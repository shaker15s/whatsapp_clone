import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/glowing_button.dart';

import '../../core/services/auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoStepEnabled = false;

  Future<void> _deleteAccount() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب نهائيًا'),
        content: const Text('هل أنت متأكد من رغبتك في حذف حسابك وكل بياناتك نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final uid = user.uid;
        // مسح مستند المستخدم في Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        // مسح الحساب من Auth
        await user.delete();
        
        if (mounted) {
          context.go('/welcome');
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء حذف الحساب، حاول إعادة تسجيل الدخول مجددًا')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الأمان والحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        children: [
          const Text(
            'حماية إضافية لحسابك',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: SwitchListTile(
              title: const Text('التحقق بخطوتين (2-Step Verification)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('طلب رمز PIN إضافي عند تسجيل الدخول مجددًا', style: TextStyle(color: AppColors.outline, fontSize: 11)),
              activeColor: AppColors.primary,
              value: _twoStepEnabled,
              onChanged: (val) => setState(() => _twoStepEnabled = val),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'منطقة الخطر',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.04,
            blur: 15,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سيؤدي حذف الحساب إلى مسح كافة سجلات المحادثات ورسائل الميديا نهائيًا من خوادمنا ولا يمكن استرجاعها.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: AppColors.onErrorContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _deleteAccount,
                  child: const Text('حذف حسابي نهائيًا', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
