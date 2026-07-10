import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/auth/phone_auth_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/chats/home_layout.dart';
import '../../features/chats/chat_detail_screen.dart';
import '../../features/calls/active_call_screen.dart';
import '../../features/calls/incoming_call_overlay.dart';
import '../../features/groups/group_create_screen.dart';
import '../../features/groups/group_info_screen.dart';
import '../../features/groups/group_invite_screen.dart';
import '../../features/communities/communities_screen.dart';
import '../../features/contacts/contacts_select_screen.dart';
import '../../features/contacts/contact_detail_screen.dart';
import '../../features/settings/settings_menu_screen.dart';
import '../../features/settings/chat_settings_screen.dart';
import '../../features/settings/privacy_settings_screen.dart';
import '../../features/settings/storage_settings_screen.dart';
import '../../features/settings/security_settings_screen.dart';

import '../../core/services/auth_service.dart';

// Route path constants — prevents typos in navigation calls
class AppRoutes {
  static const root = '/';
  static const welcome = '/welcome';
  static const phoneAuth = '/auth/phone';
  static const otp = '/auth/otp';
  static const profileSetup = '/auth/profile-setup';
  static const home = '/home';
  static const chat = '/chat';
  static const callIncoming = '/call/incoming';
  static const callActive = '/call/active';
  static const groupCreate = '/group/create';
  static const groupInfo = '/group';
  static const groupInvite = '/group/invite';
  static const communities = '/communities';
  static const contacts = '/contacts';
  static const contactDetail = '/contact';
  static const settings = '/settings';
  static const settingsChats = '/settings/chats';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsStorage = '/settings/storage';
  static const settingsSecurity = '/settings/security';
}

// Error screen for unmatched routes
class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('الصفحة غير موجودة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.welcome),
                icon: const Icon(Icons.home),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Auth state notifier to drive GoRouter reactively
class _AuthStateNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _sub;

  _AuthStateNotifier() {
    _sub = _authService.authStateChanges().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthStateNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.root,
  // Re-evaluate redirects whenever auth state changes
  refreshListenable: _authNotifier,
  // Handle unmatched routes
  errorBuilder: (context, state) => _ErrorScreen(error: 'مسار غير معروف: ${state.uri}'),
  redirect: (context, state) {
    final user = AuthService().currentUser;
    final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
        state.matchedLocation == AppRoutes.welcome;

    if (user == null) {
      if (!isAuthRoute && state.matchedLocation != AppRoutes.root) {
        return AppRoutes.welcome;
      }
    } else {
      if (isAuthRoute || state.matchedLocation == AppRoutes.root) {
        return AppRoutes.home;
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.root,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.phoneAuth,
      builder: (context, state) => const PhoneAuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpScreen(
          verificationId: extra?['verificationId'] ?? '',
          phoneNumber: extra?['phoneNumber'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeLayout(),
    ),
    GoRoute(
      path: '${AppRoutes.chat}/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final extra = state.extra as Map<String, dynamic>?;
        return ChatDetailScreen(
          chatId: chatId,
          myUid: extra?['myUid'] ?? '',
          otherUid: extra?['otherUid'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.callIncoming,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return IncomingCallOverlay(
          callId: extra['callId'] as String? ?? '',
          callerId: extra['callerId'] as String? ?? '',
          channelName: extra['channelName'] as String? ?? '',
          isVideo: extra['isVideo'] as bool? ?? false,
          token: extra['token'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.callActive,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ActiveCallScreen(
          callId: extra['callId'] as String? ?? '',
          isVideo: extra['isVideo'] as bool? ?? false,
          otherUid: extra['otherUid'] as String? ?? '',
          channelName: extra['channelName'] as String? ?? '',
          token: extra['token'] as String? ?? '',
          myUid: extra['myUid'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.groupCreate,
      builder: (context, state) => const GroupCreateScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.groupInfo}/:groupId',
      builder: (context, state) => GroupInfoScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '${AppRoutes.groupInvite}/:groupId',
      builder: (context, state) => GroupInviteScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: AppRoutes.communities,
      builder: (context, state) => const CommunitiesScreen(),
    ),
    GoRoute(
      path: AppRoutes.contacts,
      builder: (context, state) => const ContactsSelectScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.contactDetail}/:contactId',
      builder: (context, state) => ContactDetailScreen(contactId: state.pathParameters['contactId']!),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsMenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsChats,
      builder: (context, state) => const ChatSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsPrivacy,
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsStorage,
      builder: (context, state) => const StorageSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsSecurity,
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
  ],
);
