import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// معالج الإشعارات الخلفية - يجب أن يكون دالة عليا (top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[NotificationService] Background message received: ${message.messageId}');
  // يمكن إضافة معالجة بيانات هنا (مثل: تحديث قاعدة بيانات محلية، إظهار إشعار محلي، إلخ)
}

/// خدمة الإشعارات - FCM + Local Notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _currentUid;

  /// التحقق من جاهزية Firebase
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseMessaging get _fcm {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. شغل flutterfire configure أولاً.');
    }
    return FirebaseMessaging.instance;
  }

  FirebaseFirestore get _db {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. شغل flutterfire configure أولاً.');
    }
    return FirebaseFirestore.instance;
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[NotificationService] $msg');
  }

  /// تهيئة الخدمة - يجب استدعاؤها بعد تسجيل الدخول
  Future<void> init(String uid) async {
    _currentUid = uid;

    // 1. تهيئة الإشعارات المحلية (Android + iOS)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(initSettings);
      _log('Local notifications initialized');
    } catch (e) {
      _log('Local notifications init error: $e');
      rethrow;
    }

    // 2. تهيئة FCM
    try {
      // طلب الأذونات (iOS يتطلب ذلك)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _log('FCM permission: ${settings.authorizationStatus}');

      // الحصول على التوكن وحفظه
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
        _log('FCM token saved for $uid');
      }

      // مراقبة تحديث التوكن
      _fcm.onTokenRefresh.listen((newToken) async {
        if (_currentUid != null) {
          await _db.collection('users').doc(_currentUid!).update({'fcmToken': newToken});
          _log('FCM token refreshed for $_currentUid');
        }
      });

      // إشعارات المقدمة (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // تسجيل معالج الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    } catch (e) {
      _log('FCM init error: $e');
      rethrow;
    }
  }

  /// استدعاء عند تسجيل الخروج لمسح توكن FCM
  Future<void> clearToken() async {
    if (_currentUid == null) return;

    try {
      await _fcm.deleteToken();
      await _db.collection('users').doc(_currentUid!).update({'fcmToken': null});
      _log('FCM token cleared for $_currentUid');
    } catch (e) {
      _log('clearToken error: $e');
    } finally {
      _currentUid = null;
    }
  }

  /// إظهار إشعار محلي من رسالة FCM
  void _showLocalNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'chat_channel',
        'رسايل الشات',
        channelDescription: 'إشعارات الرسايل والمكالمات',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      _localNotifications.show(
        message.hashCode,
        notification.title ?? 'رسالة جديدة',
        notification.body ?? '',
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    } catch (e) {
      _log('showLocalNotification error: $e');
    }
  }
}