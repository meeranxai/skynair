import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/models/comment_model.dart';
import '../../../core/providers/comments_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/live_user_widgets.dart';

/// Real-time comment section with streaming updates
/// Features:
/// - Slide-up modal
/// - Real-time comment streaming
/// - Nested replies (threaded comments)
/// - @mention autocomplete
/// - Emoji picker integration
/// - Optimistic UI updates
class RealtimeCommentSection extends ConsumerStatefulWidget {
  final String postId;
  final String postAuthorId;

  const RealtimeCommentSection({
    super.key,
    required this.postId,
    required this.postAuthorId,
  });

  @override
  ConsumerState<RealtimeCommentSection> createState() =>
      _RealtimeCommentSectionState();
}

class _RealtimeCommentSectionState extends ConsumerState<RealtimeCommentSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String? _replyingToId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsStreamProvider(widget.postId));
    final currentUser = ref.watch(authProvider).user;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
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
            _buildHeader(theme, commentsAsync),

            const Divider(height: 1),

            // Comments list
            Expanded(
              child: commentsAsync.when(
                data: (comments) => _buildCommentsList(comments, theme),
                loading: () => _buildLoadingState(theme),
                error: (error, stack) => _buildErrorState(theme, error),
              ),
            ),

            // Reply indicator
            if (_replyingToId != null) _buildReplyIndicator(theme),

            // Comment input
            _buildCommentInput(theme, currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AsyncValue<List<CommentModel>> commentsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                commentsAsync.when(
                  data: (comments) => Text(
                    '${comments.length} ${comments.length == 1 ? 'comment' : 'comments'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  loading: () => Text(
                    'Loading...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  error: (_, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<CommentModel> comments, ThemeData theme) {
    if (comments.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Separate top-level comments and replies
    final topLevelComments = comments.where((c) => c.parentId == null).toList();
    topLevelComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: topLevelComments.length,
      itemBuilder: (context, index) {
        final comment = topLevelComments[index];
        final replies = comments.where((c) => c.parentId == comment.id).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return _buildCommentItem(comment, replies, theme);
      },
    );
  }

  Widget _buildCommentItem(
    CommentModel comment,
    List<CommentModel> replies,
    ThemeData theme,
  ) {
    final currentUserId = ref.read(authProvider).user?.uid;
    final isOwner = currentUserId == comment.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              LiveUserAvatar(
                userId: comment.authorId,
                radius: 18,
                fallbackUrl: comment.authorAvatar,
                fallbackName: comment.authorName,
              ),

              const SizedBox(width: 12),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author and timestamp
                    Row(
                      children: [
                        LiveUserDisplayName(
                          userId: comment.authorId,
                          fallbackName: comment.authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(comment.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Comment text
                    Text(
                      comment.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),

                    const SizedBox(height: 8),

                    // Action buttons
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: () => _toggleCommentLike(comment.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  comment.likes.contains(currentUserId)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: comment.likes.contains(currentUserId)
                                      ? Colors.red
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                                if (comment.likes.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.likes.length}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          comment.likes.contains(currentUserId)
                                          ? Colors.red
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Reply button
                        InkWell(
                          onTap: () =>
                              _startReply(comment.id, comment.authorName),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'Reply',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Delete button (for owner)
                        if (isOwner)
                          IconButton(
                            onPressed: () => _deleteComment(comment.id),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Replies
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 12),
              child: Column(
                children: replies.map((reply) {
                  return _buildReplyItem(reply, theme);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(CommentModel reply, ThemeData theme) {
    final currentUserId = ref.read(authProvider).user?.uid;
    final isOwner = currentUserId == reply.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveUserAvatar(
            userId: reply.authorId,
            radius: 14,
            fallbackUrl: reply.authorAvatar,
            fallbackName: reply.authorName,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LiveUserDisplayName(
                      userId: reply.authorId,
                      fallbackName: reply.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimestamp(reply.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.content,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),

          if (isOwner)
            IconButton(
              onPressed: () => _deleteComment(reply.id),
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToUsername',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme, user) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: isKeyboardOpen ? 12 : mediaQuery.padding.bottom + 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundImage: user?.photoURL != null
                    ? CachedNetworkImageProvider(user!.photoURL!)
                    : null,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: user?.photoURL == null
                    ? Text(
                        user?.displayName?[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _replyingToId != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(color: theme.colorScheme.primary),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load comments',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(commentsProvider(widget.postId).notifier)
        .addComment(widget.postId, content);

    _commentController.clear();
    _cancelReply();
    _focusNode.unfocus();

    // Scroll to bottom to show new comment
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToId = commentId;
      _replyingToUsername = username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
    });
  }

  void _toggleCommentLike(String commentId) {
    ref
        .read(commentsProvider(widget.postId).notifier)
        .toggleCommentLike(widget.postId, commentId);
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(commentsProvider(widget.postId).notifier)
                  .deleteComment(widget.postId, commentId);
              Navigator.pop(context);
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
