import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnim;
  late AnimationController _fadeController;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;

  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // Logo pulse: scale 0.85 -> 1.15 -> 0.85 loop
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _logoAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Staggered fade-up for title + subtitle
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );

    // Trigger fade after logo starts pulsing
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });

    _navigateWhenReady();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateWhenReady() async {
    // Wait for minimum splash time so animations are appreciated
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    // Light haptic on transition
    HapticFeedback.lightImpact();

    final auth = AuthService();
    // authStateChanges is reactive — wait for it to emit at least once
    final user = await auth.authStateChanges().first;

    if (!mounted) return;

    if (user != null) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with pulse
            ScaleTransition(
              scale: _logoAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.tertiaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Title — fades in
            FadeTransition(
              opacity: _titleFade,
              child: const Text(
                'Lumina Emerald',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle — fades in slightly later
            FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                'تواصل بوضوح وأناقة',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
