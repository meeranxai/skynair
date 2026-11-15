import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';

/// Skynaire explore grid with modern staggered layout
class SkynaireExploreGrid extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const SkynaireExploreGrid({
    super.key,
    required this.posts,
    this.isLoading = false,
    this.error,
  });

  @override
  ConsumerState<SkynaireExploreGrid> createState() =>
      _SkynaireExploreGridState();
}

class _SkynaireExploreGridState extends ConsumerState<SkynaireExploreGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading && widget.posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null && widget.posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading posts',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(postsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No posts to explore',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new content',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          return _buildGridItem(context, theme, post, index);
        },
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    ThemeData theme,
    PostModel post,
    int index,
  ) {
    // Create Instagram-style staggered pattern
    final patterns = [
      const StaggeredGridTile.count(
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
        child: SizedBox(),
      ),
      const StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 2,
        child: SizedBox(),
      ),
      const StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 1,
        child: SizedBox(),
      ),
      const StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 1,
        child: SizedBox(),
      ),
      const StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 1,
        child: SizedBox(),
      ),
    ];

    final patternIndex = index % patterns.length;
    final isLarge = patternIndex == 0; // First item in pattern is large

    return GestureDetector(
      onTap: () => _handlePostTap(context, post),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post content
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildPostContent(context, theme, post, isLarge),
            ),

            // Overlay with post info (for large items)
            if (isLarge) _buildOverlay(context, theme, post),

            // Interaction indicators
            _buildInteractionIndicators(theme, post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent(
    BuildContext context,
    ThemeData theme,
    PostModel post,
    bool isLarge,
  ) {
    if (post.image != null) {
      return CachedNetworkImage(
        imageUrl: post.image!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: theme.colorScheme.onSurfaceVariant,
                size: isLarge ? 32 : 24,
              ),
              if (isLarge) ...[
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // Text-only post
      return Container(
        padding: EdgeInsets.all(isLarge ? 16 : 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (post.title.isNotEmpty && isLarge) ...[
              Text(
                post.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              post.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: isLarge ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOverlay(BuildContext context, ThemeData theme, PostModel post) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipOval(
                    child: post.authorAvatar != null
                        ? CachedNetworkImage(
                            imageUrl: post.authorAvatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey,
                              child: const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              child: const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                post.author.isNotEmpty
                                    ? post.author[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.author,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Post title/description
            if (post.title.isNotEmpty)
              Text(
                post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionIndicators(ThemeData theme, PostModel post) {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        children: [
          // Likes indicator
          if (post.likes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    post.likes.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Comments indicator
          if (post.commentsCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    post.commentsCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePostTap(BuildContext context, PostModel post) {
    // Navigate to post detail or comments
    context.push('/posts/${post.id}/comments');
  }
}
