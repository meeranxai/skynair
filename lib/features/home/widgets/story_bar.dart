import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/config/app_config.dart';
import '../../stories/providers/story_provider.dart';
import '../../stories/pages/story_camera_page.dart';
import '../../stories/pages/story_viewer_page.dart';
import '../../stories/models/story_model.dart';

class StoryBar extends ConsumerWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final user = authState.user;
    final storyState = ref.watch(storyProvider);

    if (!AppConfig.enableStories) return const SizedBox.shrink();

    final stories = storyState.stories;
    final currentUserStory = stories.any((s) => s.userId == user?.uid)
        ? stories.firstWhere((s) => s.userId == user?.uid)
        : null;
    
    final followingStories = stories.where((s) => s.userId != user?.uid).toList();
    
    // Sort following stories: unviewed first, then by createdAt
    followingStories.sort((a, b) {
      final aViewed = user != null && a.isViewedBy(user.uid);
      final bViewed = user != null && b.isViewedBy(user.uid);
      
      if (aViewed != bViewed) {
        return aViewed ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: storyState.isLoading && stories.isEmpty
          ? ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (user != null) _buildYourStoryCard(context, theme, user, currentUserStory, stories),
                ...List.generate(5, (index) => _buildLoadingCard(theme)),
              ],
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Your Story
                if (user != null)
                  _buildYourStoryCard(context, theme, user, currentUserStory, stories),

                // Following stories
                ...followingStories.map((story) {
                  return _buildStoryCard(
                    context,
                    theme,
                    story,
                    stories,
                    ref,
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildYourStoryCard(
    BuildContext context,
    ThemeData theme,
    dynamic user,
    StoryModel? ownStory,
    List<StoryModel> allStories,
  ) {
    final hasActiveStory = ownStory != null;
    final hasViewed = ownStory != null && ownStory.isViewedBy(user.uid);

    return GestureDetector(
      onTap: () {
        if (hasActiveStory) {
          final storyIndex = allStories.indexOf(ownStory);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerPage(
                stories: allStories,
                initialIndex: storyIndex,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StoryCameraPage()),
          );
        }
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStory && !hasViewed
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasActiveStory && hasViewed
                        ? Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: 2,
                          )
                        : (!hasActiveStory
                            ? Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                width: 1,
                              )
                            : null),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? CachedNetworkImageProvider(user.photoURL!)
                        : null,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                ),
                if (!hasActiveStory)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StoryCameraPage()),
                        );
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your Story',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: hasActiveStory ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildStoryCard(
    BuildContext context,
    ThemeData theme,
    StoryModel story,
    List<StoryModel> stories,
    WidgetRef ref,
  ) {
    final currentUser = ref.watch(authProvider).user;
    final hasViewed = currentUser != null && story.isViewedBy(currentUser.uid);

    return GestureDetector(
      onTap: () {
        final storyIndex = stories.indexOf(story);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StoryViewerPage(stories: stories, initialIndex: storyIndex),
          ),
        );
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasViewed
                    ? null
                    : LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: hasViewed
                    ? Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(2.5),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: story.userAvatar != null
                    ? CachedNetworkImageProvider(story.userAvatar!)
                    : null,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: story.userAvatar == null
                    ? Text(
                        story.userName.isNotEmpty
                            ? story.userName[0].toUpperCase()
                                : 'U',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.userName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: !hasViewed ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
