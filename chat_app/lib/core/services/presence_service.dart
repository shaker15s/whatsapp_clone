import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  FirebaseDatabase? get _db {
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }

  void setOnline(String uid) {
    if (_db == null) return;
    try {
      final myRef = _db!.ref('presence/$uid');
      
      // عند الانقطاع الفجائي، السيرفر يحدث الحالة
      myRef.onDisconnect().set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      });

      // تعيين الحالة الحالية متصل
      myRef.set({
        'state': 'online',
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  void setOffline(String uid) {
    if (_db == null) return;
    try {
      final myRef = _db!.ref('presence/$uid');
      myRef.set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  Stream<dynamic> watchUserPresence(String uid) {
    if (_db == null) {
      // Return a simulated stream of online/offline status
      return Stream.value(null);
    }
    return _db!.ref('presence/$uid').onValue;
  }
}
