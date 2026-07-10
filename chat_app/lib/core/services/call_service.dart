import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:permission_handler/permission_handler.dart';

/// خدمة المكالمات - Agora RTC + Firestore signaling
/// 
/// متطلبات:
/// 1. تشغيل `flutterfire configure` لإعداد Firebase
/// 2. إعداد Agora App ID و Token Server
/// 3. إضافة أذونات الميكروفون والكاميرا في AndroidManifest.xml و Info.plist
class CallService {
  /// التحقق من جاهزية Firebase
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// إرجاع مثيل Firestore مع التحقق
  FirebaseFirestore get _db {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. شغل flutterfire configure أولاً.');
    }
    return FirebaseFirestore.instance;
  }

  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  RtcEngine? get engine => _engine;
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[CallService] $msg');
  }

  // ─── Permissions ────────────────────────────────────────────────────────────

  /// طلب أذونات الميكروفون والكاميرا
  /// ترجع true إذا تم منح الأذونات المطلوبة
  Future<bool> requestPermissions(bool isVideo) async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        _log('Microphone permission denied: $mic');
        return false;
      }

      if (isVideo) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          _log('Camera permission denied: $cam');
          return false;
        }
      }
      return true;
    } catch (e) {
      _log('requestPermissions error: $e');
      return false;
    }
  }

  // ─── Agora Engine ───────────────────────────────────────────────────────────

  /// تهيئة محرك Agora
  /// يتطلب App ID صالحاً (ليس فارغاً أو placeholder)
  Future<void> initEngine(String appId) async {
    if (_engine != null) return;

    if (appId.isEmpty || appId.length < 10) {
      throw ArgumentError('Agora App ID غير صالح: يجب أن يكون 32 حرفاً hexadecimal');
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // تسجيل مستمعي الأحداث
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _log('Joined channel: ${connection.channelId}, uid: ${connection.localUid}');
            _eventController.add({
              'type': 'joinSuccess',
              'channel': connection.channelId,
              'uid': connection.localUid,
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _log('Remote user joined: $remoteUid');
            _eventController.add({
              'type': 'userJoined',
              'channel': connection.channelId,
              'remoteUid': remoteUid,
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _log('Remote user left: $remoteUid, reason: $reason');
            _eventController.add({
              'type': 'userLeft',
              'channel': connection.channelId,
              'remoteUid': remoteUid,
              'reason': reason.name,
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            _log('Left channel: ${connection.channelId}');
            _eventController.add({
              'type': 'leaveChannel',
              'channel': connection.channelId,
            });
          },
          onError: (ErrorCodeType err, String msg) {
            _log('Agora error: $err - $msg');
            _eventController.add({
              'type': 'error',
              'code': err.index,
              'message': msg,
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            _log('Token will expire soon, need renewal');
            _eventController.add({
              'type': 'tokenExpiring',
              'channel': connection.channelId,
            });
          },
        ),
      );

      _log('Agora engine initialized successfully');
    } catch (e) {
      _engine = null;
      _log('initEngine error: $e');
      rethrow;
    }
  }

  // ─── Call Signaling (Firestore) ─────────────────────────────────────────────

  /// بدء مكالمة جديدة
  /// ترجع callId للمكالمة المنشأة
Future<String> startCall({
  required String callerId,
  required String calleeId,
  required bool isVideo,
  required String appId,
  required String token, // يجب جلبه من Token Server
  String? channelName, // القناة موحدة بين المتصل والمستقبل
}) async {
  // التحقق من الأذونات أولاً
  final hasPermissions = await requestPermissions(isVideo);
  if (!hasPermissions) {
    throw Exception('لم يتم منح أذونات الميكروفون/الكاميرا');
  }

  await initEngine(appId);

  channelName ??= 'call_${DateTime.now().millisecondsSinceEpoch}_${callerId.hashCode.abs()}';
    _currentChannelName = channelName;
    _currentUid = _generateUid(callerId);

    // إنشاء مستند المكالمة في Firestore
    final callRef = _db.collection('calls').doc();
    final callId = callRef.id;

    await callRef.set({
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'channelName': channelName,
      'callerUid': _currentUid,
      'type': isVideo ? 'video' : 'voice',
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // الانضمام للقناة
    if (isVideo) {
      await _engine!.enableVideo();
    } else {
      await _engine!.disableVideo();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: _currentUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _log('Started call: $callId, channel: $channelName, uid: $_currentUid');
    return callId;
  }

  /// الانضمام لمكالمة قائمة
  Future<void> joinCall({
    required String callId,
    required String channelName,
    required bool isVideo,
    required String appId,
    required String token,
    required String myUid,
  }) async {
    // تحديث حالة المكالمة
    await _db.collection('calls').doc(callId).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await requestPermissions(isVideo);
    await initEngine(appId);

    _currentChannelName = channelName;
    _currentUid = _generateUid(myUid);

    if (isVideo) await _engine!.enableVideo();
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: _currentUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _log('Joined call: $callId, channel: $channelName, uid: $_currentUid');
  }

  /// رفض مكالمة واردة
  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إشارة مكالمة فائتة (عندما لا يرد المستخدم)
  Future<void> markCallMissed(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'missed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إنهاء مكالمة
  Future<void> endCall(String callId) async {
    // تحديث الحالة في Firestore
    await _db.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // مغادرة القناة
    try {
      await _engine?.leaveChannel();
    } catch (e) {
      _log('leaveChannel error: $e');
    }

    _currentChannelName = null;
    _currentUid = null;
    _log('Ended call: $callId');
  }

  // ─── Call History & Queries ─────────────────────────────────────────────────

  /// جلب سجل المكالمات السابقة
  Stream<QuerySnapshot> getCallHistory(String myUid) {
    return _db
        .collection('calls')
        .where(Filter.or(
          Filter('callerId', isEqualTo: myUid),
          Filter('calleeId', isEqualTo: myUid),
        ))
        .where('status', whereIn: ['ended', 'missed', 'declined'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// جلب مكالمة واحدة بالمعرف
  Future<Map<String, dynamic>?> getCallById(String callId) async {
    final doc = await _db.collection('calls').doc(callId).get();
    if (!doc.exists) return null;
    return Map<String, dynamic>.from(doc.data() as Map);
  }

  /// مراقبة المكالمات الواردة (ringing)
  Stream<QuerySnapshot> watchIncomingCalls(String myUid) {
    return _db
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  // ─── In-Call Controls ───────────────────────────────────────────────────────

  Future<void> toggleMute(bool muted) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (e) {
      _log('toggleMute error: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
    } catch (e) {
      _log('switchCamera error: $e');
    }
  }

  // ─── Token Renewal ──────────────────────────────────────────────────────────

  /// تجديد التوكن عند اقتراب انقضائه
  /// يجب استدعاؤها عند استلام حدث tokenExpiring
  Future<void> renewToken(String newToken) async {
    try {
      await _engine?.renewToken(newToken);
      _log('Token renewed successfully');
    } catch (e) {
      _log('renewToken error: $e');
      rethrow;
    }
  }

  // ─── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (e) {
      _log('dispose error: $e');
    }
    _engine = null;
    _currentChannelName = null;
    _currentUid = null;
    await _eventController.close();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// توليد UID رقمي فريد من نص (لتجنب تعارض uid=0)
  int _generateUid(String input) {
    int hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    // Agora uid يجب أن يكون بين 1 و 2^32-1
    return (hash % 2147483647) + 1;
  }
}