import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glowing_button.dart';
import '../../shared/widgets/glass_container.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              // الجزء الأوسط: الرسم التوضيحي وعنوان الترحيب
              Column(
                children: [
                  // رسمة بلورية محاكية للتصميم
                  GlassContainer(
                    width: 180,
                    height: 180,
                    borderRadius: BorderRadius.circular(90),
                    opacity: 0.08,
                    blur: 25,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryContainer, AppColors.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tertiary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'أهلاً بك في Lumina',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'تواصل مع أصدقائك وعائلتك بمحادثات آمنة، مشفرة، ومبنية بجماليات بلورية فريدة.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // الجزء السفلي: الموافقة والمتابعة
              Column(
                children: [
                  const Text(
                    'بالضغط على "الموافقة والمتابعة"، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.outline,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GlowingButton(
                      text: 'الموافقة والمتابعة',
                      onPressed: () => context.push('/auth/phone'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
