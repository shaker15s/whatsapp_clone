import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/message_model.dart';
import '../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onStar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReact,
    this.onReply,
    this.onStar,
    this.onEdit,
    this.onDelete,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    // Asymmetric rounding like WhatsApp
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

    return AnimatedSlide(
      offset: const Offset(0, 0.3),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: Align(
        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.lightImpact();
            _showOptionsSheet(context);
          },
          onTap: () {
            // Optional: tap to open image in full screen
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: bubbleRadius,
              color: isMe
                  ? null // Gradient handled below
                  : AppColors.surfaceContainerHigh,
              gradient: isMe
                  ? const LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.tertiaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: bubbleRadius,
                border: Border.all(
                  color: isMe
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: bubbleRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply quote
                      if (message.replyTo != null) ...[
                        _buildReplyQuote(),
                        const SizedBox(height: 6),
                      ],
                      // Message content
                      _buildMessageContent(),
                      const SizedBox(height: 6),
// Meta row: forward/edit star
if (message.isForwarded) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forward_outlined, size: 11, color: AppColors.outline),
        const SizedBox(width: 3),
        Text(
          'تم التوجيه',
          style: TextStyle(fontSize: 10, color: AppColors.outline),
        ),
      ],
    ),
  ),
] else if (message.isEdited) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
    child: Text(
      'تم تعديلها',
      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.outline),
    ),
  ),
],
// Time + checkmarks
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
         color: isMe
             ? AppColors.onPrimary.withValues(alpha: 0.7)
             : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
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
        ),
      ),
    );
  }

  Widget _buildReplyQuote() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface.withValues(alpha: 0.4),
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
              fontWeight: FontWeight.w600,
              color: isMe ? AppColors.primary : AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!['textSnippet'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: isMe
                  ? AppColors.onPrimary.withValues(alpha: 0.7)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.content,
            fit: BoxFit.cover,
            width: 220,
            height: 180,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 220,
                height: 180,
                color: AppColors.surfaceContainer,
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      color: isMe ? AppColors.onPrimary : AppColors.primary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 220,
              height: 180,
              color: AppColors.surfaceContainer,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: AppColors.outlineVariant),
                  SizedBox(height: 8),
                  Text('فشل تحميل الصورة', style: TextStyle(fontSize: 12, color: AppColors.outlineVariant)),
                ],
              ),
            ),
          ),
        );

      case MessageType.audio:
        return _buildAudioPlayer();

      case MessageType.location:
        return _buildLocationPreview();

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? AppColors.onPrimary : AppColors.onSurface,
            fontSize: 15,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildAudioPlayer() {
    final duration = message.durationSeconds ?? 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AudioPlayButton(isMe: isMe),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, "0")}',
              style: TextStyle(
                fontSize: 12,
                color: isMe
                    ? AppColors.onPrimary.withValues(alpha: 0.8)
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AudioWaveform(isMe: isMe),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map placeholder (inline map would require flutter_map package)
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.3),
                  AppColors.tertiaryContainer.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'موقع مشترك',
                  style: TextStyle(
                    fontSize: 13,
                    color: isMe ? AppColors.onPrimary : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    if (message.status == MessageStatus.read) {
      icon = Icons.done_all;
      color = AppColors.tertiary; // Mint checkmarks
    } else if (message.status == MessageStatus.delivered) {
      icon = Icons.done_all;
      color = isMe ? AppColors.onPrimary.withValues(alpha: 0.6) : AppColors.onSurfaceVariant;
    } else {
      icon = Icons.done;
      color = isMe ? AppColors.onPrimary.withValues(alpha: 0.6) : AppColors.onSurfaceVariant;
    }
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildReactionsBadge() {
    final list = message.reactions.values.toList();
    final unique = list.toSet().toList();
    if (unique.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4, right: 12, left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unique.join(' '),
            style: const TextStyle(fontSize: 13),
          ),
          if (list.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              list.length.toString(),
              style: const TextStyle(fontSize: 10, color: AppColors.outlineVariant),
            ),
          ],
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            // Quick reactions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
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
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
  ListTile(
    leading: const Icon(Icons.star_border),
    title: const Text('تمييز بنجمة'),
    onTap: () {
      Navigator.pop(ctx);
      onStar?.call();
    },
  ),
  if (isMe && !message.isDeleted) ...[
    if (message.type == MessageType.text) ...[
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text('تعديل'),
        onTap: () {
          Navigator.pop(ctx);
          onEdit?.call();
        },
      ),
    ],
    ListTile(
      leading: const Icon(Icons.forward),
      title: const Text('إعادة توجيه'),
      onTap: () {
        Navigator.pop(ctx);
        onForward?.call();
      },
    ),
    ListTile(
      leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
      title: Text('حذف', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
      onTap: () {
        Navigator.pop(ctx);
        onDelete?.call();
      },
    ),
  ],
          ],
        ),
      ),
    );
  }
}

// ─── Audio Play Button (Inline Widget) ───────────────────────────────────────
class _AudioPlayButton extends StatefulWidget {
  final bool isMe;
  const _AudioPlayButton({required this.isMe});

  @override
  State<_AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<_AudioPlayButton> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _playing = !_playing);
        // TODO: Wire to real audio player service
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isMe ? AppColors.primary : AppColors.primaryContainer,
        ),
        child: Icon(
          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 20,
          color: widget.isMe ? AppColors.onPrimary : AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ─── Audio Waveform (Decorative) ────────────────────────────────────────────
class _AudioWaveform extends StatelessWidget {
  final bool isMe;
  const _AudioWaveform({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final barCount = 8;
    final baseColor = isMe ? AppColors.onPrimary : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(barCount, (i) {
        final height = 6.0 + (i % 3) * 5.0 + (i % 2) * 3.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.5 + (i / barCount) * 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
