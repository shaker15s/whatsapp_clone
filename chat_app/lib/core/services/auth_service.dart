import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// خدمة المصادقة - تدعم Firebase Auth الحقيقي مع معالجة خطأ سليمة
class AuthService {
  /// حالة ما إذا كان Firebase مهيأ وجاهزاً للاستخدام
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// إرجاع مثيل FirebaseAuth مع التحقق من جاهزية Firebase
  FirebaseAuth get _auth {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. تأكد من تشغيل flutterfire configure وإضافة google-services.json');
    }
    return FirebaseAuth.instance;
  }

  /// إرجاع مثيل Firestore مع التحقق من جاهزية Firebase
  FirebaseFirestore get _db {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. تأكد من تشغيل flutterfire configure');
    }
    return FirebaseFirestore.instance;
  }

  // ─── Current User ────────────────────────────────────────────────────────
  /// المستخدم الحالي (null إذا لم يكن هناك تسجيل دخول)
  User? get currentUser {
    if (!_isFirebaseReady) return null;
    return _auth.currentUser;
  }

  // ─── Auth State Stream ───────────────────────────────────────────────────
  /// Stream يتفاعل مع تغييرات حالة المصادقة (تسجيل دخول/خروج)
  Stream<User?> authStateChanges() {
    if (!_isFirebaseReady) {
      // إرجاع stream فارغ إذا لم يكن Firebase جاهزاً
      return Stream<User?>.value(null);
    }
    return _auth.authStateChanges();
  }

  // ─── Phone Auth ──────────────────────────────────────────────────────────
  /// التحقق من رقم الهاتف وإرسال رمز OTP
  /// 
  /// المعاملات:
  /// - [phoneNumber]: رقم الهاتف بصيغة دولية (مثال: +201000000000)
  /// - [onCodeSent]: استدعاء عند إرسال الكود بنجاح مع [verificationId] و [resendToken]
  /// - [onVerificationFailed]: استدعاء عند فشل التحقق مع [FirebaseAuthException]
  /// - [onVerificationCompleted]: استدعاء عند التحقق التلقائي (Android فقط)
  /// - [onCodeAutoRetrievalTimeout]: استدعاء عند انتهاء مهلة الاسترجاع التلقائي
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. لا يمكن إرسال رمز التحقق.');
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      // إعادة رمي الاستثناء مع رسالة عربية واضحة
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء إرسال رمز التحقق: $e');
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────
  /// تسجيل الدخول باستخدام بيانات اعتماد الهاتف (OTP)
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. لا يمكن تسجيل الدخول.');
    }

    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────
  /// التحقق مما إذا كان ملف المستخدم الشخصي موجوداً
  Future<bool> checkUserProfileExists(String uid) async {
    if (!_isFirebaseReady) return false;
    
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('فشل التحقق من وجود الملف الشخصي: $e');
    }
  }

  /// إنشاء ملف مستخدم شخصي جديد
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String phoneNumber,
    String? profilePicUrl,
  }) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. لا يمكن إنشاء الملف الشخصي.');
    }

    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'profilePicUrl': profilePicUrl,
        'about': 'Lumina Emerald - تواصل بوضوح وأناقة',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل إنشاء الملف الشخصي: $e');
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  /// تسجيل الخروج
  Future<void> logout() async {
    if (!_isFirebaseReady) return;
    
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: $e');
    }
  }

  // ─── Error Mapping ───────────────────────────────────────────────────────
  /// تحويل استثناءات Firebase Auth إلى رسائل عربية واضحة
  Exception _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return Exception('رمز التحقق غير صحيح. يرجى المحاولة مرة أخرى.');
      case 'invalid-verification-id':
        return Exception('معرف التحقق غير صالح. يرجى طلب رمز جديد.');
      case 'session-expired':
        return Exception('انتهت صلاحية الجلسة. يرجى طلب رمز جديد.');
      case 'quota-exceeded':
        return Exception('تم تجاوز الحد الأقصى للمحاولات. يرجى المحاولة لاحقاً.');
      case 'too-many-requests':
        return Exception('عدد طلبات كبير جداً. يرجى الانتظار والمحاولة مرة أخرى.');
      case 'network-request-failed':
        return Exception('فشل الاتصال بالشبكة. تحقق من اتصالك بالإنترنت.');
      case 'user-disabled':
        return Exception('تم تعطيل هذا الحساب. تواصل مع الدعم.');
      case 'operation-not-allowed':
        return Exception('مصادقة الهاتف غير مفعلة في إعدادات Firebase.');
      default:
        return Exception('خطأ في المصادقة: ${e.message ?? e.code}');
    }
  }
}