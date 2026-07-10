import 'package:flutter/material.dart';
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

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final CallService _callService = CallService();
  late final String _myUid = _authService.currentUser?.uid ?? '';
  bool _dialogShown = false;

  final List<Widget> _tabs = [
    const ChatsTab(),
    const CallsTab(),
    const StatusTab(),
    const CommunitiesScreen(),
  ];

  final List<String> _titles = [
    'المحادثات',
    'المكالمات',
    'الحالات',
    'المجتمعات',
  ];

  @override
  void initState() {
    super.initState();
    _listenToIncomingCalls();
  }

  void _listenToIncomingCalls() {
    if (_myUid.isEmpty) return;
    _callService.watchIncomingCalls(_myUid).listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_dialogShown && mounted) {
        final callDoc = snapshot.docs.first;
        final data = callDoc.data() as Map<String, dynamic>;
        
        _dialogShown = true;
        context.push(
          '/call/incoming',
          extra: {
            'callId': callDoc.id,
            'callerId': data['callerId'],
            'channelName': data['channelName'],
            'isVideo': data['type'] == 'video',
          },
        ).then((_) => _dialogShown = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'logout') {
                _authService.logout().then((_) {
                  context.go('/welcome');
                });
              } else if (val == 'group') {
                context.push('/group/create');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'group', child: Text('مجموعة جديدة')),
              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // الخلفية المدرجة
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    Color(0xFF0F223D), // نبرة خفيفة
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          // المحتوى
          _tabs[_currentIndex],
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => context.push('/contacts'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GlassContainer(
            height: 64,
            borderRadius: BorderRadius.circular(24),
            opacity: 0.05,
            blur: 15,
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

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          isSelected ? solidIcon : outlineIcon,
          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }
}
