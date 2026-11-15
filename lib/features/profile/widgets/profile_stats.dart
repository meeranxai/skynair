import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../pages/profile_page.dart';

class ProfileStats extends ConsumerWidget {
  final UserModel user;

  const ProfileStats({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).user?.uid;
    final isOwnProfile = currentUserId == user.uid;
    final isFollowingAsync = ref.watch(isFollowingProvider(user.uid));
    
    // Watch the user profile to get real-time updates
    final updatedUserAsync = ref.watch(userProfileByIdProvider(user.uid));

    return updatedUserAsync.when(
      data: (updatedUser) {
        final displayUser = updatedUser ?? user;
        final bool isAuthorized = isFollowingAsync.maybeWhen(
          data: (isFollowing) => isOwnProfile || !displayUser.isPrivate || isFollowing,
          orElse: () => isOwnProfile || !displayUser.isPrivate,
        );
        
        return _buildStatsContainer(context, theme, displayUser, isAuthorized);
      },
      loading: () => _buildStatsContainer(context, theme, user, isOwnProfile || !user.isPrivate),
      error: (error, stackTrace) => _buildStatsContainer(context, theme, user, isOwnProfile || !user.isPrivate),
    );
  }

  Widget _buildStatsContainer(
    BuildContext context,
    ThemeData theme,
    UserModel displayUser,
    bool isAuthorized,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            theme,
            displayUser.postsCount,
            'Posts',
            Icons.photo_library_outlined,
            isAuthorized ? () => _navigateToUserPosts(context) : null,
          ),
          _buildDivider(theme),
          _buildStatItem(
            context,
            theme,
            displayUser.followersCount,
            'Followers',
            Icons.people_outline,
            isAuthorized ? () => _navigateToFollowers(context, displayUser) : null,
          ),
          _buildDivider(theme),
          _buildStatItem(
            context,
            theme,
            displayUser.followingCount,
            'Following',
            Icons.person_add_outlined,
            isAuthorized ? () => _navigateToFollowing(context, displayUser) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    int count,
    String label,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: onTap == null ? 0.5 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  children: [
                    // Count with enhanced typography and animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: count.toDouble()),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          _formatCount(value.toInt()),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),

                    // Label
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            theme.colorScheme.outline.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    // Safety check: ensure count is never negative
    final safeCount = count < 0 ? 0 : count;

    if (safeCount < 1000) {
      return safeCount.toString();
    } else if (safeCount < 1000000) {
      final k = safeCount / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = safeCount / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }

  void _navigateToFollowers(BuildContext context, UserModel displayUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FollowersPage(
          userId: displayUser.uid,
          userName: displayUser.displayName,
        ),
      ),
    );
  }

  void _navigateToFollowing(BuildContext context, UserModel displayUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FollowingPage(
          userId: displayUser.uid,
          userName: displayUser.displayName,
        ),
      ),
    );
  }

  void _navigateToUserPosts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scrolling to posts section...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  void _navigateToUserArticles(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scrolling to articles section...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

// Followers Page
class FollowersPage extends ConsumerWidget {
  final String userId;
  final String userName;

  const FollowersPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Force refresh to get latest data
    ref.refresh(userFollowersProvider(userId));
    final followersAsync = ref.watch(userFollowersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Followers'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: followersAsync.when(
        data: (followers) {
          if (followers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No followers yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return _buildUserListItem(context, theme, follower, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading followers',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListItem(
    BuildContext context,
    ThemeData theme,
    UserModel user,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.photoURL != null
              ? CachedNetworkImageProvider(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (user.isVerified)
              Icon(Icons.verified, color: theme.colorScheme.primary, size: 16),
          ],
        ),
        subtitle: Text(
          '@${user.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        onTap: () {
          // Navigate to user's profile
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProfilePage(uid: user.uid)),
          );
        },
      ),
    );
  }
}

// Following Page
class FollowingPage extends ConsumerWidget {
  final String userId;
  final String userName;

  const FollowingPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Force refresh to get latest data
    ref.refresh(userFollowingProvider(userId));
    final followingAsync = ref.watch(userFollowingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Following'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: followingAsync.when(
        data: (following) {
          if (following.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not following anyone yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: following.length,
            itemBuilder: (context, index) {
              final followingUser = following[index];
              return _buildUserListItem(context, theme, followingUser, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading following',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListItem(
    BuildContext context,
    ThemeData theme,
    UserModel user,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.photoURL != null
              ? CachedNetworkImageProvider(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (user.isVerified)
              Icon(Icons.verified, color: theme.colorScheme.primary, size: 16),
          ],
        ),
        subtitle: Text(
          '@${user.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        onTap: () {
          // Navigate to user's profile
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProfilePage(uid: user.uid)),
          );
        },
      ),
    );
  }
}
