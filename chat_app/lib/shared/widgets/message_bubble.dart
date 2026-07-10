import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/message_model.dart';
import '../../core/theme/app_colors.dart';
import 'glass_container.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onStar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReact,
    this.onReply,
    this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    // الزوايا غير المتماثلة (Asymmetric Rounding)
    final bubbleRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () => _showOptionsSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // فقاعة الرسالة الرئيسية
              Container(
                decoration: BoxDecoration(
                  borderRadius: bubbleRadius,
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [AppColors.primaryContainer, AppColors.tertiaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: GlassContainer(
                  borderRadius: bubbleRadius,
                  opacity: isMe ? 0.05 : 0.03,
                  blur: 15,
                  color: isMe ? AppColors.tertiary : Colors.white,
                  border: Border.all(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    width: 1.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // الاقتباس / الرد (Reply quote)
                          if (message.replyTo != null) ...[
                            _buildReplyQuote(context),
                            const SizedBox(height: 6),
                          ],
                          // محتوى الرسالة
                          _buildMessageContent(context),
                          const SizedBox(height: 6),
                          // الوقت وعلامات الصح
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.isStarredBy.isNotEmpty) ...[
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                intl.DateFormat.Hm().format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                _buildStatusIcon(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // التفاعلات (Reactions)
              if (message.reactions.isNotEmpty) _buildReactionsBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyQuote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: BorderSide(
            color: isMe ? AppColors.primary : AppColors.onSurfaceVariant,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.replyTo!['senderName'] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMe ? AppColors.primary : AppColors.tertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!['textSnippet'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.content,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
          ),
        );
      case MessageType.audio:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 8),
            Text('رسالة صوتية', style: TextStyle(color: Colors.white)),
          ],
        );
      case MessageType.location:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text('موقع مشترك', style: TextStyle(color: Colors.white)),
          ],
        );
      default:
        return Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        );
    }
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = Colors.white.withOpacity(0.5);
    if (message.status == MessageStatus.read) {
      icon = Icons.done_all;
      color = AppColors.tertiary; // صحين زرقاء (mint)
    } else if (message.status == MessageStatus.delivered) {
      icon = Icons.done_all;
    } else {
      icon = Icons.done;
    }
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildReactionsBadge() {
    final list = message.reactions.values.toList();
    // تجميع الإيموجيز الفريدة
    final unique = list.toSet().toList();

    return Container(
      margin: const EdgeInsets.only(top: 2, right: 8, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unique.join(' ')),
          if (list.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              list.length.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            // شريط التفاعلات السريعة
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.outlineVariant),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('تمييز بنجمة'),
              onTap: () {
                Navigator.pop(context);
                onStar?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
