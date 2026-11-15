import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/stories/providers/story_provider.dart';
import '../../features/stories/pages/story_viewer_page.dart';
import '../providers/auth_provider.dart';
import '../providers/user_providers.dart';
import 'image_viewer_screen.dart';

class LiveUserAvatar extends ConsumerWidget {
  final String userId;
  final double radius;
  final String? fallbackUrl;
  final String? fallbackName;
  final bool enableStoryClick;

  const LiveUserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.fallbackUrl,
    this.fallbackName,
    this.enableStoryClick = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileByIdProvider(userId));
    final storiesAsync = ref.watch(userStoriesProvider(userId));
    final currentUser = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return userAsync.when(
      data: (user) {
        final avatarUrl = user?.photoURL ?? fallbackUrl;
        
        return storiesAsync.maybeWhen(
          data: (stories) {
            final activeStories = stories.where((s) => !s.isExpired).toList();
            final hasStory = activeStories.isNotEmpty;
            final hasViewedAll = hasStory && activeStories.every((s) => s.isViewedBy(currentUser?.uid ?? ''));

            Widget avatar = _buildAvatar(context, theme, avatarUrl, user?.displayName);

            if (hasStory) {
              avatar = Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasViewedAll
                      ? null
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: hasViewedAll
                      ? Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : null,
                ),
                child: avatar,
              );
            }

            if (enableStoryClick) {
              return GestureDetector(
                onTap: () {
                  if (hasStory) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewerPage(stories: activeStories),
                      ),
                    );
                  } else if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != 'null') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(
                          imageUrl: avatarUrl,
                          heroTag: 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ),
                    );
                  }
                },
                child: avatar,
              );
            }

            return avatar;
          },
          orElse: () => _buildAvatar(context, theme, avatarUrl, user?.displayName),
        );
      },
      loading: () => _buildFallback(theme),
      error: (_, __) => _buildFallback(theme),
    );
  }

  Widget _buildAvatar(BuildContext context, ThemeData theme, String? avatarUrl, String? displayName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != 'null') {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        (displayName ?? fallbackName ?? 'U').isNotEmpty
            ? (displayName ?? fallbackName ?? 'U')[0].toUpperCase()
            : 'U',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    if (fallbackUrl != null && fallbackUrl!.isNotEmpty && fallbackUrl != 'null') {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: CachedNetworkImageProvider(fallbackUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person, size: radius, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class LiveUserDisplayName extends ConsumerWidget {
  final String userId;
  final String fallbackName;
  final TextStyle? style;
  final bool showVerified;

  const LiveUserDisplayName({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.style,
    this.showVerified = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileByIdProvider(userId));
    final theme = Theme.of(context);

    return userAsync.when(
      data: (user) {
        final name = user?.displayName ?? fallbackName;
        final isVerified = user?.isVerified ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                style: style ?? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (showVerified && isVerified)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, color: theme.colorScheme.primary, size: (style?.fontSize ?? 14) * 1.1),
              ),
          ],
        );
      },
      loading: () => Text(fallbackName, style: style),
      error: (_, __) => Text(fallbackName, style: style),
    );
  }
}
