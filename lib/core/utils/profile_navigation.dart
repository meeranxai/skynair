import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../features/profile/pages/profile_page.dart';

class ProfileNavigation {
  /// Navigate to a user's profile by UID
  static void navigateToProfile(BuildContext context, String userId) {
    if (userId.isEmpty) return;

    // Use GoRouter for navigation
    context.push('/profile/$userId');
  }

  /// Navigate to a user's profile by username
  static void navigateToProfileByUsername(BuildContext context, String username) {
    if (username.isEmpty) return;

    // Use GoRouter for navigation (assuming route exists or will be added)
    context.push('/u/$username');
  }

  /// Navigate to current user's profile
  static void navigateToOwnProfile(BuildContext context) {
    context.go('/profile');
  }

  /// Navigate to profile with Material page route (for custom transitions)
  static void navigateToProfileWithRoute(BuildContext context, String userId) {
    if (userId.isEmpty) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ProfilePage(uid: userId)));
  }

  /// Create a tappable widget that navigates to profile
  static Widget createProfileTappable({
    required Widget child,
    required String userId,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        navigateToProfile(context, userId);
      },
      child: child,
    );
  }

  /// Create a tappable avatar that navigates to profile
  static Widget createTappableAvatar({
    required String userId,
    required BuildContext context,
    String? photoURL,
    String? displayName,
    double radius = 20,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        navigateToProfile(context, userId);
      },
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipOval(
          child: (photoURL != null && photoURL.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: photoURL,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: SizedBox(
                      width: radius,
                      height: radius,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultAvatar(radius, displayName),
                )
              : _buildDefaultAvatar(radius, displayName),
        ),
      ),
    );
  }

  static Widget _buildDefaultAvatar(double radius, String? displayName) {
    return Center(
      child: Text(
        displayName?.isNotEmpty == true ? displayName![0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Create a tappable username that navigates to profile
  static Widget createTappableUsername({
    required String userId,
    required String username,
    required BuildContext context,
    TextStyle? style,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        navigateToProfile(context, userId);
      },
      child: Text(
        '@$username',
        style:
            style?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.none,
            ) ??
            TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
