import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/glowing_button.dart';

class GroupInviteScreen extends StatelessWidget {
  final String groupId;

  const GroupInviteScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final inviteLink = 'https://lumina.page.link/join?groupId=$groupId';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('رابط الدعوة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 30),
                  // QR placeholder
                  GlassContainer(
                    width: 200,
                    height: 200,
                    borderRadius: BorderRadius.circular(24),
                    opacity: 0.05,
                    blur: 20,
                    child: Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        color: Colors.white.withValues(alpha: 0.08),
                        child: const Icon(Icons.qr_code_2, size: 120, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'رابط الانضمام للمجموعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'يمكن لأي شخص لديه هذا الرابط الانضمام إلى هذه المجموعة مباشرة.',
                    style: TextStyle(color: AppColors.outline.withValues(alpha: 0.8), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Link display
                  GlassContainer(
                    opacity: 0.03,
                    blur: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            inviteLink,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlowingButton(
                    text: 'نسخ الرابط',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: inviteLink));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رابط الدعوة إلى الحافظة ✅')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Share option
                  GlowingButton(
                    text: 'مشاركة الرابط',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: inviteLink));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الرابط — يمكنك مشاركته الآن')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
