import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }
  
  RtcEngine? _engine;

  RtcEngine? get engine => _engine;

  Future<void> requestPermissions(bool isVideo) async {
    try {
      await Permission.microphone.request();
      if (isVideo) {
        await Permission.camera.request();
      }
    } catch (_) {}
  }

  Future<void> initEngine(String appId) async {
    if (_engine != null) return;
    if (appId == 'YOUR_AGORA_APP_ID_HERE' || appId.trim().isEmpty) return; // Skip if invalid
    
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (_) {
      _engine = null;
    }
  }

  Future<String> startCall({
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required String appId,
  }) async {
    final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final callId = 'call_${callerId}_${DateTime.now().millisecondsSinceEpoch}';

    if (_db != null) {
      final callRef = _db!.collection('calls').doc();
      await callRef.set({
        'callerId': callerId,
        'calleeId': calleeId,
        'channelName': channelName,
        'type': isVideo ? 'video' : 'voice',
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await requestPermissions(isVideo);
      await initEngine(appId);

      if (_engine != null) {
        if (isVideo) {
          await _engine!.enableVideo();
        } else {
          await _engine!.disableVideo();
        }

        await _engine!.joinChannel(
          token: '',
          channelId: channelName,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileCommunication,
          ),
        );
      }
      return callRef.id;
    } else {
      // Local/Offline mock call setup
      await requestPermissions(isVideo);
      await initEngine(appId);
      return callId;
    }
  }

  Future<void> joinCall(String callId, String channelName, bool isVideo, String appId) async {
    if (_db != null) {
      await _db!.collection('calls').doc(callId).update({
        'status': 'accepted',
      });
    }

    await requestPermissions(isVideo);
    await initEngine(appId);

    if (_engine != null) {
      if (isVideo) {
        await _engine!.enableVideo();
      }

      await _engine!.joinChannel(
        token: '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    }
  }

  Future<void> declineCall(String callId) async {
    if (_db != null) {
      await _db!.collection('calls').doc(callId).update({
        'status': 'declined',
      });
    }
  }

  Future<void> endCall(String callId) async {
    if (_db != null) {
      await _db!.collection('calls').doc(callId).update({
        'status': 'ended',
      });
    }
    try {
      await _engine?.leaveChannel();
    } catch (_) {}
  }

  Stream<QuerySnapshot> watchIncomingCalls(String myUid) {
    if (_db == null) {
      return const Stream.empty();
    }
    return _db!
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  Future<void> toggleMute(bool muted) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }
}
