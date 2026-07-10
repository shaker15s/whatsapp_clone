import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // معالجة الإشعارات الواردة بالخلفية
}

class NotificationService {
  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
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

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init(String uid) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    try {
      await _localNotifications.initialize(initSettings);
    } catch (_) {}

    if (_fcm == null) return;

    try {
      await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _fcm!.getToken();
      if (token != null && _db != null) {
        await _db!.collection('users').doc(uid).update({'fcmToken': token});
      }

      _fcm!.onTokenRefresh.listen((newToken) {
        if (_db != null) {
          _db!.collection('users').doc(uid).update({'fcmToken': newToken});
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message) {
    try {
      const androidDetails = AndroidNotificationDetails(
        'chat_channel',
        'رسايل الشات',
        channelDescription: 'إشعارات الرسايل والمكالمات',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'رسالة جديدة',
        message.notification?.body ?? '',
        details,
      );
    } catch (_) {}
  }
}
