import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/post_model.dart';

class SavedPostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final Function(PostModel) onPostTap;

  const SavedPostsGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Header with count
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${posts.length} saved ${posts.length == 1 ? 'post' : 'posts'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grid of saved posts - Instagram style
        SliverPadding(
          padding: EdgeInsets.zero,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = posts[index];
              return _buildPostGridItem(context, post, theme);
            }, childCount: posts.length),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPostGridItem(
    BuildContext context,
    PostModel post,
    ThemeData theme,
  ) {
    // Determine image URL (prioritize first image from list, then single image)
    final String? imageUrl = (post.imageUrls?.isNotEmpty ?? false)
        ? post.imageUrls!.first
        : post.image;

    final bool isMultiImage = (post.imageUrls?.length ?? 0) > 1;

    return GestureDetector(
      onTap: () => onPostTap(post),
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post image or placeholder
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                    size: 24,
                  ),
                ),
              )
            else
              Container(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title.isNotEmpty ? post.title : 'Text Post',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Multi-image indicator (copy icon)
            if (isMultiImage)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.copy_outlined, // Looks like multiple squares/pages
                  color: Colors.white,
                  size: 16,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
