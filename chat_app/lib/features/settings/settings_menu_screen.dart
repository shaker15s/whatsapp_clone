import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

/// Simple mock user profile data holder
class _MockUserProfile {
  final String id;
  final Map<String, dynamic> dataMap;

  _MockUserProfile(this.id, this.dataMap);

  Map<String, dynamic>? data() => dataMap;
  bool get exists => true;
}

/// Mock DocumentSnapshot for offline mode
class _MockDocumentSnapshot {
  final _MockUserProfile _profile;

  _MockDocumentSnapshot(this._profile);

  Map<String, dynamic>? data() => _profile.data();
  bool get exists => _profile.exists;
  String get id => _profile.id;
}

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    Stream<dynamic> getProfileStream() {
      try {
        return FirebaseFirestore.instance.collection('users').doc(myUid).snapshots();
      } catch (_) {
        // Return a mock user profile document
        return Stream.value(_MockDocumentSnapshot(_MockUserProfile(myUid, {
          'name': 'Julian Vance',
          'about': 'Lumina Emerald - تواصل بوضوح وأناقة (وضع محلي)',
        })));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder(
        stream: getProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'مستخدم Lumina';
          final about = data['about'] ?? 'تواصل بوضوح وأناقة';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            children: [
              // كارت البروفايل الخاص بي
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: GlassContainer(
                  opacity: 0.05,
                  blur: 15,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.surfaceBright,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                about,
                                style: const TextStyle(fontSize: 13, color: AppColors.outline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // قائمة الإعدادات البلورية
              GlassContainer(
                opacity: 0.03,
                blur: 10,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.chat_outlined,
                      title: 'إعدادات الدردشة',
                      subtitle: 'تخصيص خلفيات المحادثة ونمط الخط',
                      path: '/settings/chats',
                    ),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    _buildSettingsTile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'الخصوصية',
                      subtitle: 'آخر ظهور، جهات الاتصال المحظورة',
                      path: '/settings/privacy',
                    ),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    _buildSettingsTile(
                      context,
                      icon: Icons.pie_chart_outline,
                      title: 'التخزين والبيانات',
                      subtitle: 'إدارة الذاكرة المؤقتة للوسائط والمستندات',
                      path: '/settings/storage',
                    ),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    _buildSettingsTile(
                      context,
                      icon: Icons.security,
                      title: 'الأمان',
                      subtitle: 'التحقق بخطوتين وحذف الحساب',
                      path: '/settings/security',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String path,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.outline, fontSize: 11)),
      trailing: const Icon(Icons.chevron_left, color: AppColors.outline),
      onTap: () => context.push(path),
    );
  }
}
