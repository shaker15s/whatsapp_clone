import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// خدمة الحضور (Presence) - Realtime Database للـ online/offline
class PresenceService {
  /// التحقق من جاهزية Firebase
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// إرجاع مثيل Realtime Database
  FirebaseDatabase get _db {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. شغل flutterfire configure أولاً.');
    }
    return FirebaseDatabase.instance;
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[PresenceService] $msg');
  }

  /// تعيين المستخدم كمتصل مع withDisconnect handler
  /// يجب استدعاؤها عند كل تشغيل للتطبيق (cold start) أو إعادة اتصال
  Future<void> setOnline(String uid) async {
    try {
      final myRef = _db.ref('presence/$uid');

      // تعيين حالة عدم الاتصال عند انقطاع الاتصال
      await myRef.onDisconnect().set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      });

      // تعيين الحالة الحالية
      await myRef.set({
        'state': 'online',
        'lastSeen': ServerValue.timestamp,
      });
      _log('setOnline($uid) — onDisconnect registered');
    } catch (e, stack) {
      _log('setOnline error: $e\n$stack');
      rethrow;
    }
  }

  /// تعيين المستخدم كغير متصل بشكل صريح (مثلاً عند تسجيل الخروج)
  Future<void> setOffline(String uid) async {
    try {
      await _db.ref('presence/$uid').set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
      _log('setOffline($uid)');
    } catch (e, stack) {
      _log('setOffline error: $e\n$stack');
      rethrow;
    }
  }

  /// مراقبة حالة مستخدم — ترجع Stream من DatabaseEvent
  Stream<DatabaseEvent> watchUserPresence(String uid) {
    return _db.ref('presence/$uid').onValue;
  }
}