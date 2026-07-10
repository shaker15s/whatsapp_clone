import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/call_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class ActiveCallScreen extends StatefulWidget {
  final String callId;
  final bool isVideo;
  final String otherUid;

  const ActiveCallScreen({
    super.key,
    required this.callId,
    required this.isVideo,
    required this.otherUid,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final CallService _callService = CallService();
  bool _muted = false;
  bool _remoteJoined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _registerCallbacks();
  }

  void _registerCallbacks() {
    _callService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteJoined = true;
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteJoined = false;
            _remoteUid = null;
          });
          if (mounted) context.pop();
        },
      ),
    );
  }

  Future<void> _endCall() async {
    await _callService.endCall(widget.callId);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _callService.engine;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // خلفية المكالمة
          if (widget.isVideo && _remoteJoined && _remoteUid != null && engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.callId),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceBright,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.otherUid,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _remoteJoined ? 'متصل حاليًا' : 'يرن الآن...',
                    style: const TextStyle(color: AppColors.outline),
                  ),
                ],
              ),
            ),

          // كاميرتي الشخصية (فيديو مصغر في زاوية الشاشة)
          if (widget.isVideo && engine != null)
            Positioned(
              top: 50,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // لوحة التحكم السفلية بلورية
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              opacity: 0.08,
              blur: 20,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    color: Colors.white,
                    iconSize: 28,
                    onPressed: () async {
                      setState(() => _muted = !_muted);
                      await _callService.toggleMute(_muted);
                    },
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      iconSize: 28,
                      onPressed: _endCall,
                    ),
                  ),
                  if (widget.isVideo)
                    IconButton(
                      icon: const Icon(Icons.cameraswitch),
                      color: Colors.white,
                      iconSize: 28,
                      onPressed: () => _callService.switchCamera(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
