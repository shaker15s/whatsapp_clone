import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase مع معالجة خطأ واضحة
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } on FirebaseException catch (e) {
    debugPrint('❌ Firebase initialization failed: ${e.code} - ${e.message}');
    // عرض خطأ للمستخدم بدلاً من التشغيل في وضع تجريبي صامت
    runApp(_FirebaseErrorApp(error: e.message ?? e.code));
    return;
  } catch (e) {
    debugPrint('❌ Unexpected error during Firebase initialization: $e');
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  runApp(const ChatApp());
}

/// تطبيق يعرض خطأ تهيئة Firebase للمستخدم
class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina Emerald - Setup Required',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'يتطلب إعداد Firebase',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'فشل تهيئة Firebase. يرجى تشغيل:\n\nflutterfire configure\n\nفي مجلد المشروع، ثم أعد تشغيل التطبيق.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  error,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => debugPrint('Restart app after running flutterfire configure'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('أعد المحاولة بعد الإعداد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumina Emerald',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}