import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
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
    // تصفير غير المقروء وقراءة الرسائل
    _chatService.markChatAsRead(widget.chatId, widget.myUid);
  }

  Future<void> _startCall(bool isVideo) async {
    final callId = await _callService.startCall(
      callerId: widget.myUid,
      calleeId: widget.otherUid,
      isVideo: isVideo,
      appId: AppConfig.agoraAppId,
    );

    if (mounted) {
      context.push(
        '/call/active',
        extra: {
          'callId': callId,
          'isVideo': isVideo,
          'otherUid': widget.otherUid,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
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
            const CircleAvatar(
              backgroundColor: AppColors.surfaceBright,
              child: Icon(Icons.person, color: Colors.white),
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
                  // مؤشر الكتابة لحظيًا
                  StreamBuilder(
                    stream: _chatService.watchTyping(widget.chatId, widget.otherUid),
                    builder: (context, AsyncSnapshot<dynamic> typingSnap) {
                      bool isTyping = false;
                      if (typingSnap.hasData && typingSnap.data != null) {
                        final val = typingSnap.data;
                        if (val is bool) {
                          isTyping = val;
                        } else {
                          try {
                            isTyping = val.snapshot.value as bool;
                          } catch (_) {}
                        }
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
          // الخلفية البلورية للشات
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
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'أرسل رسالة لبدء التحدث',
                          style: TextStyle(color: AppColors.outline.withOpacity(0.7)),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final message = MessageModel.fromDoc(docs[index]);
                        return MessageBubble(
                          message: message,
                          isMe: message.senderId == widget.myUid,
                          onReact: (emoji) {
                            _chatService.toggleReaction(widget.chatId, message.id, widget.myUid, emoji);
                          },
                          onReply: () {
                            setState(() {
                              _replyingMessage = {
                                'messageId': message.id,
                                'textSnippet': message.type == MessageType.text ? message.content : 'وسائط',
                                'senderName': message.senderId == widget.myUid ? 'أنا' : 'الطرف الآخر',
                              };
                            });
                          },
                          onStar: () {
                            final isStarred = message.isStarredBy.contains(widget.myUid);
                            _chatService.toggleStarMessage(widget.chatId, message.id, widget.myUid, !isStarred);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              // لو شريط الرد نشط، نعرضه هنا
              if (_replyingMessage != null) _buildReplyBar(),

              ChatInputBar(
                onSendText: (text) {
                  _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.myUid,
                    type: 'text',
                    content: text,
                    replyTo: _replyingMessage,
                  );
                  if (_replyingMessage != null) {
                    setState(() => _replyingMessage = null);
                  }
                },
                onSendImage: (file) async {
                  final url = await _storageService.uploadImage(file, widget.chatId);
                  _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.myUid,
                    type: 'image',
                    content: url,
                    replyTo: _replyingMessage,
                  );
                  if (_replyingMessage != null) {
                    setState(() => _replyingMessage = null);
                  }
                },
                onSendAudio: (file, duration) async {
                  final url = await _storageService.uploadAudio(file, widget.chatId);
                  _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.myUid,
                    type: 'audio',
                    content: url,
                    durationSeconds: duration,
                    replyTo: _replyingMessage,
                  );
                  if (_replyingMessage != null) {
                    setState(() => _replyingMessage = null);
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
                  if (_replyingMessage != null) {
                    setState(() => _replyingMessage = null);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingMessage!['senderName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingMessage!['textSnippet'],
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => setState(() => _replyingMessage = null),
          ),
        ],
      ),
    );
  }
}
