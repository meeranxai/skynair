import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/blocking_provider.dart';

class EnhancedFollowButton extends ConsumerStatefulWidget {
  final String userId;
  final String displayName;
  final bool isCompact;
  final EdgeInsets? padding;

  const EnhancedFollowButton({
    super.key,
    required this.userId,
    required this.displayName,
    this.isCompact = false,
    this.padding,
  });

  @override
  ConsumerState<EnhancedFollowButton> createState() =>
      _EnhancedFollowButtonState();
}

class _EnhancedFollowButtonState extends ConsumerState<EnhancedFollowButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).user?.uid;

    // Don't show follow button for own profile
    if (currentUserId == null || currentUserId == widget.userId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingProvider(widget.userId));
    final isRequestedAsync = ref.watch(isFollowRequestedProvider(widget.userId));
    final followState = ref.watch(followProvider);

    // Check if user is blocked (with better error handling)
    final isBlockedAsync = ref.watch(isUserBlockedProvider(widget.userId));
    final isBlocked = isBlockedAsync.when(
      data: (blocked) => blocked,
      loading: () => false, // Don't hide button while loading
      error: (error, stackTrace) {
        // Log error but don't break the UI
        print('⚠️ Block check failed: $error');
        return false; // Default to not blocked on error
      },
    );

    // If user is blocked, don't show follow button
    if (isBlocked) {
      return const SizedBox.shrink();
    }

    // Extract values with defaults to prevent infinite loading states
    final isFollowing = isFollowingAsync.value ?? false;
    final isRequested = isRequestedAsync.value ?? false;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: _buildFollowButton(
            context,
            theme,
            isFollowing,
            isRequested,
            followState.isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    ThemeData theme,
    bool isFollowing,
    bool isRequested,
    bool isLoading,
  ) {
    String buttonText = 'Follow';
    IconData buttonIcon = Icons.person_add;
    
    if (isFollowing) {
      buttonText = 'Following';
      buttonIcon = Icons.person_remove;
    } else if (isRequested) {
      buttonText = 'Requested';
      buttonIcon = Icons.hourglass_empty;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleFollowToggle,
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 24),
          child: Container(
            padding:
                widget.padding ??
                (widget.isCompact
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            decoration: BoxDecoration(
              gradient: isFollowing || isRequested
                  ? null
                  : LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
              color: isFollowing || isRequested
                  ? theme.colorScheme.surfaceContainerHighest
                  : null,
              borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 24),
              border: isFollowing || isRequested
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
              boxShadow: isFollowing || isRequested
                  ? null
                  : [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: isLoading
                ? SizedBox(
                    width: widget.isCompact ? 16 : 20,
                    height: widget.isCompact ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFollowing
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        buttonIcon,
                        size: widget.isCompact ? 16 : 18,
                        color: isFollowing || isRequested
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onPrimary,
                      ),
                      if (!widget.isCompact) ...[
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isFollowing || isRequested
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return Container(
      padding:
          widget.padding ??
          (widget.isCompact
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 24),
      ),
      child: SizedBox(
        width: widget.isCompact ? 16 : 20,
        height: widget.isCompact ? 16 : 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  void _handleFollowToggle() async {
    try {
      final isFollowing =
          ref.read(isFollowingProvider(widget.userId)).value ?? false;

      // Safely get isRequested with fallback
      bool isRequested = false;
      try {
        isRequested =
            ref.read(isFollowRequestedProvider(widget.userId)).value ?? false;
      } catch (e) {
        print('⚠️ Could not get follow request status: $e');
        // Continue with isRequested = false
      }

      await ref
          .read(followProvider.notifier)
          .toggleFollow(
            widget.userId,
            isFollowing: isFollowing,
            isRequested: isRequested,
          );

      if (mounted) {
        final newIsFollowing =
            ref.read(isFollowingProvider(widget.userId)).value ?? false;
        final message = newIsFollowing
            ? 'You are now following ${widget.displayName}'
            : 'You unfollowed ${widget.displayName}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
