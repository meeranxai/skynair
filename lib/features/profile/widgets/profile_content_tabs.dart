import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import '../../../core/models/user_model.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart' show userPostsProvider;
import '../../../core/providers/saved_posts_provider.dart';
import '../widgets/saved_posts_grid.dart';
import '../../posts/pages/post_detail_page.dart';

import '../../../core/widgets/keep_alive_wrapper.dart';

class ProfileContentTabs extends ConsumerWidget {
  final TabController tabController;
  final UserModel user;
  final bool isOwnProfile;

  const ProfileContentTabs({
    super.key,
    required this.tabController,
    required this.user,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return TabBarView(
      controller: tabController,
      children: [
        // Posts Tab (All)
        KeepAliveWrapper(
          child: _PostsTabWithTimeout(
            user: user,
            isOwnProfile: isOwnProfile,
            filterType: 'all',
          ),
        ),

        // Media Tab (Only images/videos)
        KeepAliveWrapper(
          child: _PostsTabWithTimeout(
            user: user,
            isOwnProfile: isOwnProfile,
            filterType: 'media',
          ),
        ),

        // Saved/Tagged Tab
        KeepAliveWrapper(
          child: isOwnProfile
              ? _buildSavedTab(theme, ref, context)
              : _buildTaggedTab(theme),
        ),
      ],
    );
  }

  Widget _buildSavedTab(ThemeData theme, WidgetRef ref, BuildContext context) {
    final savedPostsAsync = ref.watch(userSavedPostsProvider(user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userSavedPostsProvider(user.uid));
      },
      color: theme.colorScheme.primary,
      child: savedPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyState(
              theme,
              Icons.bookmark_border,
              'No saved posts yet',
              'Posts you save will appear here. Start exploring and save posts you want to see later!',
              'Explore Posts',
              () => _navigateToExplore(context),
            );
          }
          return _buildSavedPostsGrid(posts, theme, context);
        },
        loading: () =>
            _buildLoadingStateWithTimeout(theme, 'Loading saved posts...'),
        error: (error, stack) => _buildErrorStateWithRetry(
          theme,
          Icons.bookmark_border,
          'Error loading saved posts',
          error.toString(),
          () => ref.invalidate(userSavedPostsProvider(user.uid)),
        ),
      ),
    );
  }

  Widget _buildTaggedTab(ThemeData theme) {
    return _buildEmptyState(
      theme,
      Icons.local_offer_outlined,
      'No tagged posts',
      'Posts where this user is tagged will appear here.',
      null,
      null,
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(icon, size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: Icon(icon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStateWithTimeout(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateWithRetry(
    ThemeData theme,
    IconData icon,
    String title,
    String error,
    VoidCallback? onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostsGrid(
    List<dynamic> savedPosts,
    ThemeData theme,
    BuildContext context,
  ) {
    return SavedPostsGrid(
      posts: savedPosts.cast<PostModel>(),
      onPostTap: (post) {
        final List<PostModel> posts = savedPosts.cast<PostModel>();
        final index = posts.indexOf(post);
        _navigateToPostDetail(context, posts, index);
      },
    );
  }

  void _navigateToExplore(BuildContext context) {
    context.go('/explore');
  }

  void _navigateToPostDetail(
    BuildContext context,
    List<PostModel> posts,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          postId: posts[index].id,
          allPosts: posts,
          initialIndex: index,
        ),
      ),
    );
  }
}

// Separate widget for posts tab with timeout handling
class _PostsTabWithTimeout extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isOwnProfile;
  final String filterType; // 'all' or 'media'

  const _PostsTabWithTimeout({
    required this.user,
    required this.isOwnProfile,
    required this.filterType,
  });

  @override
  ConsumerState<_PostsTabWithTimeout> createState() =>
      _PostsTabWithTimeoutState();
}

class _PostsTabWithTimeoutState extends ConsumerState<_PostsTabWithTimeout> {
  Timer? _timeoutTimer;
  bool _showTimeoutMessage = false;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    setState(() {
      _showTimeoutMessage = false;
    });

    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showTimeoutMessage = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userPostsAsync = ref.watch(userPostsProvider(widget.user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        _startTimeoutTimer();
        ref.invalidate(userPostsProvider(widget.user.uid));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: theme.colorScheme.primary,
      child: userPostsAsync.when(
        data: (posts) {
          print(
            '🎯 UI received ${posts.length} posts for user ${widget.user.uid}',
          );
          _timeoutTimer?.cancel(); // Cancel timer when data loads

          // Filter out articles and drafts for others, and ensure no duplicates
          final seenIds = <String>{};
          final visiblePosts = posts.where((p) {
            if (seenIds.contains(p.id)) return false;
            seenIds.add(p.id);

            final isVisible = widget.isOwnProfile || p.isDraft != true;
            
            if (widget.filterType == 'media') {
              // Media tab only shows posts with images/videos
              final hasMedia = (p.image != null && p.image!.isNotEmpty) || (p.imageUrls != null && p.imageUrls!.isNotEmpty);
              return isVisible && hasMedia && p.postType == 'media';
            } else {
              // Posts tab shows everything (equally treated)
              return isVisible;
            }
          }).toList();

          print('🎯 After filtering: ${visiblePosts.length} visible posts');

          // Stable sort by createdAt (Newest first)
          visiblePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (visiblePosts.isEmpty) {
            return _buildEmptyState(
              theme,
              Icons.post_add_outlined,
              'No posts yet',
              widget.isOwnProfile
                  ? 'Share your first post with the community!'
                  : 'This user hasn\'t posted anything yet.',
              widget.isOwnProfile ? 'Create Post' : null,
              widget.isOwnProfile ? () => _navigateToCreatePost(context) : null,
            );
          }

          // Grid layout for posts - Instagram style
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.zero,
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = visiblePosts[index];

                    // Determine image URL
                    final String? imageUrl =
                        (post.imageUrls?.isNotEmpty ?? false)
                        ? post.imageUrls!.first
                        : post.image;

                    final bool isMultiImage = (post.imageUrls?.length ?? 0) > 1;

                    return GestureDetector(
                      onTap: () =>
                          _navigateToPostDetail(context, visiblePosts, index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Content for text-only posts
                            if (imageUrl == null || imageUrl.isEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      theme.colorScheme.secondary.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.format_quote_rounded,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post.title.isNotEmpty
                                            ? post.title
                                            : post.description,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Multi-image indicator
                            if (isMultiImage)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.copy_outlined,
                                  color: Colors.white,
                                  size: 16,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: visiblePosts.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
        loading: () {
          print('🔄 UI showing loading state for user ${widget.user.uid}');
          if (_showTimeoutMessage) {
            return _buildTimeoutState(theme);
          }
          return _buildLoadingState(theme);
        },
        error: (error, stack) {
          print('❌ UI showing error state: $error');
          return _buildErrorState(theme, error.toString());
        },
      ),
    );
  }

  Widget _buildTimeoutState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading taking longer than expected',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This might be due to network issues or the user having many posts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _startTimeoutTimer();
                ref.invalidate(userPostsProvider(widget.user.uid));
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading posts...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _startTimeoutTimer();
                ref.invalidate(userPostsProvider(widget.user.uid));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(icon, size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: Icon(icon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    context.go('/create');
  }

  void _navigateToPostDetail(
    BuildContext context,
    List<PostModel> posts,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          postId: posts[index].id,
          allPosts: posts,
          initialIndex: index,
        ),
      ),
    );
  }
}
