import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الإعلان عن ميزة المجتمعات
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GlassContainer(
                opacity: 0.04,
                blur: 15,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.groups_outlined, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'تقديم ميزة المجتمعات',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اجمع بين المجموعات ذات الاهتمام المشترك وأرسل إعلانات لجميع الأعضاء بسهولة تامة.',
                        style: TextStyle(fontSize: 13, color: AppColors.outline.withValues(alpha: 0.8), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Text(
              'مجتمعاتك',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // مجتمع افتراضي للمثال
            GlassContainer(
              opacity: 0.03,
              blur: 10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBright,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apartment_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'فريق تطوير Lumina',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'مجتمع يجمع كل مطوري مشروع لوكس',
                                style: TextStyle(fontSize: 12, color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.campaign_outlined, color: AppColors.primary),
                      ),
                      title: const Text('مجموعة الإعلانات العامة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('أدمن: تم إصدار التحديث الجديد Lumina v1.0', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
