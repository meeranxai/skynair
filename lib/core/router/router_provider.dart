import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/signup_page.dart';
import '../../features/auth/pages/email_verification_page.dart';
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
import '../../features/profile/pages/archive_page.dart';
import '../../features/coming_soon/pages/coming_soon_page.dart';

import '../../core/models/post_model.dart';
import './layouts/main_layout.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final firebaseUser = authState.firebaseUser;

      // 1. Loading state protection
      if (isLoading) {
        return null;
      }

      // 2. Email verification check
      if (isAuthenticated &&
          firebaseUser != null &&
          !firebaseUser.emailVerified &&
          state.matchedLocation != '/email-verification') {
        return '/email-verification';
      }

      // 3. Not authenticated -> Login
      if (!isAuthenticated &&
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/signup' &&
          state.matchedLocation != '/email-verification') {
        return '/login';
      }

      // 4. Authenticated but NO profile -> Force Login or Signup (unless loading)
      final isProfileMissing = isAuthenticated && !authState.hasProfile;
      if (isProfileMissing && 
          state.matchedLocation != '/signup' && 
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/email-verification') {
        return '/login'; 
      }

      // 5. Authenticated & Profile loaded -> Home (if on auth pages)
      if (isAuthenticated &&
          authState.hasProfile &&
          firebaseUser != null &&
          firebaseUser.emailVerified &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup' ||
              state.matchedLocation == '/email-verification')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [

          GoRoute(path: '/', redirect: (context, state) => '/home'),
          GoRoute(
            path: '/home',
            builder: (context, state) => const SkynaireHomePage(),
          ),
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
            path: '/u/:username',
            builder: (context, state) {
              final username = state.pathParameters['username'];
              return ProfilePage(username: username);
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
            path: '/coming-soon-media',
            builder: (context, state) => const ComingSoonPage(
              featureName: 'Media Feed',
              description:
                  'Photo posts, stories, and media sharing will be available in Phase 2',
              icon: Icons.photo_library,
            ),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) {
              final postToEdit = state.extra as PostModel?;
              final postType = state.uri.queryParameters['type'];
              return CreatePostPage(postToEdit: postToEdit, postType: postType);
            },
          ),
          GoRoute(
            path: '/archive',
            builder: (context, state) => const ArchivePage(),
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

/// A notifier that triggers router refresh when auth state changes significantly
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(
      authProvider.select((value) => '${value.isAuthenticated}_${value.isLoading}'),
      (_, __) => notifyListeners(),
    );
  }
}
