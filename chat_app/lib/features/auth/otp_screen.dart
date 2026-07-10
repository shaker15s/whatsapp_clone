import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/glowing_button.dart';
import '../../shared/widgets/glass_container.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length < 6) {
      setState(() => _errorMessage = 'يرجى إدخال الرمز المكون من 6 أرقام');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _authService.signInWithCredential(credential);
      if (userCredential.user != null) {
        final profileExists = await _authService.checkUserProfileExists(userCredential.user!.uid);
        if (profileExists) {
          if (mounted) context.go('/home');
        } else {
          if (mounted) context.go('/auth/profile-setup');
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'رمز التحقق غير صحيح، يرجى المحاولة مرة أخرى.';
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                        'التحقق من رمز OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تم إرسال رمز التحقق إلى الرقم ${widget.phoneNumber}',
                        style: const TextStyle(
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
                              'أدخل الرمز المكون من 6 أرقام',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.white),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 8),
                                fillColor: Colors.black.withValues(alpha: 0.2),
                                filled: true,
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
                        text: 'تأكيد الرمز والدخول',
                        loading: _loading,
                        onPressed: _verifyOtp,
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
