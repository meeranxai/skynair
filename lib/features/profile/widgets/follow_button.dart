import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/auth_provider.dart';

class FollowButton extends ConsumerWidget {
  final String targetUserId;
  final String? targetUsername;
  final bool isCompact;
  final EdgeInsets? padding;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.targetUsername,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.uid;

    // Don't show follow button for own profile or when not logged in
    if (currentUserId == null || currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));
    final isRequestedAsync = ref.watch(isFollowRequestedProvider(targetUserId));
    final followState = ref.watch(followProvider);

    final isFollowing = isFollowingAsync.value ?? false;
    final isRequested = isRequestedAsync.value ?? false;

    return _buildFollowButton(
      context,
      ref,
      theme,
      isFollowing,
      isRequested,
      followState.isLoading,
      currentUserId,
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isFollowing,
    bool isRequested,
    bool isLoading,
    String currentUserId,
  ) {
    // Determine button appearance
    final Color bgColor = isFollowing || isRequested
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;
    final Color fgColor = isFollowing || isRequested
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;
    
    String label = 'Follow';
    IconData icon = Icons.person_add;
    
    if (isFollowing) {
      label = 'Unfollow';
      icon = Icons.person_remove;
    } else if (isRequested) {
      label = 'Requested';
      icon = Icons.hourglass_empty;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                try {
                  print('🔘 Follow button pressed for user: $targetUserId');
                  print('📊 Current state - isFollowing: $isFollowing, isRequested: $isRequested');
                  
                  await ref.read(followProvider.notifier).toggleFollow(
                        targetUserId,
                        isFollowing: isFollowing,
                        isRequested: isRequested,
                      );
                  
                  print('✅ Toggle follow completed successfully');
                  
                  // Refresh the providers after action
                  ref.invalidate(isFollowingProvider(targetUserId));
                  ref.invalidate(isFollowRequestedProvider(targetUserId));
                  
                  // IMPORTANT: Invalidate the profile provider so the stats (followers/following count) update
                  // This is defined in user_profile_provider.dart which should be imported if not already
                  // But since we are using ref, we can just use the provider name.
                  // We need to ensure userProfileByIdProvider is available here.
                  
                  print('🔄 Providers invalidated, UI should update');
                  
                  // Show success feedback
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFollowing
                              ? 'Unfollowed successfully'
                              : isRequested
                                  ? 'Request cancelled'
                                  : 'Followed successfully',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Follow button error: $e');
                  
                  // Show error feedback
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: theme.colorScheme.error,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: isCompact ? 8 : 12,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            side: isFollowing || isRequested
                ? BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  )
                : BorderSide.none,
          ),
          elevation: isFollowing || isRequested ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                width: isCompact ? 16 : 20,
                height: isCompact ? 16 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: isCompact ? 16 : 18),
                  SizedBox(width: isCompact ? 4 : 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: isCompact ? 8 : 12,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        ),
      ),
      child: SizedBox(
        width: isCompact ? 16 : 20,
        height: isCompact ? 16 : 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: isCompact ? 8 : 12,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_problem,
            size: isCompact ? 16 : 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'Follow',
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
