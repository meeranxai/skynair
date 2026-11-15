import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
// PHASE 1: Share disabled (Enable in Phase 2)
// import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/utils/profile_navigation.dart';
import '../../../core/widgets/parsed_text.dart';

import '../../../core/widgets/live_user_widgets.dart';

/// Skynaire feed card that maintains Skynaire's functionality
/// with modern visual patterns and interactions
class SkynaireFeedCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String? currentUserId;

  const SkynaireFeedCard({super.key, required this.post, this.currentUserId});

  @override
  ConsumerState<SkynaireFeedCard> createState() => _SkynaireFeedCardState();
}

class _SkynaireFeedCardState extends ConsumerState<SkynaireFeedCard>
    with TickerProviderStateMixin {
  bool _isLikeAnimating = false;
  bool _isExpanded = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId =
        widget.currentUserId ?? ref.watch(authProvider).user?.uid;
    final isLiked = widget.post.isLikedBy(currentUserId ?? '');

    final hasImage =
        (widget.post.image != null && widget.post.image!.isNotEmpty) ||
        (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty);

    // Article check removed to render all posts uniformly

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Author info) - Instagram style
          _buildHeader(context, theme),

          // Image/Content - Instagram style with double-tap
          _buildContent(context, theme),

          // Actions (Like, Comment, Share)
          _buildActions(context, theme, currentUserId, isLiked),

          // Likes count - Instagram style
          _buildLikesCount(theme),

          // Caption - Instagram style
          _buildCaption(context, theme),

          // Comments preview - Instagram style
          _buildCommentsPreview(context, theme),

          // Timestamp - Instagram style
          _buildTimestamp(theme),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          LiveUserAvatar(
            userId: widget.post.authorId,
            radius: 16,
            fallbackUrl: widget.post.authorAvatar,
            fallbackName: widget.post.author,
          ),

          const SizedBox(width: 12),

          // Author info - Real-time from provider
          Expanded(child: _buildAuthorInfo(context, theme)),

          // More options
          IconButton(
            onPressed: () => _showPostOptions(context),
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the author's profile for real-time updates
        final authorAsync = ref.watch(
          userProfileByIdProvider(widget.post.authorId),
        );

        return authorAsync.when(
          data: (author) {
            if (author == null) {
              // Fallback to post data if author not found
              return _buildAuthorInfoContent(
                theme,
                context,
                widget.post.author,
                widget.post.authorUsername,
              );
            }
            // Use real-time author data
            return _buildAuthorInfoContent(
              theme,
              context,
              author.displayName,
              author.username,
            );
          },
          loading: () => _buildAuthorInfoContent(
            theme,
            context,
            widget.post.author,
            widget.post.authorUsername,
          ),
          error: (error, stackTrace) => _buildAuthorInfoContent(
            theme,
            context,
            widget.post.author,
            widget.post.authorUsername,
          ),
        );
      },
    );
  }

  Widget _buildAuthorInfoContent(
    ThemeData theme,
    BuildContext context,
    String authorName,
    String? authorUsername,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => ProfileNavigation.navigateToProfile(
            context,
            widget.post.authorId,
          ),
          child: Text(
            authorName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (authorUsername != null)
          Text(
            '@$authorUsername',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTapLike(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (if image exists)
              if (widget.post.image != null)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 500,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Content placeholder if no image
              if (widget.post.image == null)
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Icon(
                      Icons.article_outlined,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
            ],
          ),

          // Like animation overlay
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _likeAnimation.value,
                child: Opacity(
                  opacity: _isLikeAnimating
                      ? (1.0 - _likeAnimation.value)
                      : 0.0,
                  child: Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ThemeData theme,
    String? currentUserId,
    bool isLiked,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: () => _handleLike(currentUserId),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isLiked),
                color: isLiked ? Colors.red : theme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Comment button
          GestureDetector(
            onTap: () => context.push('/posts/${widget.post.id}/comments'),
            child: Icon(
              Icons.chat_bubble_outline,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Share button
          GestureDetector(
            onTap: () => _handleShare(context),
            child: Icon(
              Icons.send_outlined,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          const Spacer(),

          // Save button
          GestureDetector(
            onTap: () => _handleSave(currentUserId),
            child: Icon(
              widget.post.isSavedBy(currentUserId ?? '')
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount(ThemeData theme) {
    if (widget.post.likes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '${widget.post.likes.length} ${widget.post.likes.length == 1 ? 'like' : 'likes'}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context, ThemeData theme) {
    if (widget.post.title.isEmpty && widget.post.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author name and Title
          Consumer(
            builder: (context, ref, child) {
              final authorAsync = ref.watch(userProfileByIdProvider(widget.post.authorId));
              final authorName = authorAsync.maybeWhen(
                data: (author) => author?.displayName ?? widget.post.author,
                orElse: () => widget.post.author,
              );
              
              return RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: authorName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => ProfileNavigation.navigateToProfile(
                          context,
                          widget.post.authorId,
                        ),
                    ),
                    if (widget.post.title.isNotEmpty) ...[
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: widget.post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          if (widget.post.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            ParsedDescription(
              text: widget.post.description,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            if (widget.post.description.length > 60)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsPreview(BuildContext context, ThemeData theme) {
    if (widget.post.commentsCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: GestureDetector(
        onTap: () => context.push('/posts/${widget.post.id}/comments'),
        child: Text(
          'View all ${widget.post.commentsCount} comments',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Text(
        _formatTimestamp(widget.post.createdAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
    );
  }

  void _handleDoubleTapLike() {
    final currentUserId =
        widget.currentUserId ?? ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;

    // Only animate if not already liked
    if (!widget.post.isLikedBy(currentUserId)) {
      setState(() {
        _isLikeAnimating = true;
      });
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reset();
        setState(() {
          _isLikeAnimating = false;
        });
      });
    }

    _handleLike(currentUserId);
  }

  void _handleLike(String? currentUserId) {
    if (currentUserId == null) return;
    ref.read(postsProvider.notifier).likePost(widget.post.id);
  }

  void _handleSave(String? currentUserId) {
    if (currentUserId == null) return;
    ref.read(postsProvider.notifier).savePost(widget.post.id);
  }

  void _handleShare(BuildContext context) async {
    final post = widget.post;
    await Share.share(
      '${post.title}\n${post.description}',
      subject: post.title,
    );

    if (mounted) {
      ref.read(postsProvider.notifier).sharePost(post.id);
    }
  }

  void _showPostOptions(BuildContext context) {
    _showOwnerOptions(context);
  }

  void _showOwnerOptions(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId =
        widget.currentUserId ?? ref.read(authProvider).user?.uid;
    final isOwner = currentUserId == widget.post.authorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
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
                if (isOwner) ...[
                  ListTile(
                    leading: Icon(
                      widget.post.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    title: Text(widget.post.isArchived ? 'Unarchive' : 'Archive'),
                    onTap: () {
                      Navigator.pop(context);
                      // Archive/Unarchive toggle
                      ref
                          .read(postsProvider.notifier)
                          .archivePost(widget.post.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.post.isArchived
                                ? 'Post unarchived'
                                : 'Post archived',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: theme.colorScheme.onSurface,
                    ),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      // Pass post type when editing
                      final postType = widget.post.postType;
                      context.push(
                        '/create?type=$postType',
                        extra: widget.post,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.share_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    title: const Text('Share'),
                    // PHASE 2: Share functionality
                    onTap: () {
                      Navigator.pop(context);
                      _handleShare(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.delete, color: theme.colorScheme.error),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(postsProvider.notifier)
                          .deletePost(widget.post.id);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(
                      Icons.report_gmailerrorred_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context, widget.post);
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, PostModel post) {
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Why are you reporting this post?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                    _submitReport(context, post.id, reasons[index]);
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
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Thank you! Your report has been submitted for review.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again.'),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
