import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/share_service.dart';
import '../services/internal_share_service.dart';
import '../services/app_availability_service.dart';
import '../providers/auth_provider.dart';

// Provider for available share destinations
final availableShareDestinationsProvider =
    FutureProvider<List<ShareDestinationInfo>>((ref) async {
      final availableApps =
          await AppAvailabilityService.getAvailableDestinations();

      return ShareDestinationInfo.all.where((destination) {
        final availability = availableApps.firstWhere(
          (app) => app.destination == destination.destination.name,
          orElse: () => ShareDestinationAvailability(
            destination: '',
            name: '',
            isAvailable: false,
          ),
        );
        return availability.isAvailable;
      }).toList();
    });

class EnhancedShareDialog extends ConsumerStatefulWidget {
  final PostModel post;

  const EnhancedShareDialog({super.key, required this.post});

  @override
  ConsumerState<EnhancedShareDialog> createState() =>
      _EnhancedShareDialogState();
}

class _EnhancedShareDialogState extends ConsumerState<EnhancedShareDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Share Post',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'External', icon: Icon(Icons.share)),
              Tab(text: 'Internal', icon: Icon(Icons.people)),
            ],
          ),

          // Tab views
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExternalShareTab(theme),
                _buildInternalShareTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalShareTab(ThemeData theme) {
    final availableDestinationsAsync = ref.watch(
      availableShareDestinationsProvider,
    );

    return availableDestinationsAsync.when(
      data: (availableDestinations) {
        if (availableDestinations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apps_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No apps available',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Install WhatsApp, Instagram, or other apps to share',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post preview
              _buildPostPreview(theme),

              const SizedBox(height: 24),

              // Share options grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share to',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${availableDestinations.length} apps available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: availableDestinations.length,
                itemBuilder: (context, index) {
                  final destination = availableDestinations[index];
                  return _buildShareOption(theme, destination);
                },
              ),

              const SizedBox(height: 16),

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only showing apps installed on your device',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // Fallback to showing all options if detection fails
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostPreview(theme),
              const SizedBox(height: 24),
              Text(
                'Share to',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: ShareDestinationInfo.all.length,
                itemBuilder: (context, index) {
                  final destination = ShareDestinationInfo.all[index];
                  return _buildShareOption(theme, destination);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInternalShareTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post preview
          _buildPostPreview(theme),

          const SizedBox(height: 24),

          // Repost option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.repeat, color: theme.colorScheme.primary),
            ),
            title: const Text('Repost to your feed'),
            subtitle: const Text('Share with your followers'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleRepost(context),
          ),

          const Divider(),

          // Quote post option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.format_quote,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: const Text('Quote post'),
            subtitle: const Text('Add your thoughts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleQuotePost(context),
          ),

          const Divider(),

          // Send via DM option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(Icons.send, color: theme.colorScheme.tertiary),
            ),
            title: const Text('Send via message'),
            subtitle: const Text('Share with specific people'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleSendViaDM(context),
          ),

          const SizedBox(height: 16),

          // Share statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  theme,
                  Icons.repeat,
                  widget.post.shareCount.toString(),
                  'Shares',
                ),
                _buildStatItem(
                  theme,
                  Icons.favorite,
                  widget.post.likes.length.toString(),
                  'Likes',
                ),
                _buildStatItem(
                  theme,
                  Icons.comment,
                  widget.post.commentsCount.toString(),
                  'Comments',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(widget.post.authorName[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.post.authorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          if (widget.post.title.isNotEmpty) ...[
            Text(
              widget.post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],

          // Description
          Text(
            widget.post.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Image indicator
          if (widget.post.image != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.image, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Contains image',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareOption(ThemeData theme, ShareDestinationInfo destination) {
    return InkWell(
      onTap: () => _handleExternalShare(destination.destination),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: destination.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(destination.icon, color: destination.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            destination.name,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExternalShare(ShareDestination destination) async {
    setState(() => _isLoading = true);

    try {
      await ShareService.shareToApp(
        post: widget.post,
        destination: destination,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show helpful error message
        final errorMessage = _getShareErrorMessage(destination, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Use Other',
              onPressed: () {
                // Fallback to generic share
                ShareService.sharePostExternal(post: widget.post);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getShareErrorMessage(ShareDestination destination, dynamic error) {
    switch (destination) {
      case ShareDestination.whatsapp:
        return 'WhatsApp not installed or unavailable';
      case ShareDestination.instagram:
        return 'Instagram not installed or unavailable';
      case ShareDestination.facebook:
        return 'Facebook not installed or unavailable';
      case ShareDestination.twitter:
        return 'Twitter not installed or unavailable';
      case ShareDestination.telegram:
        return 'Telegram not installed or unavailable';
      default:
        return 'Failed to share: $error';
    }
  }

  Future<void> _handleRepost(BuildContext context) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await InternalShareService.repost(
        originalPost: widget.post,
        userId: currentUser.uid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reposted to your feed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to repost: $e')));
      }
    }
  }

  Future<void> _handleQuotePost(BuildContext context) async {
    // TODO: Navigate to create post with quote
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quote post coming soon!')));
  }

  Future<void> _handleSendViaDM(BuildContext context) async {
    // TODO: Show user selection dialog
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Send via DM coming soon!')));
  }
}
