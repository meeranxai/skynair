import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/models/post_model.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/comments_provider.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/profile_navigation.dart';
import '../../../core/widgets/live_user_widgets.dart';

class CommentsPage extends ConsumerStatefulWidget {
  final PostModel? post;
  final String postId;

  const CommentsPage({super.key, this.post, required this.postId});

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  PostModel? _fetchedPost;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _fetchedPost = widget.post;
    }

    // Listen to keyboard visibility
    _commentFocusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _commentFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(authProvider).user;

    // If post not provided, fetch it
    if (_fetchedPost == null) {
      final postAsync = ref.watch(singlePostProvider(widget.postId));
      return postAsync.when(
        data: (post) {
          if (post == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Comments')),
              body: const Center(child: Text('Post not found')),
            );
          }
          // We can't call setState in build, but we can use the post directly
          return _buildScaffold(
            context,
            theme,
            post,
            commentsAsync,
            currentUser,
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Comments')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Comments')),
          body: Center(child: Text('Error: $error')),
        ),
      );
    }

    return _buildScaffold(
      context,
      theme,
      _fetchedPost!,
      commentsAsync,
      currentUser,
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    PostModel post,
    CommentsState commentsAsync,
    UserModel? currentUser,
  ) {
    return Scaffold(
      // Key fix: Prevent keyboard from resizing the scaffold
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
        ),
      ),
      body: GestureDetector(
        // Dismiss keyboard when tapping outside
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Post Preview
            _buildPostPreview(context, theme, post),

            const Divider(height: 1),

            // Comments List
            Expanded(
              child: commentsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : commentsAsync.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${commentsAsync.error}',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                ref.refresh(commentsProvider(widget.postId)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : commentsAsync.comments.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: _isKeyboardVisible
                            ? 80
                            : 8, // Add bottom padding when keyboard is visible
                      ),
                      itemCount: commentsAsync.comments.length,
                      itemBuilder: (context, index) => _buildCommentItem(
                        context,
                        theme,
                        commentsAsync.comments[index],
                        currentUser?.uid,
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Fixed bottom input that doesn't move with keyboard
      bottomSheet: _buildCommentInput(context, theme, currentUser, post),
    );
  }

  Widget _buildPostPreview(
    BuildContext context,
    ThemeData theme,
    PostModel post,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Avatar
          GestureDetector(
            onTap: () =>
                ProfileNavigation.navigateToProfile(context, post.authorId),
            child: LiveUserAvatar(
              userId: post.authorId,
              radius: 20,
              fallbackUrl: post.authorAvatar,
              fallbackName: post.author,
            ),
          ),

          const SizedBox(width: 12),

          // Post Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Name and Username
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ProfileNavigation.navigateToProfile(
                        context,
                        post.authorId,
                      ),
                      child: LiveUserDisplayName(
                        userId: post.authorId,
                        fallbackName: post.author,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (post.authorUsername != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '@${post.authorUsername}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Post Title and Description
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                if (post.description.isNotEmpty)
                  Text(
                    post.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
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
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
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
            'Be the first to comment on this post',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    ThemeData theme,
    CommentModel comment,
    String? currentUserId,
  ) {
    final isOwner = currentUserId == comment.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commenter Avatar
          GestureDetector(
            onTap: () =>
                ProfileNavigation.navigateToProfile(context, comment.authorId),
            child: LiveUserAvatar(
              userId: comment.authorId,
              radius: 16,
              fallbackUrl: comment.authorAvatar,
              fallbackName: comment.author,
            ),
          ),

          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ProfileNavigation.navigateToProfile(
                        context,
                        comment.authorId,
                      ),
                      child: LiveUserDisplayName(
                        userId: comment.authorId,
                        fallbackName: comment.author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (comment.authorUsername != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '@${comment.authorUsername}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isOwner)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) =>
                            _handleCommentAction(value, comment),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment Text
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                // Comment Actions
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () => _toggleCommentLike(comment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLikedBy(currentUserId ?? '')
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: comment.isLikedBy(currentUserId ?? '')
                                ? Colors.red
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                          if (comment.likes.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.length.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: comment.isLikedBy(currentUserId ?? '')
                                    ? Colors.red
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Reply Button
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    ThemeData theme,
    dynamic currentUser,
    PostModel post,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: _isKeyboardVisible
            ? MediaQuery.of(context).viewInsets.bottom + 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // User Avatar
            LiveUserAvatar(
              userId: currentUser?.uid ?? '',
              radius: 16,
              fallbackUrl: currentUser?.photoURL,
              fallbackName: currentUser?.displayName,
            ),

            const SizedBox(width: 12),

            // Comment Input Field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() {}),
                  onTap: () {
                    // Auto scroll to bottom when keyboard opens
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            IconButton(
              onPressed: _commentController.text.trim().isEmpty
                  ? null
                  : () => _addComment(post),
              icon: Icon(
                Icons.send_rounded,
                color: _commentController.text.trim().isEmpty
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : theme.colorScheme.primary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment(PostModel post) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();
    _commentFocusNode.unfocus();

    try {
      await ref
          .read(commentsProvider(widget.postId).notifier)
          .addComment(widget.postId, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
      }
    }
  }

  void _toggleCommentLike(CommentModel comment) {
    ref
        .read(commentsProvider(widget.postId).notifier)
        .toggleCommentLike(widget.postId, comment.id);
  }

  void _replyToComment(CommentModel comment) {
    _commentController.text = '@${comment.authorUsername ?? comment.author} ';
    _commentFocusNode.requestFocus();
  }

  void _handleCommentAction(String action, CommentModel comment) {
    switch (action) {
      case 'edit':
        _editComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
    }
  }

  void _editComment(CommentModel comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Comment',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(commentsProvider(widget.postId).notifier)
                  .updateComment(
                    widget.postId,
                    comment.id,
                    controller.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(CommentModel comment) {
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
          ElevatedButton(
            onPressed: () {
              ref
                  .read(commentsProvider(widget.postId).notifier)
                  .deleteComment(widget.postId, comment.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
