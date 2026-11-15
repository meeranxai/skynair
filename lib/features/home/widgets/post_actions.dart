import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// PHASE 1: Share disabled (Enable in Phase 2)
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/post_interaction_provider.dart';
import '../../../core/providers/saved_posts_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/posts_provider.dart';

class PostActions extends ConsumerWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onCommentTap;
  final Animation<double>? likeScaleAnimation;
  final Animation<double>? saveScaleAnimation;
  final Function(bool isLiked)? onLikeToggle;
  final Function(bool isSaved)? onSaveToggle;

  const PostActions({
    super.key,
    required this.post,
    this.currentUserId,
    this.onCommentTap,
    this.likeScaleAnimation,
    this.saveScaleAnimation,
    this.onLikeToggle,
    this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOwner = currentUserId == post.authorId;
    final isLiked = post.isLikedBy(currentUserId ?? '');
    final isSaved = post.isSavedBy(currentUserId ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Main action buttons
          Row(
            children: [
              // Like button
              _buildLikeButton(context, ref, theme, isLiked),
              const SizedBox(width: 16),

              // Comment button
              _buildCommentButton(context, theme),
              const SizedBox(width: 16),

              _buildShareButton(context, ref, theme),
              const SizedBox(width: 16),
              const Spacer(),

              // Save button (viewers only) or More options (owner/viewer)
              if (isOwner)
                _buildOwnerMoreButton(context, ref, theme)
              else ...[
                _buildSaveButton(context, ref, theme, isSaved),
                const SizedBox(width: 16),
                _buildViewerMoreButton(context, ref, theme),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Engagement stats
          _buildEngagementStats(context, theme),
        ],
      ),
    );
  }

  Widget _buildLikeButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isLiked,
  ) {
    Widget icon = Icon(
      isLiked ? Icons.favorite : Icons.favorite_border,
      color: isLiked
          ? Colors.red
          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      size: 22,
    );

    if (likeScaleAnimation != null) {
      icon = ScaleTransition(scale: likeScaleAnimation!, child: icon);
    }

    return GestureDetector(
      onTap: () {
        if (currentUserId != null) {
          HapticFeedback.lightImpact();

          if (onLikeToggle != null) {
            onLikeToggle!(isLiked);
          } else {
            // Fallback to direct provider call if no toggle handler provided
            ref.read(postsProvider.notifier).likePost(post.id);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLiked
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (post.likes.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(post.likes.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLiked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: onCommentTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            if (post.commentsCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(post.commentsCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // PHASE 1: Share button disabled (Enable in Phase 2)
  Widget _buildShareButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        _showShareOptions(context, ref);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.share_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            if (post.shareCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(post.shareCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isSaved,
  ) {
    Widget icon = Icon(
      isSaved ? Icons.bookmark : Icons.bookmark_border,
      color: isSaved
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      size: 22,
    );

    if (saveScaleAnimation != null) {
      icon = ScaleTransition(scale: saveScaleAnimation!, child: icon);
    }

    return GestureDetector(
      onTap: () {
        if (currentUserId != null) {
          HapticFeedback.lightImpact();

          if (onSaveToggle != null) {
            onSaveToggle!(isSaved);
          } else {
            // Fallback to direct provider call if no toggle handler provided
            ref.read(savedPostsProvider.notifier).toggleSave(post.id);
          }

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isSaved ? 'Post unsaved' : 'Post saved!'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSaved
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: icon,
      ),
    );
  }

  Widget _buildViewerMoreButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showViewerOptions(context, ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Icon(
          Icons.more_horiz,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildOwnerMoreButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showOwnerOptions(context, ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Icon(
          Icons.more_horiz,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildEngagementStats(BuildContext context, ThemeData theme) {
    final totalEngagement =
        post.likes.length + post.commentsCount + post.shareCount;

    if (totalEngagement == 0) return const SizedBox.shrink();

    return Row(
      children: [
        if (post.likes.isNotEmpty) ...[
          GestureDetector(
            onTap: () => _showLikesList(context),
            child: Text(
              '${_formatCount(post.likes.length)} ${post.likes.length == 1 ? 'like' : 'likes'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (post.likes.isNotEmpty &&
            (post.commentsCount > 0 || post.shareCount > 0))
          Text(
            ' • ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        if (post.commentsCount > 0) ...[
          GestureDetector(
            onTap: onCommentTap,
            child: Text(
              '${_formatCount(post.commentsCount)} ${post.commentsCount == 1 ? 'comment' : 'comments'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        // PHASE 1: Share count disabled (Enable in Phase 2)
        // if (post.shareCount > 0 &&
        //     (post.likes.isNotEmpty || post.commentsCount > 0))
        //   Text(
        //     ' • ',
        //     style: theme.textTheme.bodySmall?.copyWith(
        //       color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        //     ),
        //   ),
        // if (post.shareCount > 0) ...[
        //   Text(
        //     '${_formatCount(post.shareCount)} ${post.shareCount == 1 ? 'share' : 'shares'}',
        //     style: theme.textTheme.bodySmall?.copyWith(
        //       color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        // ],
      ],
    );
  }

  void _showViewerOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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

            // Post Safety Actions
            ListTile(
              leading: Icon(
                Icons.report_outlined,
                color: theme.colorScheme.error,
              ),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, ref);
              },
            ),

            // User Actions
            ListTile(
              leading: Icon(
                Icons.volume_off_outlined,
                color: theme.colorScheme.error,
              ),
              title: const Text('Mute User'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(postInteractionProvider.notifier)
                    .muteUser(post.authorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User muted successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block_outlined,
                color: theme.colorScheme.error,
              ),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // PHASE 1: Share options disabled (Enable in Phase 2)
  void _showShareOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
            ListTile(
              leading: Icon(Icons.share, color: theme.colorScheme.primary),
              title: const Text('Share via...'),
              onTap: () async {
                Navigator.pop(context);
                final shareText =
                    'Check out this post: ${post.title}\n\n${post.description}';
                await Share.share(shareText);
                // Use postsProvider for app-wide state sync
                ref.read(postsProvider.notifier).sharePost(post.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: theme.colorScheme.primary),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                // In a real app, you'd generate a deep link here
                final postLink = 'https://Skynaire.app/posts/${post.id}';
                Clipboard.setData(ClipboardData(text: postLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showOwnerOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                final postType = post.postType;
                context.push('/create?type=$postType', extra: post);
              },
            ),
//             ListTile(
//               leading: Icon(
//                 Icons.visibility_outlined,
//                 color: theme.colorScheme.primary,
//               ),
//               title: const Text('Change Visibility'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showVisibilityOptions(context, ref);
//               },
//             ),
//             ListTile(
//               leading: Icon(
//                 Icons.analytics_outlined,
//                 color: theme.colorScheme.primary,
//               ),
//               title: const Text('View Insights'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showPostInsights(context, ref);
//               },
//             ),
            // PHASE 1: Share disabled (Enable in Phase 2)
            // ListTile(
            //   leading: Icon(
            //     Icons.share_outlined,
            //     color: theme.colorScheme.primary,
            //   ),
            //   title: const Text('Share Post'),
            //   onTap: () async {
            //     Navigator.pop(context);
            //     final shareText =
            //         'Check out this post: ${post.title}\n\n${post.description}';
            //     await SharePlus.instance.share(ShareParams(text: shareText));
            //     // Use postsProvider for app-wide state sync
            //     ref.read(postsProvider.notifier).sharePost(post.id);
            //     if (context.mounted) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text('Post shared successfully!'),
            //           behavior: SnackBarBehavior.floating,
            //         ),
            //       );
            //     }
            //   },
            // ),
            ListTile(
              leading: Icon(
                Icons.archive_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Archive Post'),
              onTap: () {
                Navigator.pop(context);
                _showArchiveConfirmation(context, ref);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outlined,
                color: theme.colorScheme.error,
              ),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showArchiveConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Post'),
        content: const Text(
          'Are you sure you want to archive this post? It will be moved to your archive folder and hidden from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(postsProvider.notifier).archivePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post archived successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String selectedReason = 'Inappropriate content';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Reason',
              ),
              items:
                  [
                        'Inappropriate content',
                        'Spam',
                        'Harassment',
                        'False information',
                        'Copyright violation',
                        'Other',
                      ]
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) selectedReason = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(postInteractionProvider.notifier)
                  .reportPost(post.id, selectedReason);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post reported successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block @${post.authorUsername ?? 'this user'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(postInteractionProvider.notifier)
                  .blockUser(post.authorId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
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
              // Use postsProvider for app-wide state sync
              ref.read(postsProvider.notifier).deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post deleted successfully!'),
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



  void _showVisibilityOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Post Visibility',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Public'),
              subtitle: const Text('Anyone can see this post'),
              trailing: post.visibility == 'public'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                // Use postsProvider for app-wide state sync
                ref
                    .read(postsProvider.notifier)
                    .updatePostVisibility(post.id, 'public');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Friends'),
              subtitle: const Text('Only your friends can see this post'),
              trailing: post.visibility == 'friends'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                // Use postsProvider for app-wide state sync
                ref
                    .read(postsProvider.notifier)
                    .updatePostVisibility(post.id, 'friends');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Private'),
              subtitle: const Text('Only you can see this post'),
              trailing: post.visibility == 'private'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.pop(context);
                // Use postsProvider for app-wide state sync
                ref
                    .read(postsProvider.notifier)
                    .updatePostVisibility(post.id, 'private');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPostInsights(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Insights'),
        content: Consumer(
          builder: (context, ref, child) {
            final insightsAsync = ref.watch(postInsightsProvider(post.id));

            return insightsAsync.when(
              data: (insights) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightRow(
                    'Total Likes',
                    insights['totalLikes'].toString(),
                  ),
                  _buildInsightRow(
                    'Total Saves',
                    insights['totalSaves'].toString(),
                  ),
                  _buildInsightRow(
                    'Total Shares',
                    insights['totalShares'].toString(),
                  ),
                  _buildInsightRow(
                    'Total Comments',
                    insights['totalComments'].toString(),
                  ),
                  _buildInsightRow(
                    'Total Engagement',
                    insights['engagement'].toString(),
                  ),
                  _buildInsightRow(
                    'Days Since Created',
                    insights['daysSinceCreated'].toString(),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLikesList(BuildContext context) {
    // TODO: Implement likes list dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Likes list coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }
}
