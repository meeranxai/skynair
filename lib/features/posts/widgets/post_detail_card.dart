import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/post_interaction_provider.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/profile_navigation.dart';
import '../../../core/utils/role_based_actions.dart';
import '../../../core/services/post_interaction_service.dart';
import '../../home/widgets/post_actions.dart';

class PostDetailCard extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onCommentTap;

  const PostDetailCard({super.key, required this.post, this.onCommentTap});

  @override
  ConsumerState<PostDetailCard> createState() => _PostDetailCardState();
}

class _PostDetailCardState extends ConsumerState<PostDetailCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _doubleTapAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _doubleTapScaleAnimation;
  late Animation<double> _doubleTapOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _doubleTapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _doubleTapScaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _doubleTapAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _doubleTapOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _doubleTapAnimationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _doubleTapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.uid;
    final isLiked = widget.post.isLikedBy(currentUserId ?? '');
    final isSaved = widget.post.isSavedBy(currentUserId ?? '');

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Background Image/Content
          _buildPostMedia(context),

          // Double-Tap Like Animation Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _doubleTapAnimationController,
              builder: (context, child) => _doubleTapOpacityAnimation.value > 0
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Transform.scale(
                          scale: _doubleTapScaleAnimation.value,
                          child: Opacity(
                            opacity: _doubleTapOpacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Content Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Author Info and Follow Button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ProfileNavigation.navigateToProfile(
                          context,
                          widget.post.authorId,
                        ),
                        child: ClipOval(
                          child: Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[800],
                            child: widget.post.authorAvatar != null && widget.post.authorAvatar!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.post.authorAvatar!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        widget.post.author.isNotEmpty
                                            ? widget.post.author[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      widget.post.author.isNotEmpty
                                          ? widget.post.author[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      ProfileNavigation.navigateToProfile(
                                        context,
                                        widget.post.authorId,
                                      ),
                                  child: Text(
                                    widget.post.author,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Follow button removed - should only be on profile pages
                              ],
                            ),
                            if (widget.post.authorUsername != null)
                              Text(
                                '@${widget.post.authorUsername}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 16),

                  // Post Content
                  if (widget.post.title.isNotEmpty) ...[
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (widget.post.description.isNotEmpty) ...[
                    Text(
                      widget.post.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Timestamp and Category
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      // Like Button
                      AnimatedBuilder(
                        animation: _likeScaleAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _likeScaleAnimation.value,
                          child: GestureDetector(
                            onTap: () => _toggleLike(isLiked),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.white,
                                  size: 28,
                                ),
                                if (widget.post.likes.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCount(widget.post.likes.length),
                                    style: TextStyle(
                                      color: isLiked
                                          ? Colors.red
                                          : Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Comment Button
                      GestureDetector(
                        onTap: widget.onCommentTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            if (widget.post.commentsCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                _formatCount(widget.post.commentsCount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Share Button
                      GestureDetector(
                        onTap: _sharePost,
                        child: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const Spacer(),

                      // Save Button
                      GestureDetector(
                        onTap: () => _toggleSave(isSaved),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.amber : Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Top Options Menu
          Positioned(
            top: 48,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showPostMenu(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context) {
    final images =
        widget.post.imageUrls ??
        (widget.post.image != null ? [widget.post.image!] : <String>[]);

    if (images.isEmpty) {
      // Text-only post with gradient background
      return GestureDetector(
        onDoubleTap: () => _handleDoubleTapLike(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900,
                Colors.blue.shade900,
                Colors.teal.shade900,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.post.title.isNotEmpty) ...[
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (widget.post.description.isNotEmpty)
                    Text(
                      widget.post.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Image post
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTapLike(),
      child: images.length == 1
          ? _buildSingleImage(images.first)
          : _buildMultipleImages(images),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages(List<String> images) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) => _buildSingleImage(images[index]),
    );
  }

  void _handleDoubleTapLike() {
    final currentUserId = ref.read(authProvider).user?.uid;
    final isLiked = widget.post.isLikedBy(currentUserId ?? '');

    if (!isLiked) {
      _toggleLike(false);
    }

    // Always show animation for double-tap
    _doubleTapAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _doubleTapAnimationController.reverse();
        }
      });
    });
  }

  void _toggleLike(bool isCurrentlyLiked) {
    if (isCurrentlyLiked) {
      _likeAnimationController.reverse();
    } else {
      _likeAnimationController.forward();
    }

    ref.read(postsProvider.notifier).likePost(widget.post.id);
  }

  void _toggleSave(bool isCurrentlySaved) {
    ref.read(postsProvider.notifier).savePost(widget.post.id);
  }

  void _sharePost() async {
    final post = widget.post;
    await Share.share(
      '${post.title}\n${post.description}',
      subject: post.title,
    );

    if (mounted) {
      ref.read(postInteractionProvider.notifier).sharePost(post.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.share, color: Colors.black),
              SizedBox(width: 12),
              Text(
                'Post shared successfully!',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showPostMenu(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(authProvider).user?.uid;
    final actions = RoleBasedActions.getPostActions(
      post: widget.post,
      currentUserId: currentUserId,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...actions.map(
              (action) => ListTile(
                leading: Icon(action.icon, color: action.getColor(context)),
                title: Text(action == PostAction.archive && widget.post.isArchived ? 'Unarchive Post' : action.displayName),
                onTap: () {
                  Navigator.pop(context);
                  _handlePostAction(action);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handlePostAction(PostAction action) {
    final currentUserId = ref.read(authProvider).user?.uid;

    switch (action) {
      case PostAction.edit:
        final postType = widget.post.postType;
        context.push('/create?type=$postType', extra: widget.post);
        break;
      case PostAction.delete:
        _confirmDelete(context);
        break;
      case PostAction.share:
        _sharePost();
        break;
      case PostAction.save:
        _toggleSave(widget.post.isSavedBy(currentUserId ?? ''));
        break;
      case PostAction.like:
        _toggleLike(widget.post.isLikedBy(currentUserId ?? ''));
        break;
      case PostAction.report:
        _showReportDialog(context);
        break;
      case PostAction.block:
        if (currentUserId != null) {
          PostInteractionService.blockUser(currentUserId, widget.post.authorId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User blocked')),
          );
        }
        break;
      case PostAction.archive:
        ref.read(postsProvider.notifier).archivePost(widget.post.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.post.isArchived ? 'Post unarchived' : 'Post archived')),
        );
        break;
      default:
        break;
    }
  }



  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(postsProvider.notifier).deletePost(widget.post.id);
              if (mounted) Navigator.pop(context); // Close detail view
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String reason = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Reason for reporting...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (val) => reason = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (reason.trim().isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context);

              final currentUserId = ref.read(authProvider).user?.uid;
              if (currentUserId != null) {
                try {
                  await PostInteractionService.reportPost(
                    widget.post.id,
                    currentUserId,
                    reason,
                  );
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Report submitted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to report: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = count / 1000000;
    return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
  }
}
