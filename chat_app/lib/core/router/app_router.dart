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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = AuthService().currentUser;
    final loggingIn = state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/welcome';

    if (user == null) {
      if (!loggingIn && state.matchedLocation != '/') {
        return '/welcome';
      }
    } else {
      if (loggingIn || state.matchedLocation == '/') {
        return '/home';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth/phone',
      builder: (context, state) => const PhoneAuthScreen(),
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpScreen(
          verificationId: extra?['verificationId'] ?? '',
          phoneNumber: extra?['phoneNumber'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/auth/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeLayout(),
    ),
    GoRoute(
      path: '/chat/:chatId',
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
      path: '/call/incoming',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return IncomingCallOverlay(
          callId: extra['callId'],
          callerId: extra['callerId'],
          channelName: extra['channelName'],
          isVideo: extra['isVideo'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/call/active',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ActiveCallScreen(
          callId: extra['callId'],
          isVideo: extra['isVideo'] ?? false,
          otherUid: extra['otherUid'],
        );
      },
    ),
    GoRoute(
      path: '/group/create',
      builder: (context, state) => const GroupCreateScreen(),
    ),
    GoRoute(
      path: '/group/:groupId/info',
      builder: (context, state) => GroupInfoScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/group/:groupId/invite',
      builder: (context, state) => GroupInviteScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/communities',
      builder: (context, state) => const CommunitiesScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsSelectScreen(),
    ),
    GoRoute(
      path: '/contact/:contactId',
      builder: (context, state) => ContactDetailScreen(contactId: state.pathParameters['contactId']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsMenuScreen(),
    ),
    GoRoute(
      path: '/settings/chats',
      builder: (context, state) => const ChatSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/storage',
      builder: (context, state) => const StorageSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
  ],
);
