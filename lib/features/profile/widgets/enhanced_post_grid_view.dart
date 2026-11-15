import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart' show userPostsProvider;
import 'enhanced_post_detail_view.dart';

class EnhancedPostGridView extends ConsumerStatefulWidget {
  final String userId;
  final ScrollController? scrollController;

  const EnhancedPostGridView({
    super.key,
    required this.userId,
    this.scrollController,
  });

  @override
  ConsumerState<EnhancedPostGridView> createState() =>
      _EnhancedPostGridViewState();
}

class _EnhancedPostGridViewState extends ConsumerState<EnhancedPostGridView>
    with AutomaticKeepAliveClientMixin {
  double _savedScrollOffset = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userPostsAsync = ref.watch(userPostsProvider(widget.userId));
    final theme = Theme.of(context);

    return userPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptyState(theme);
        }

        return _buildPostGrid(posts, theme);
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, error),
    );
  }

  Widget _buildPostGrid(List<PostModel> posts, ThemeData theme) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _savedScrollOffset = notification.metrics.pixels;
        }
        return false;
      },
      child: GridView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostGridItem(post, posts, index, theme);
        },
      ),
    );
  }

  Widget _buildPostGridItem(
    PostModel post,
    List<PostModel> allPosts,
    int index,
    ThemeData theme,
  ) {
    final imageUrl = post.imageUrls?.isNotEmpty == true
        ? post.imageUrls!.first
        : post.image;

    return GestureDetector(
      onTap: () => _openPostDetail(allPosts, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Post Image
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.error,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                )
              else
                // Text-only post placeholder
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
                        post.title.isNotEmpty ? post.title : 'Text',
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

              // Multiple images indicator
              if (post.imageUrls != null && post.imageUrls!.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${post.imageUrls!.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tap indicator
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openPostDetail(allPosts, index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementOverlay(PostModel post, ThemeData theme) {
    final hasEngagement = post.likes.isNotEmpty || post.commentsCount > 0;

    if (!hasEngagement) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Likes
            if (post.likes.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.likes.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            // Comments
            if (post.commentsCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.commentsCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Posts Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts will appear here when they\'re shared',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to create post
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Post'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 9, // Show 9 shimmer items
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildShimmerEffect(theme),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.surfaceContainerHighest,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load posts',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(userPostsProvider(widget.userId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openPostDetail(List<PostModel> posts, int initialIndex) async {
    // Save current scroll position
    if (widget.scrollController != null) {
      _savedScrollOffset = widget.scrollController!.offset;
    }

    // Navigate to post detail with swipe navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EnhancedPostDetailView(posts: posts, initialIndex: initialIndex),
      ),
    );

    // Restore scroll position when returning
    if (widget.scrollController != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController!.hasClients) {
          widget.scrollController!.animateTo(
            _savedScrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
