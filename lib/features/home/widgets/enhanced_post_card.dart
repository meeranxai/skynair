import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/post_interaction_service.dart';
import '../../../core/utils/profile_navigation.dart';
import '../../../core/utils/role_based_actions.dart';
import '../../../shared/widgets/author_header.dart';
import '../../../core/widgets/live_user_widgets.dart';

class EnhancedPostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onCommentTap;
  final VoidCallback? onPostTap;

  const EnhancedPostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onCommentTap,
    this.onPostTap,
  });

  @override
  ConsumerState<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends ConsumerState<EnhancedPostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _saveAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _saveScaleAnimation;

  @override
  void initState() {
    super.initState();

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
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
    final currentUserId = widget.currentUserId ?? ref.watch(authProvider).user?.uid;
    final isOwner = currentUserId != null && currentUserId == widget.post.authorId;
    final isLiked = widget.post.isLikedBy(currentUserId ?? '');
    final isSaved = widget.post.isSavedBy(currentUserId ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(context, theme, currentUserId, isOwner),

          // Post Content
          _buildPostContent(context, theme),

          // Post Images
          if (widget.post.image != null ||
              (widget.post.imageUrls?.isNotEmpty == true))
            _buildPostImages(context, theme),

          // Action Buttons & Engagement
          _buildActionSection(
            context,
            theme,
            currentUserId,
            isOwner,
            isLiked,
            isSaved,
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(
    BuildContext context,
    ThemeData theme,
    String? currentUserId,
    bool isOwner,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AuthorHeader(
        authorId: widget.post.authorId,
        fallbackName: widget.post.author,
        fallbackAvatar: widget.post.authorAvatar,
        onTap: () => ProfileNavigation.navigateToProfile(
          context,
          widget.post.authorId,
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => _showPostMenu(context, theme, isOwner),
        ),
      ),
    );
  }


  Widget _buildPostContent(BuildContext context, ThemeData theme) {
    if (widget.post.title.isEmpty && widget.post.description.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: widget.onPostTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.title.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            if (widget.post.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Row(
                  children: [
                    Text(
                      'by ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    LiveUserDisplayName(
                      userId: widget.post.authorId,
                      fallbackName: widget.post.author,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.post.title.isNotEmpty && widget.post.description.isNotEmpty)
              const SizedBox(height: 8),
            if (widget.post.description.isNotEmpty)
              Text(
                widget.post.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImages(BuildContext context, ThemeData theme) {
    final images = widget.post.imageUrls ??
        (widget.post.image != null ? [widget.post.image!] : <String>[]);

    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: widget.onPostTap,
        child: SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.errorContainer,
                  child: const Center(child: Icon(Icons.error_outline)),
                ),
              );
            },
          ),
        ),
      )
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    ThemeData theme,
    String? currentUserId,
    bool isOwner,
    bool isLiked,
    bool isSaved,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionButton(
                context,
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.red : theme.colorScheme.onSurface,
                label: widget.post.likes.length.toString(),
                onTap: () => _toggleLike(isLiked),
                scaleAnimation: _likeScaleAnimation,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                color: theme.colorScheme.onSurface,
                label: widget.post.commentsCount.toString(),
                onTap: widget.onCommentTap ?? () {},
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                context,
                icon: Icons.send_rounded,
                color: theme.colorScheme.onSurface,
                label: widget.post.shareCount.toString(),
                onTap: _sharePost,
              ),
            ],
          ),
          ScaleTransition(
            scale: _saveScaleAnimation,
            child: IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
              onPressed: () => _toggleSave(isSaved),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    Animation<double>? scaleAnimation,
  }) {
    final theme = Theme.of(context);
    
    Widget iconWidget = Icon(icon, color: color, size: 24);
    
    if (scaleAnimation != null) {
      iconWidget = ScaleTransition(scale: scaleAnimation, child: iconWidget);
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            iconWidget,
            if (label != '0') ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return DateFormat('MMM d').format(timestamp);
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
    if (isCurrentlySaved) {
      _saveAnimationController.reverse();
    } else {
      _saveAnimationController.forward();
    }
    ref.read(postsProvider.notifier).savePost(widget.post.id);
  }

  Future<void> _sharePost() async {
    // 1. Native share
    await Share.share(
      '${widget.post.title}\n${widget.post.description}',
      subject: widget.post.title,
    );
    // 2. Real-time update increment
    if (mounted) {
      ref.read(postsProvider.notifier).sharePost(widget.post.id);
    }
  }

  void _showPostMenu(BuildContext context, ThemeData theme, bool isOwner) {
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
                title: Text(action.displayName),
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
      case PostAction.comment:
        widget.onCommentTap?.call();
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
      case PostAction.mute:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mute feature coming soon')),
        );
        break;
      default:
        // Handle other actions or ignore
        break;
    }
  }



  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
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
              // Post is removed from list automatically via provider
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
                    reason
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
}
