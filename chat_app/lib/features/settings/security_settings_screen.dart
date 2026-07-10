import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoStepEnabled = false;
  String? _twoStepPin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _twoStepEnabled = (data['twoStepEnabled'] ?? false) as bool;
          _twoStepPin = data['twoStepPin'] as String?;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleTwoStep(bool val) async {
    if (val && _twoStepPin == null) {
      // First time enabling — ask user to set a PIN
      final pin = await _showPinSetupDialog();
      if (pin == null) return; // user cancelled
      await _saveTwoStepSettings(enabled: true, pin: pin);
    } else if (!val) {
      // Disable 2FA
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text('تعطيل التحقق بخطوتين؟'),
          content: const Text('سيتم إيقاف الحماية الإضافية لحسابك.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تعطيل', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await _saveTwoStepSettings(enabled: false, pin: null);
      }
    } else {
      // Already enabled — just update state
      await _saveTwoStepSettings(enabled: true, pin: _twoStepPin);
    }
  }

  Future<void> _saveTwoStepSettings({required bool enabled, String? pin}) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    try {
      final updates = <String, dynamic>{'twoStepEnabled': enabled};
      if (enabled && pin != null) {
        updates['twoStepPin'] = pin;
      } else if (!enabled) {
        updates['twoStepPin'] = null;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      setState(() {
        _twoStepEnabled = enabled;
        _twoStepPin = pin;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enabled ? 'تم تفعيل التحقق بخطوتين ✅' : 'تم تعطيل التحقق بخطوتين')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الإعداد: $e')),
        );
      }
    }
  }

  Future<String?> _showPinSetupDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text('تعيين رمز PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'أدخل رمز PIN (4-6 أرقام)',
                  hintStyle: TextStyle(color: AppColors.outline),
                ),
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              ),
              TextField(
                controller: confirmController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'أعد إدخال الرمز',
                  hintStyle: TextStyle(color: AppColors.outline),
                ),
                style: const TextStyle(color: Colors.white),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length < 4) {
                  setModalState(() => error = 'الرمز لازم يكون 4-6 أرقام على الأقل');
                  return;
                }
                if (pin != confirm) {
                  setModalState(() => error = 'الرمز مش متطابق');
                  return;
                }
                Navigator.pop(ctx, pin);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // If 2FA is enabled, require PIN before deletion
    if (_twoStepEnabled && _twoStepPin != null) {
      final pin = await _showPinVerificationDialog();
      if (pin != _twoStepPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رمز PIN غير صحيح'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('حذف الحساب نهائيًا'),
        content: const Text('هل أنت متأكد من رغبتك في حذف حسابك وكل بياناتك نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final uid = user.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await user.delete();
        context.go('/welcome');
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حذف الحساب، حاول إعادة تسجيل الدخول مجددًا')),
        );
      }
    }
  }

  Future<String?> _showPinVerificationDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('أدخل رمز PIN'),
        content: TextField(
          controller: controller,
          maxLength: 6,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
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
                    subtitle: Text(
                      _twoStepEnabled ? 'مفعل — اضغط لتغيير الرمز أو التعطيل' : 'طلب رمز PIN عند تسجيل الدخول',
                      style: const TextStyle(color: AppColors.outline, fontSize: 11),
                    ),
                    activeColor: AppColors.primary,
                    value: _twoStepEnabled,
                    onChanged: _toggleTwoStep,
                  ),
                ),
                if (_twoStepEnabled && _twoStepPin != null) ...[
                  const SizedBox(height: 8),
                  GlassContainer(
                    opacity: 0.03,
                    blur: 10,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.tertiary, size: 18),
                        const SizedBox(width: 8),
                        const Text('رمز PIN محفوظ محلياً', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final newPin = await _showPinSetupDialog();
                            if (newPin != null && mounted) {
                              await _saveTwoStepSettings(enabled: true, pin: newPin);
                            }
                          },
                          child: const Text('تغيير', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],
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
