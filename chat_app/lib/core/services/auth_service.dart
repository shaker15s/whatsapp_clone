import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock implementations of Firebase Auth objects to prevent compiler and runtime errors
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;
  @override
  final String? displayName;

  MockUser({required this.uid, this.phoneNumber, this.displayName});

  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  @override
  final User? user;

  MockUserCredential(this.user);

  @override
  AuthCredential? get credential => null;
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Local static state to retain login session during execution
  static User? _mockUser;
  static bool _isMockLoggedIn = false;
  static final Map<String, Map<String, dynamic>> _mockProfiles = {};

  User? get currentUser {
    if (_auth == null) {
      return _isMockLoggedIn ? (_mockUser ?? _createMockUser()) : null;
    }
    return _auth!.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (_auth == null) {
      // Periodic check or event-based streaming of login state
      return Stream.value(_isMockLoggedIn ? (_mockUser ?? _createMockUser()) : null);
    }
    return _auth!.authStateChanges();
  }

  User _createMockUser() {
    return _mockUser ??= MockUser(
      uid: 'mock_uid_123',
      phoneNumber: '+201000000000',
      displayName: 'مستخدم Lumina التجريبي',
    );
  }

  /// التحقق من رقم الهاتف وإرسال الـ OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (_auth == null) {
      // Simulate network latency then trigger codeSent
      await Future.delayed(const Duration(milliseconds: 800));
      onCodeSent('mock_verification_id_12345', null);
      return;
    }

    await _auth!.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// تسجيل الدخول بالرمز والكود المدخل
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    if (_auth == null) {
      _isMockLoggedIn = true;
      _mockUser = _createMockUser();
      return MockUserCredential(_mockUser);
    }
    return await _auth!.signInWithCredential(credential);
  }

  /// فحص وجود الملف الشخصي للمستخدم في قاعدة البيانات
  Future<bool> checkUserProfileExists(String uid) async {
    if (_db == null) {
      return _mockProfiles.containsKey(uid);
    }
    final doc = await _db!.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// إنشاء البروفايل للمستخدم الجديد لأول مرة
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String phoneNumber,
    String? profilePicUrl,
  }) async {
    if (_db == null) {
      _mockProfiles[uid] = {
        'uid': uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'profilePicUrl': profilePicUrl,
        'about': 'Lumina Emerald - تواصل بوضوح وأناقة (تجريبي)',
        'createdAt': DateTime.now(),
      };
      return;
    }

    await _db!.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl,
      'about': 'Lumina Emerald - تواصل بوضوح وأناقة',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    if (_auth == null) {
      _isMockLoggedIn = false;
      _mockUser = null;
      return;
    }
    await _auth!.signOut();
  }
}
