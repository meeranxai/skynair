import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/follow_provider.dart';
import '../../stories/pages/story_viewer_page.dart';
import '../../stories/providers/story_provider.dart';

/// Skynaire profile header with modern interface
class SkynaireProfileHeader extends ConsumerStatefulWidget {
  final UserModel user;
  final int postsCount;
  final bool isCurrentUser;

  const SkynaireProfileHeader({
    super.key,
    required this.user,
    required this.postsCount,
    required this.isCurrentUser,
  });

  @override
  ConsumerState<SkynaireProfileHeader> createState() =>
      _SkynaireProfileHeaderState();
}

class _SkynaireProfileHeaderState extends ConsumerState<SkynaireProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;
    final isFollowingAsync = currentUser != null
        ? ref.watch(isFollowingProvider(widget.user.uid))
        : const AsyncValue.data(false);

    final isFollowing = isFollowingAsync.value ?? false;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile info row
          Row(
            children: [
              // Profile picture
              _buildProfilePicture(theme),

              const SizedBox(width: 20),

              // Stats (Posts, Followers, Following)
              Expanded(child: _buildStats(theme)),
            ],
          ),

          const SizedBox(height: 16),

          // Name and bio
          _buildNameAndBio(theme),

          const SizedBox(height: 16),

          // Action buttons
          if (!widget.isCurrentUser) _buildActionButtons(theme, isFollowing),
          if (widget.isCurrentUser) _buildEditProfileButton(theme),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(ThemeData theme) {
    // Watch user stories to check for active stories
    final userStoriesAsync = ref.watch(userStoriesProvider(widget.user.uid));

    return userStoriesAsync.when(
      data: (stories) {
        final hasStories = stories.isNotEmpty;
        final currentUser = ref.read(authProvider).user;
        final allViewed =
            hasStories &&
            currentUser != null &&
            stories.every((s) => s.isViewedBy(currentUser.uid));

        return GestureDetector(
          onTap: () {
            if (hasStories) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StoryViewerPage(stories: stories, initialIndex: 0),
                ),
              );
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasStories && !allViewed
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: hasStories && allViewed
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 2.5,
                    )
                  : !hasStories
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: hasStories ? 2 : 0,
                ),
              ),
              child: ClipOval(
                child: widget.user.photoURL != null
                    ? CachedNetworkImage(
                        imageUrl: widget.user.photoURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            widget.user.displayName.isNotEmpty
                                ? widget.user.displayName[0].toUpperCase()
                                : widget.user.email[0].toUpperCase(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
      loading: () => _buildBasicProfilePicture(theme),
      error: (_, __) => _buildBasicProfilePicture(theme),
    );
  }

  Widget _buildBasicProfilePicture(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: widget.user.photoURL != null
            ? CachedNetworkImage(
                imageUrl: widget.user.photoURL!,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  widget.user.displayName.isNotEmpty
                      ? widget.user.displayName[0].toUpperCase()
                      : widget.user.email[0].toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(theme, widget.postsCount.toString(), 'Posts'),
        _buildStatItem(
          theme,
          widget.user.followersCount.toString(),
          'Followers',
        ),
        _buildStatItem(
          theme,
          widget.user.followingCount.toString(),
          'Following',
        ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndBio(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display name
        Text(
          widget.user.displayName.isNotEmpty
              ? widget.user.displayName
              : widget.user.email.split('@').first,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        // Username
        if (widget.user.username.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '@${widget.user.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],

        // Bio
        if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.user.bio!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],

        // Join date
        const SizedBox(height: 4),
        Text(
          'Joined ${_formatJoinDate(widget.user.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isFollowing) {
    final followState = ref.watch(followProvider);
    final isLoading = followState.isLoading;

    return Row(
      children: [
        // Follow/Unfollow button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _handleFollowToggle(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primary,
              foregroundColor: isFollowing
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isFollowing
                    ? BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      )
                    : BorderSide.none,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFollowing
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        const SizedBox(width: 8),

        // Message button
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleMessage(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _handleEditProfile(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to follow users')),
        );
      }
      return;
    }

    final isFollowing =
        ref.read(isFollowingProvider(widget.user.uid)).value ?? false;
    final isRequested =
        ref.read(isFollowRequestedProvider(widget.user.uid)).value ?? false;

    try {
      await ref
          .read(followProvider.notifier)
          .toggleFollow(
            widget.user.uid,
            isFollowing: isFollowing,
            isRequested: isRequested,
          );

      if (mounted) {
        final newIsFollowing =
            ref.read(isFollowingProvider(widget.user.uid)).value ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newIsFollowing
                  ? 'You are now following ${widget.user.displayName}'
                  : 'You unfollowed ${widget.user.displayName}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleMessage() {
    // Navigate to chat with this user
    // You can implement this based on your messaging system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleEditProfile() {
    // Navigate to edit profile page
    // You can implement this based on your settings/profile edit system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
