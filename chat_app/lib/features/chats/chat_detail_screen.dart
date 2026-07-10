import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/call_service.dart';
import '../../core/config/app_config.dart';
import '../../models/message_model.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../shared/widgets/chat_input_bar.dart';
import '../../core/theme/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String myUid;
  final String otherUid;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.myUid,
    required this.otherUid,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final CallService _callService = CallService();

  Map<String, dynamic>? _replyingMessage;

  @override
  void initState() {
    super.initState();
    _chatService.markChatAsRead(widget.chatId, widget.myUid);
  }

  Future<void> _editMessage(MessageModel msg) async {
    final controller = TextEditingController(text: msg.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _chatService.editMessage(widget.chatId, msg.id, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل الرسالة')),
        );
      }
    }
  }

  Future<void> _deleteMessage(MessageModel msg) async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل تريد حذف هذه الرسالة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف للكل'),
          ),
        ],
      ),
    );
    if (choice == true) {
      await _chatService.deleteMessage(widget.chatId, msg.id, widget.myUid, unsendForAll: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الرسالة للكل')),
        );
      }
    }
  }

  Future<void> _forwardMessage(MessageModel msg) async {
    await context.push('/contacts', extra: {'forwardMessageId': msg.id, 'forwardFromChatId': widget.chatId});
  }

Future<void> _startCall(bool isVideo) async {
  final token = '';
  final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}_${widget.myUid.hashCode.abs()}';
  // استخدام Cloud Function لجلب توكن Agora حقيقي
  String agoraToken = token;
  try {
    final functions = FirebaseFunctions.instance;
    final result = await functions
        .httpsCallable('getAgoraToken')
        .call({'channel': channelName, 'uid': widget.myUid});
    agoraToken = result.data['token'] ?? token;
  } catch (e) {
    // لو فشل نكمل بالتوكن الفارغ (Agora يعمل بدون توكن) بس
    debugPrint('Failed to get Agora token: $e');
  }
    
  final callId = await _callService.startCall(
    callerId: widget.myUid,
    calleeId: widget.otherUid,
    isVideo: isVideo,
    appId: AppConfig.agoraAppId,
    token: agoraToken,
    channelName: channelName,
  );

    if (mounted) {
      context.push(
        '/call/active',
        extra: {
          'callId': callId,
          'isVideo': isVideo,
          'otherUid': widget.otherUid,
          'channelName': channelName,
          'token': token,
          'myUid': widget.myUid,
        },
      );
    }
  }

  void _clearReply() {
    setState(() => _replyingMessage = null);
  }

  Future<void> _onReplyTo(MessageModel msg) async {
    String senderName;
    if (msg.senderId == widget.myUid) {
      senderName = 'أنا';
    } else {
      try {
        final db = FirebaseFirestore.instance;
        final doc = await db.collection('users').doc(msg.senderId).get();
        if (doc.exists) {
          senderName = (doc.data()?['name'] ?? msg.senderId) as String;
        } else {
          senderName = msg.senderId.length > 10 ? 'مستخدم Lumina' : msg.senderId;
        }
      } catch (_) {
        senderName = msg.senderId.length > 10 ? 'مستخدم Lumina' : msg.senderId;
      }
    }

    String textSnippet;
    if (msg.type == MessageType.text) {
      textSnippet = msg.content;
    } else {
      textSnippet = _typeLabel(msg.type);
    }

    setState(() {
      _replyingMessage = {
        'messageId': msg.id,
        'textSnippet': textSnippet,
        'senderName': senderName,
      };
    });
  }

  String _typeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 صورة';
      case MessageType.audio:
        return '🎤 رسالة صوتية';
      case MessageType.location:
        return '📍 موقع';
      default:
        return 'وسائط';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ],
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceBright,
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUid.length > 10 ? 'مستخدم Lumina' : widget.otherUid,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  StreamBuilder(
                    stream: _chatService.watchTyping(widget.chatId, widget.otherUid),
                    builder: (context, AsyncSnapshot<dynamic> typingSnap) {
                      bool isTyping = false;
                      if (typingSnap.hasData && typingSnap.data != null) {
                        try {
                          final val = typingSnap.data;
                          if (val is DatabaseEvent) {
                            isTyping = (val.snapshot.value as bool?) ?? false;
                          } else if (val is Map) {
                            isTyping = (val['snapshot']?['value'] as bool?) ?? false;
                          }
                        } catch (_) {}
                      }

                      if (isTyping) {
                        return const Text(
                          'يكتب الآن...',
                          style: TextStyle(fontSize: 12, color: AppColors.tertiary),
                        );
                      }
                      return const Text(
                        'متصل',
                        style: TextStyle(fontSize: 12, color: AppColors.outline),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            onPressed: () => _startCall(true),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0C1930),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _chatService.watchMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.outline.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'أرسل رسالة لبدء التحدث',
                              style: TextStyle(color: AppColors.outline.withValues(alpha: 0.7), fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final message = MessageModel.fromDoc(docs[index]);
                        final isMe = message.senderId == widget.myUid;
                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          onReact: (emoji) {
                            _chatService.toggleReaction(
                              widget.chatId,
                              message.id,
                              widget.myUid,
                              emoji,
                            );
                          },
                          onReply: () => _onReplyTo(message),
                          onStar: () {
                            final isStarred = message.isStarredBy.contains(widget.myUid);
                            _chatService.toggleStarMessage(
                              widget.chatId,
                              message.id,
                              widget.myUid,
                              !isStarred,
                            );
                          },
                          onEdit: isMe ? () => _editMessage(message) : null,
                          onDelete: isMe ? () => _deleteMessage(message) : null,
                          onForward: isMe ? () => _forwardMessage(message) : null,
                        );
                      },
                    );
                  },
                ),
              ),
              ChatInputBar(
                onSendText: (text) {
                  _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.myUid,
                    type: 'text',
                    content: text,
                    replyTo: _replyingMessage,
                  );
                  _clearReply();
                },
                onSendImage: (file) async {
                  try {
                    String url;
      final bytes = await file.readAsBytes();
      url = await _storageService.uploadImageBytes(bytes, widget.chatId, fileName: file.name);
                    _chatService.sendMessage(
                      chatId: widget.chatId,
                      senderId: widget.myUid,
                      type: 'image',
                      content: url,
                      replyTo: _replyingMessage,
                    );
                    _clearReply();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل رفع الصورة: $e')),
                      );
                    }
                  }
                },
                onSendAudio: (file, duration) async {
                  try {
                    String url;
      final bytes = await file.readAsBytes();
      url = await _storageService.uploadAudioBytes(bytes, widget.chatId, fileName: file.name);
                    _chatService.sendMessage(
                      chatId: widget.chatId,
                      senderId: widget.myUid,
                      type: 'audio',
                      content: url,
                      durationSeconds: duration,
                      replyTo: _replyingMessage,
                    );
                    _clearReply();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل رفع الصوت: $e')),
                      );
                    }
                  }
                },
                onSendLocation: (lat, lng) {
                  _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.myUid,
                    type: 'location',
                    content: '$lat,$lng',
                    replyTo: _replyingMessage,
                  );
                  _clearReply();
                },
                replyTo: _replyingMessage,
                onClearReply: _clearReply,
              ),
            ],
          ),
        ],
      ),
    );
  }
}