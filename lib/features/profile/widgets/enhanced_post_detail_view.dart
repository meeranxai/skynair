import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/post_interaction_provider.dart';
import '../../../core/utils/profile_navigation.dart';
import '../../comments/widgets/realtime_comment_section.dart';

class EnhancedPostDetailView extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final String? currentUserId;

  const EnhancedPostDetailView({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.currentUserId,
  });

  @override
  ConsumerState<EnhancedPostDetailView> createState() =>
      _EnhancedPostDetailViewState();
}

class _EnhancedPostDetailViewState extends ConsumerState<EnhancedPostDetailView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RealtimeCommentSection(
        postId: post.id,
        postAuthorId: post.authorId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          PageView.builder(
            controller: _pageController,
            itemCount: widget.posts.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              return _buildPostDetailPage(post, theme);
            },
          ),

          // Top UI Overlay
          if (_showUI)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTopOverlay(theme),
            ),

          // Bottom UI Overlay
          if (_showUI)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBottomOverlay(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildPostDetailPage(PostModel post, ThemeData theme) {
    final images =
        post.imageUrls ?? (post.image != null ? [post.image!] : <String>[]);

    return GestureDetector(
      onTap: _toggleUI,
      child: Column(
        children: [
          // Image Gallery
          if (images.isNotEmpty)
            Expanded(flex: 3, child: _buildImageGallery(images, theme))
          else
            Expanded(
              flex: 3,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No image available',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Post Content
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surface,
              child: _buildPostContent(post, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, ThemeData theme) {
    if (images.length == 1) {
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(images.first),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: images.first),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Container(
          color: theme.colorScheme.errorContainer,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PhotoViewGallery.builder(
      itemCount: images.length,
      builder: (context, index) => PhotoViewGalleryPageOptions(
        imageProvider: CachedNetworkImageProvider(images[index]),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      pageController: PageController(),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
          value: event == null
              ? null
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
        ),
      ),
    );
  }

  Widget _buildPostContent(PostModel post, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          _buildAuthorInfo(post, theme),

          const SizedBox(height: 16),

          // Post Title and Description
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (post.description.isNotEmpty) ...[
            Text(
              post.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Engagement Stats
          _buildEngagementStats(post, theme),

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(post, theme),

          const SizedBox(height: 24),

          // Comments Section
          _buildCommentsSection(post, theme),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(PostModel post, ThemeData theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () =>
              ProfileNavigation.navigateToProfile(context, post.authorId),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: post.authorAvatar != null
                ? CachedNetworkImageProvider(post.authorAvatar!)
                : null,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: post.authorAvatar == null
                ? Text(
                    post.author.isNotEmpty ? post.author[0].toUpperCase() : 'U',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    ProfileNavigation.navigateToProfile(context, post.authorId),
                child: Text(
                  post.author,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (post.authorUsername != null)
                GestureDetector(
                  onTap: () => ProfileNavigation.navigateToProfile(
                    context,
                    post.authorId,
                  ),
                  child: Text(
                    '@${post.authorUsername}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Follow Button (if not owner)
        if (widget.currentUserId != post.authorId)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Follow',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEngagementStats(PostModel post, ThemeData theme) {
    return Row(
      children: [
        if (post.likes.isNotEmpty) ...[
          Icon(Icons.favorite, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            '${post.likes.length} likes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        if (post.commentsCount > 0) ...[
          if (post.likes.isNotEmpty) const SizedBox(width: 16),
          Icon(
            Icons.chat_bubble_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.commentsCount} comments',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        if (post.shareCount > 0) ...[
          if (post.likes.isNotEmpty || post.commentsCount > 0)
            const SizedBox(width: 16),
          Icon(
            Icons.share_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.shareCount} shares',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(PostModel post, ThemeData theme) {
    final isLiked = post.isLikedBy(widget.currentUserId ?? '');
    final isSaved = post.isSavedBy(widget.currentUserId ?? '');

    return Row(
      children: [
        // Like Button
        GestureDetector(
          onTap: () =>
              ref.read(postInteractionProvider.notifier).toggleLike(post.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isLiked
                  ? Colors.red.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Colors.red
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Like',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLiked
                        ? Colors.red
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Comment Button
        GestureDetector(
          onTap: () => _showComments(post),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Share Button
        GestureDetector(
          onTap: () =>
              ref.read(postInteractionProvider.notifier).sharePost(post.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Share',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Save Button
        GestureDetector(
          onTap: () =>
              ref.read(postInteractionProvider.notifier).toggleSave(post.id),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSaved
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(PostModel post, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        // Comment Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  widget.currentUserId?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: InputBorder.none,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              IconButton(
                onPressed: () {
                  // TODO: Post comment
                },
                icon: Icon(
                  Icons.send,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Comments List (Placeholder)
        if (post.commentsCount == 0)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No comments yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to comment!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          )
        else
          // TODO: Implement actual comments list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Comments feature coming soon!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopOverlay(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),

                const Spacer(),

                // Post Counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.posts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // More Options
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Show post options
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Navigation Dots
                if (widget.posts.length > 1)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.posts.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });

    if (_showUI) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }
}
