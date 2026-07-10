// ⚠️ ملف مؤقت - لازم تستبدله بالملف الحقيقي.
//
// الملف ده لازم يتولّد تلقائيًا عندك على جهازك بالأمر ده (مش هنا):
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// الأمر ده هيسألك تختار مشروع Firebase بتاعك (اللي عملته)، وهيولّدلك
// الملف ده تلقائيًا بكل الـ API keys الصحيحة لكل منصة (Android/iOS/Web).
// من غيره التطبيق مش هيقدر يتصل بـ Firebase خالص.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'لسه محتاج تشغل: flutterfire configure\n'
      'عشان يتولد الملف الحقيقي بدل الملف ده',
    );
  }
}
