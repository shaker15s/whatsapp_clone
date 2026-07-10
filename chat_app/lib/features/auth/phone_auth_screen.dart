import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/glowing_button.dart';
import '../../shared/widgets/glass_container.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submitPhoneNumber() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رقم الهاتف');
      return;
    }

    // إضافة كود الدولة الافتراضي (+20) لو مش مكتوب
    String formattedPhone = rawPhone;
    if (!rawPhone.startsWith('+')) {
      if (rawPhone.startsWith('0')) {
        formattedPhone = '+20${rawPhone.substring(1)}';
      } else {
        formattedPhone = '+20$rawPhone';
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) {
          setState(() => _loading = false);
          context.push(
            '/auth/otp',
            extra: {
              'verificationId': verificationId,
              'phoneNumber': formattedPhone,
            },
          );
        },
        onVerificationFailed: (e) {
          setState(() {
            _loading = false;
            _errorMessage = e.message ?? 'فشلت عملية التحقق، حاول مجددًا';
          });
        },
        onVerificationCompleted: (credential) async {
          // في حال التحقق التلقائي السريع
          final cred = await _authService.signInWithCredential(credential);
          setState(() => _loading = false);
          if (cred.user != null) {
            final profileExists = await _authService.checkUserProfileExists(cred.user!.uid);
            if (profileExists) {
              context.go('/home');
            } else {
              context.go('/auth/profile-setup');
            }
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          // عند انتهاء مهلة جلب الكود تلقائيًا
        },
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'حدث خطأ غير متوقع';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'أدخل رقم هاتفك',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'سنرسل لك رمز تحقق OTP لتأكيد حسابك المكتوب بالأسفل.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        opacity: 0.04,
                        blur: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رقم الهاتف (مع كود الدولة)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '+20 123 456 7890',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                fillColor: Colors.black.withOpacity(0.2),
                                filled: true,
                                prefixIcon: const Icon(Icons.phone_iphone_outlined, color: AppColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Spacer(),
                      GlowingButton(
                        text: 'إرسال الرمز',
                        loading: _loading,
                        onPressed: _submitPhoneNumber,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
