import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chats_tab.dart';
import '../calls/calls_tab.dart';
import '../status/status_tab.dart';
import '../communities/communities_screen.dart';
import '../../core/services/call_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final CallService _callService = CallService();
  late String _myUid;
  bool _dialogShown = false;

  // Track previous index for fade transition direction
  int _previousIndex = 0;

  // Tab labels
  static const _tabLabels = ['المحادثات', 'المكالمات', 'الحالات', 'المجتمعات'];

  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _myUid = _authService.currentUser?.uid ?? '';
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    if (_currentIndex == 0) _fabAnimController.value = 1.0;

    _listenToIncomingCalls();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _listenToIncomingCalls() {
    if (_myUid.isEmpty) return;
    _callService.watchIncomingCalls(_myUid).listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_dialogShown && mounted) {
        final callDoc = snapshot.docs.first;
        final data = callDoc.data() as Map<String, dynamic>;

        _dialogShown = true;
        _showIncomingCallDialog(callDoc.id, data);
      }
    });
  }

  void _showIncomingCallDialog(String callId, Map<String, dynamic> data) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => PopScope(
        canPop: false,
        child: IncomingCallDialog(
          callId: callId,
          callerId: data['callerId'] ?? '',
          channelName: data['channelName'] ?? '',
          isVideo: data['type'] == 'video',
          onAccept: () {
            Navigator.of(ctx).pop();
            context.push('/call/active', extra: {
              'callId': callId,
              'channelName': data['channelName'],
              'isVideo': data['type'] == 'video',
              'token': '', // Token will be fetched from server in production
              'myUid': _myUid,
            });
            _dialogShown = false;
          },
          onReject: () {
            Navigator.of(ctx).pop();
            _callService.declineCall(callId);
            _dialogShown = false;
          },
        ),
      ),
    );
  }

  void _onTabChanged(int newIndex) {
    if (newIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });

      // Animate FAB
      if (newIndex == 0) {
        _fabAnimController.forward();
      } else {
        _fabAnimController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      Color(0xFF0F223D),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            // Animated tab content with fade transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final slideFrom = _currentIndex > _previousIndex ? 20.0 : -20.0;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(slideFrom / 400, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                    child: child,
                  ),
                );
              },
              child: _tabs[_currentIndex],
            ),
          ],
        ),
      ),
      // Animated FAB
      floatingActionButton: ScaleTransition(
        scale: _fabAnimController,
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () => context.push('/contacts'),
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ),
      // Glass bottom nav
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GlassContainer(
            height: 72,
            borderRadius: BorderRadius.circular(24),
            opacity: 0.06,
            blur: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.forum_outlined, Icons.forum),
                _buildNavItem(1, Icons.phone_outlined, Icons.phone),
                _buildNavItem(2, Icons.circle_outlined, Icons.trip_origin),
                _buildNavItem(3, Icons.groups_outlined, Icons.groups),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> get _tabs => [
        const ChatsTab(),
        const CallsTab(),
        const StatusTab(),
        const CommunitiesScreen(),
      ];

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabChanged(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              _tabLabels[index],
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incoming Call Dialog Widget ────────────────────────────────────────────
class IncomingCallDialog extends StatelessWidget {
  final String callId;
  final String callerId;
  final String channelName;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    super.key,
    required this.callId,
    required this.callerId,
    required this.channelName,
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surfaceContainerHigh, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caller avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                size: 40,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isVideo ? 'مكالمة فيديو واردة' : 'مكالمة صوتية واردة',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قناة: $channelName',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Caller identifier (placeholder — replace with real name)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    callerId.isEmpty ? 'مستخدم Lumina' : callerId,
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject
                _CallActionButton(
                  icon: Icons.call_end_rounded,
                  label: 'رفض',
                  color: const Color(0xFFFF5252),
                  onTap: onReject,
                ),
                // Accept
                _CallActionButton(
                  icon: Icons.call_rounded,
                  label: 'قبول',
                  color: const Color(0xFF4CAF50),
                  onTap: onAccept,
                  isAccept: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isAccept;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isAccept = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isAccept ? 0.5 : 0.3),
              blurRadius: isAccept ? 24 : 16,
              spreadRadius: isAccept ? 4 : 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
