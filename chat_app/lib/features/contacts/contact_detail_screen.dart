import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(contactId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المستخدم غير موجود'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'مستخدم Lumina';
          final about = data['about'] ?? 'تواصل بوضوح وأناقة';
          final phone = data['phoneNumber'] ?? 'غير معروف';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 53,
                          backgroundColor: AppColors.surfaceBright,
                          child: Icon(Icons.person, size: 55, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(color: AppColors.outline, fontSize: 13),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // نبذة عن جهة الاتصال
                const Text(
                  'الأخبار والمعلومات',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  opacity: 0.03,
                  blur: 10,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    about,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // خيارات الحظر والكتم
                GlassContainer(
                  opacity: 0.03,
                  blur: 10,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.block, color: AppColors.error),
                        title: const Text('حظر المستخدم', style: TextStyle(color: AppColors.error)),
                        onTap: () {
                          // تفعيل الحظر
                        },
                      ),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      ListTile(
                        leading: const Icon(Icons.notifications_off_outlined, color: Colors.white),
                        title: const Text('كتم الإشعارات', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          // كتم المستخدم
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
