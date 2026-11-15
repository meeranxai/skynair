import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer';

import '../providers/auth_state_provider.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/signup_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/messages/pages/messages_list_page.dart';
import '../../features/messages/pages/chat_page.dart';
import '../../features/explore/pages/explore_page.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/create_post/pages/create_post_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/posts/pages/post_detail_page.dart';
import '../../features/comments/pages/comments_page_enhanced.dart';
import '../../core/models/post_model.dart';
import './layouts/main_layout.dart';

/// Fixed router provider that ONLY watches authentication state
/// This ensures the router ONLY rebuilds on login/logout
/// Profile updates and other data changes DO NOT trigger router rebuilds
final appRouterProvider = Provider<GoRouter>((ref) {
  // ✅ CRITICAL FIX: Only watch authentication state (boolean)
  // DO NOT watch full auth provider or user profile data
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  log(
    '🔄 RouterProvider: Building router with isAuthenticated=$isAuthenticated',
  );

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      log(
        '🔄 RouterProvider: Redirect check - location=$location, isAuth=$isAuthenticated',
      );

      // Allow splash screen
      if (location == '/splash') {
        return null;
      }

      // Redirect to login if not authenticated
      if (!isAuthenticated && location != '/login' && location != '/signup') {
        log('🔄 RouterProvider: Redirecting to /login (not authenticated)');
        return '/login';
      }

      // Redirect to home if authenticated and on auth pages
      if (isAuthenticated && (location == '/login' || location == '/signup')) {
        log('🔄 RouterProvider: Redirecting to /home (already authenticated)');
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const SkynaireHomePage(),
          ),
          GoRoute(path: '/', redirect: (context, state) => '/home'),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/:uid',
            builder: (context, state) {
              final uid = state.pathParameters['uid'];
              return ProfilePage(uid: uid);
            },
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesListPage(),
          ),
          GoRoute(
            path: '/chat/:chatId',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final otherUserId = state.uri.queryParameters['otherUserId']!;
              final otherUserName = state.uri.queryParameters['otherUserName']!;
              final otherUserAvatar =
                  state.uri.queryParameters['otherUserAvatar'];

              return ChatPage(
                chatId: chatId,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserAvatar: otherUserAvatar,
              );
            },
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExplorePage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) {
              final postToEdit = state.extra as PostModel?;
              return CreatePostPage(postToEdit: postToEdit);
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/posts/:postId',
            builder: (context, state) {
              final postId = state.pathParameters['postId']!;
              return PostDetailPage(postId: postId);
            },
          ),
          GoRoute(
            path: '/posts/:postId/comments',
            builder: (context, state) {
              final postId = state.pathParameters['postId']!;
              return CommentsPageEnhanced(postId: postId);
            },
          ),
        ],
      ),
    ],
  );
});
