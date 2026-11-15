import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/story_model.dart';
import '../providers/story_provider.dart';
import '../pages/story_camera_page.dart';
import '../pages/story_viewer_page.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class StoryBar extends ConsumerWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyState = ref.watch(storyProvider);
    final currentUser = ref.watch(authProvider).user;

    return Container(
      height: 115, // Increased height for better spacing
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: storyState.isLoading && storyState.stories.isEmpty
          ? _buildLoadingState(context)
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  storyState.stories.length + 1, // +1 for "Add Story" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryButton(context, currentUser);
                }

                final story = storyState.stories[index - 1];
                final isOwnStory = story.userId == currentUser?.uid;

                return _buildStoryItem(
                  context,
                  ref,
                  story,
                  isOwnStory,
                  storyState.stories,
                  index - 1,
                );
              },
            ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context, dynamic currentUser) {
    final theme = Theme.of(context);

    return _ScaleButton(
      onTap: () => _openStoryCamera(context),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: currentUser?.photoURL != null
                          ? CachedNetworkImage(
                              imageUrl: currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.person),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your Story',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(
    BuildContext context,
    WidgetRef ref,
    StoryModel story,
    bool isOwnStory,
    List<StoryModel> allStories,
    int index,
  ) {
    final currentUser = ref.read(authProvider).user;
    final isViewed = story.isViewedBy(currentUser?.uid ?? '');
    final theme = Theme.of(context);

    return _ScaleButton(
      onTap: () => _openStoryViewer(context, allStories, index),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 76, // Slightly larger
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? null
                    : LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                border: isViewed
                    ? Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3), // Thicker ring gap
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface, // Gap color
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: story.userAvatar != null
                          ? CachedNetworkImage(
                              imageUrl: story.userAvatar!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 74,
              child: Text(
                isOwnStory ? 'You' : story.userName.split(' ').first,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
                  color: isViewed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryCameraPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openStoryViewer(
    BuildContext context,
    List<StoryModel> stories,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StoryViewerPage(stories: stories, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
