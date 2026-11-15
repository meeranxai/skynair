import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/saved_posts_provider.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/live_user_widgets.dart';

class ExplorePostCard extends ConsumerStatefulWidget {
  final PostModel post;

  const ExplorePostCard({super.key, required this.post});

  @override
  ConsumerState<ExplorePostCard> createState() => _ExplorePostCardState();
}

class _ExplorePostCardState extends ConsumerState<ExplorePostCard> {
  bool _isExpanded = false;

  bool get hasImage {
    return (widget.post.image != null && widget.post.image!.isNotEmpty) || 
           (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty);
  }

  void _navigateToPostDetail(BuildContext context, PostModel postData) {
    // context.push('/posts/${postData.id}', extra: {'allPosts': [postData]});
    
    context.push('/posts/${postData.id}', extra: {'allPosts': [postData]});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;
    final post = widget.post;

    // Watch the correct provider to get real-time updates
    final postsState = ref.watch(postsProvider);
    final updatedPost = postsState.posts.firstWhere(
      (p) => p.id == post.id,
      orElse: () => post,
    );

    final isLiked = updatedPost.isLikedBy(currentUser?.uid ?? '');
    final isSaved = updatedPost.isSavedBy(currentUser?.uid ?? '');

    return GestureDetector(
      onTap: () => _navigateToPostDetail(context, updatedPost),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          image: hasImage
              ? DecorationImage(
                  image: CachedNetworkImageProvider(updatedPost.imageUrls?.first ?? updatedPost.image!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient Overlay for text visibility
            if (hasImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),

            // Content for text-only posts
            if (!hasImage)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    updatedPost.title.isNotEmpty ? updatedPost.title : updatedPost.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Author Info Overlay (Bottom)
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  LiveUserAvatar(
                    userId: updatedPost.authorId,
                    radius: 10,
                    fallbackUrl: updatedPost.authorAvatar,
                    fallbackName: updatedPost.author,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LiveUserDisplayName(
                      userId: updatedPost.authorId,
                      fallbackName: updatedPost.author,
                      showVerified: false,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasImage ? Colors.white : theme.colorScheme.onSurface,
                        shadows: hasImage
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _navigateToComments(BuildContext context, PostModel postData) {
    context.push('/posts/${postData.id}/comments');
  }

  void _toggleLike(WidgetRef ref, PostModel postData) {
    ref.read(postsProvider.notifier).likePost(postData.id);
  }

  void _toggleSave(WidgetRef ref, PostModel postData) {
    ref.read(postsProvider.notifier).savePost(postData.id);
  }

  void _showPostOptions(BuildContext context, WidgetRef ref, PostModel postData) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authProvider).user;
    final isOwner = currentUser?.uid == postData.authorId;

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
                    leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                    title: const Text('Edit Post'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/create?type=media', extra: postData);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.archive, color: theme.colorScheme.secondary),
                    title: Text(postData.isArchived ? 'Unarchive Post' : 'Archive Post'),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(postsProvider.notifier).archivePost(postData.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(postData.isArchived ? 'Post unarchived' : 'Post archived'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: theme.colorScheme.error),
                    title: const Text('Delete Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(context, ref, postData);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(Icons.report_gmailerrorred_rounded, color: theme.colorScheme.error),
                    title: const Text('Report Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context, ref, postData);
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

  void _confirmDelete(BuildContext context, WidgetRef ref, PostModel postData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(postsProvider.notifier).deletePost(postData.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, PostModel postData) {
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
                    _submitReport(context, ref, postData, reasons[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, WidgetRef ref, PostModel postData, String reason) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await FirestoreService.submitReport(
        reporterId: currentUser.uid,
        targetId: postData.id,
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
}

