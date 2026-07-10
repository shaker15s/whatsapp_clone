import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/call_service.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class IncomingCallOverlay extends StatelessWidget {
  final String callId;
  final String callerId;
  final String channelName;
  final bool isVideo;

  const IncomingCallOverlay({
    super.key,
    required this.callId,
    required this.callerId,
    required this.channelName,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final callService = CallService();

    return Scaffold(
      backgroundColor: AppColors.background.withOpacity(0.95),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppColors.surfaceBright,
                    child: Icon(Icons.person, size: 55, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  callerId,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  isVideo ? 'مكالمة فيديو واردة...' : 'مكالمة صوتية واردة...',
                  style: const TextStyle(color: AppColors.outline, fontSize: 16),
                ),
              ],
            ),
            
            // أزرار القبول والرفض البلورية
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      iconSize: 28,
                      onPressed: () async {
                        await callService.declineCall(callId);
                        if (context.mounted) context.pop();
                      },
                    ),
                  ),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Colors.white),
                      iconSize: 28,
                      onPressed: () async {
                        await callService.joinCall(callId, channelName, isVideo, AppConfig.agoraAppId);
                        if (context.mounted) {
                          context.pushReplacement(
                            '/call/active',
                            extra: {
                              'callId': callId,
                              'isVideo': isVideo,
                              'otherUid': callerId,
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
