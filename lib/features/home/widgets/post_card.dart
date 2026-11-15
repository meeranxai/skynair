import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String? currentUserId;

  const PostCard({super.key, required this.post, this.currentUserId});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _saveAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _saveScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Like animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Save animation
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _saveScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _saveAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked =
        widget.currentUserId != null &&
        widget.post.isLikedBy(widget.currentUserId!);
    final isSaved =
        widget.currentUserId != null &&
        widget.post.isSavedBy(widget.currentUserId!);
    final isOwner = widget.currentUserId == widget.post.authorId;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional Header
            _buildPostHeader(context, theme, isOwner),

            // Content Section
            _buildPostContent(context, theme),

            // Image Section
            if (widget.post.image != null) _buildPostImage(context, theme),

            // Engagement Stats (subtle)
            if (widget.post.likes.isNotEmpty || widget.post.commentsCount > 0)
              _buildEngagementStats(context, theme),

            // Action Bar
            _buildActionBar(context, theme, isLiked, isSaved),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, ThemeData theme, bool isOwner) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
      child: Row(
        children: [
          // Professional Avatar with Status Ring
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.secondary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(1.5),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: widget.post.authorAvatar != null
                      ? CachedNetworkImageProvider(widget.post.authorAvatar!)
                      : null,
                  child: widget.post.authorAvatar == null
                      ? Text(
                          widget.post.author.isNotEmpty
                              ? widget.post.author[0].toUpperCase()
                              : 'U',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              // Online status indicator (optional)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Author Info with Professional Typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.post.author,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                    if (widget.post.category != 'General') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.post.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(widget.post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (widget.post.visibility != 'public') ...[
                      const SizedBox(width: 8),
                      Icon(
                        widget.post.visibility == 'private'
                            ? Icons.lock_outline
                            : Icons.group_outlined,
                        size: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Professional More Options
          _buildMoreOptionsButton(context, theme, isOwner),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsButton(
    BuildContext context,
    ThemeData theme,
    bool isOwner,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPostOptions(context, isOwner),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Professional Typography
          if (widget.post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
            ),

          // Description with Better Readability
          if (widget.post.description.isNotEmpty)
            Text(
              widget.post.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostImage(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.post.image!,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(theme),
          errorWidget: (context, url, error) => _buildImageError(theme),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading image...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      height: 200,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementStats(BuildContext context, ThemeData theme) {
    final hasLikes = widget.post.likes.isNotEmpty;
    final hasComments = widget.post.commentsCount > 0;

    if (!hasLikes && !hasComments) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (hasLikes) ...[
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.post.likes.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (hasLikes && hasComments) ...[
            const SizedBox(width: 16),
            Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (hasComments) ...[
            Text(
              '${widget.post.commentsCount} ${widget.post.commentsCount == 1 ? 'comment' : 'comments'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    ThemeData theme,
    bool isLiked,
    bool isSaved,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // Like Button with Professional Animation
          ScaleTransition(
            scale: _likeScaleAnimation,
            child: _buildActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: isLiked ? theme.colorScheme.primary : null,
              onTap: _handleLike,
              theme: theme,
            ),
          ),

          // Comment Button
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            onTap: () => _showComments(context),
            theme: theme,
          ),

          // Share Button
          _buildActionButton(
            icon: Icons.share_outlined,
            onTap: () => _sharePost(context),
            theme: theme,
          ),

          const Spacer(),

          // Save Button with Animation
          ScaleTransition(
            scale: _saveScaleAnimation,
            child: _buildActionButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              iconColor: isSaved ? theme.colorScheme.primary : null,
              onTap: _handleSave,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color:
                iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  void _handleLike() {
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    final currentUserId =
        widget.currentUserId ?? ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;

    ref.read(postsProvider.notifier).likePost(widget.post.id);
    HapticFeedback.lightImpact();
  }

  void _handleSave() {
    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });

    final currentUserId =
        widget.currentUserId ?? ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;

    ref.read(postsProvider.notifier).savePost(widget.post.id);
    HapticFeedback.lightImpact();
  }

  void _showComments(BuildContext context) {
    context.push('/posts/${widget.post.id}/comments');
  }

  Future<void> _sharePost(BuildContext context) async {
    final currentUserId =
        widget.currentUserId ?? ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out this post: ${widget.post.title}\n${widget.post.description}',
      ),
    );

    ref.read(postsProvider.notifier).sharePost(widget.post.id);
  }

  void _showPostOptions(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPostOptionsSheet(context, isOwner),
    );
  }

  Widget _buildPostOptionsSheet(BuildContext context, bool isOwner) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Post Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Options based on ownership
            if (isOwner) ...[
              _buildOptionTile(
                context,
                icon: Icons.edit_outlined,
                title: 'Edit Post',
                subtitle: 'Modify your post content',
                onTap: () {
                  Navigator.pop(context);
                  // Pass post type when editing
                  final postType = widget.post.postType;
                  context.push('/create?type=$postType', extra: widget.post);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.visibility_outlined,
                title: 'Change Visibility',
                subtitle: 'Who can see this post',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show visibility options
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.delete_outline,
                title: 'Delete Post',
                subtitle: 'Remove this post permanently',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ] else ...[
              _buildOptionTile(
                context,
                icon: Icons.bookmark_outline,
                title: 'Save Post',
                subtitle: 'Add to your saved posts',
                onTap: () {
                  Navigator.pop(context);
                  _handleSave();
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.person_remove_outlined,
                title: 'Unfollow ${widget.post.author}',
                subtitle: 'Stop seeing posts from this user',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement unfollow
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.visibility_off_outlined,
                title: 'Hide Post',
                subtitle: 'See fewer posts like this',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement hide post
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.report_outlined,
                title: 'Report Post',
                subtitle: 'Report inappropriate content',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showReportOptions(context);
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? theme.colorScheme.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete post
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportOptions(BuildContext context) {
    final theme = Theme.of(context);
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'False information',
      'Violence',
      'Intellectual property violation',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report Post',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Why are you reporting this post?',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Divider(height: 32),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reasons.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(reasons[index]),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _submitReport(context, widget.post.id, reasons[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, String postId, String reason) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await FirestoreService.submitReport(
        reporterId: currentUser.uid,
        targetId: postId,
        targetType: 'post',
        reason: reason,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Thank you! Your report has been submitted for review.'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit report. Please try again.')),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
