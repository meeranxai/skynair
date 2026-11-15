import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../home/widgets/enhanced_post_card.dart';

class PostDetailView extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final String? currentUserId;

  const PostDetailView({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.currentUserId,
  });

  @override
  ConsumerState<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends ConsumerState<PostDetailView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Post ${_currentIndex + 1} of ${widget.posts.length}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          // Share button - PHASE 1: Disabled (Enable in Phase 2)
          // IconButton(
          //   icon: Icon(
          //     Icons.share_outlined,
          //     color: theme.colorScheme.onSurface,
          //   ),
          //   onPressed: () => _sharePost(widget.posts[_currentIndex]),
          // ),
          // More options
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onPressed: () => _showPostOptions(widget.posts[_currentIndex]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.posts.length,
                    backgroundColor: theme.colorScheme.outline.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_currentIndex + 1}/${widget.posts.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Posts PageView with vertical scrolling
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical, // Vertical scrolling
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.posts.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: EnhancedPostCard(
                      post: widget.posts[index],
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation hints
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentIndex > 0) ...[
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe up for previous',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (_currentIndex > 0 &&
                    _currentIndex < widget.posts.length - 1)
                  const SizedBox(width: 16),
                if (_currentIndex < widget.posts.length - 1) ...[
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe down for next',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PHASE 1: Share disabled (Enable in Phase 2)
  // void _sharePost(PostModel post) {
  //   // TODO: Implement post sharing
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Sharing "${post.title}"...'),
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     ),
  //   );
  // }

  void _showPostOptions(PostModel post) {
    final theme = Theme.of(context);
    final isOwnPost = post.authorId == widget.currentUserId;

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

            if (isOwnPost) ...[
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(post);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: const Text('Delete Post'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(
                  Icons.bookmark_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Save Post'),
                onTap: () {
                  Navigator.pop(context);
                  _savePost(post);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.report_outlined,
                  color: theme.colorScheme.error,
                ),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(post);
                },
              ),
            ],

            // PHASE 1: Share features disabled (Enable in Phase 2)
            // ListTile(
            //   leading: Icon(
            //     Icons.share_outlined,
            //     color: theme.colorScheme.primary,
            //   ),
            //   title: const Text('Share Post'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _sharePost(post);
            //   },
            // ),
            // ListTile(
            //   leading: Icon(
            //     Icons.link_outlined,
            //     color: theme.colorScheme.primary,
            //   ),
            //   title: const Text('Copy Link'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _copyPostLink(post);
            //   },
            // ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editPost(PostModel post) {
    // TODO: Navigate to edit post page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit post functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deletePost(PostModel post) {
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement post deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post deleted successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _savePost(PostModel post) {
    // TODO: Implement post saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.bookmark, color: Colors.white),
            SizedBox(width: 12),
            Text('Post saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reportPost(PostModel post) {
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

  // PHASE 1: Share disabled (Enable in Phase 2)
  // void _copyPostLink(PostModel post) {
  //   // TODO: Copy post link to clipboard
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Row(
  //         children: [
  //           Icon(Icons.link, color: Colors.white),
  //           SizedBox(width: 12),
  //           Text('Post link copied to clipboard!'),
  //         ],
  //       ),
  //       backgroundColor: Colors.green,
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }
}
