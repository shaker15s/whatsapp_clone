import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:firebase_database/firebase_database.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/presence_service.dart';
import '../../models/chat_model.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/theme/app_colors.dart';

import '../../core/services/auth_service.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final String _myUid = AuthService().currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    if (_myUid.isNotEmpty) {
      _presenceService.setOnline(_myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid.isEmpty) {
      return const Center(child: Text('غير مسجل دخول'));
    }

    return StreamBuilder(
      stream: _chatService.watchMyChats(_myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 64, color: AppColors.outline.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد محادثات نشطة بعد',
                  style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على زر الإضافة لبدء شات جديد',
                  style: TextStyle(fontSize: 13, color: AppColors.outline.withValues(alpha: 0.8)),
                ),
              ],
            ),
          );
        }

        final chatDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chat = ChatModel.fromDoc(chatDocs[index]);
            final otherUid = chat.participants.firstWhere((id) => id != _myUid, orElse: () => '');
            
            // فلترة الشات المؤرشف افتراضيا
            if (chat.archivedBy.contains(_myUid)) {
              return const SizedBox.shrink();
            }

            final unreadCount = chat.unreadCount[_myUid] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                opacity: 0.03,
                blur: 10,
                child: InkWell(
                  onTap: () {
                    context.push(
                      '/chat/${chat.id}',
                      extra: {
                        'myUid': _myUid,
                        'otherUid': otherUid,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        // البروفايل مع مؤشر التواجد
                        StreamBuilder(
                          stream: _presenceService.watchUserPresence(otherUid),
                          builder: (context, AsyncSnapshot<dynamic> presenceSnap) {
                            bool isOnline = false;
                            if (presenceSnap.hasData && presenceSnap.data != null) {
                              final val = presenceSnap.data;
                              try {
                                if (val is Map) {
                                  isOnline = val['state'] == 'online';
                                } else {
                                  final presenceData = Map<dynamic, dynamic>.from(val.snapshot.value as Map);
                                  isOnline = presenceData['state'] == 'online';
                                }
                              } catch (_) {}
                            }

                            return Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isOnline
                                        ? Border.all(color: AppColors.primary, width: 2)
                                        : null,
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: AppColors.surfaceBright,
                                    child: Icon(Icons.person, color: Colors.white, size: 28),
                                  ),
                                ),
                                if (isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: AppColors.tertiary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.surface, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // تفاصيل المحادثة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUid.length > 10 ? 'مستخدم Lumina' : otherUid, // اسم العرض المؤقت
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // يكتب الآن أو آخر رسالة
                              StreamBuilder(
                                stream: _chatService.watchTyping(chat.id, otherUid),
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.tertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }

                                  return Text(
                                    chat.lastMessage.isEmpty ? 'ابدأ المحادثة الآن' : chat.lastMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: unreadCount > 0 ? Colors.white : AppColors.onSurfaceVariant,
                                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // التوقيت وعدد غير المقروء
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chat.lastMessageTime != null)
                              Text(
                                intl.DateFormat.Hm().format(chat.lastMessageTime!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: unreadCount > 0 ? AppColors.primary : AppColors.outline,
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
