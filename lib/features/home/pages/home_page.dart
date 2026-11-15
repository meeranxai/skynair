import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/ai_feed_provider.dart';
import '../../../core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/feed_card.dart';
import '../widgets/story_bar.dart';

/// Skynaire Home Page with modern feed interface
class SkynaireHomePage extends ConsumerStatefulWidget {
  const SkynaireHomePage({super.key});

  @override
  ConsumerState<SkynaireHomePage> createState() => _SkynaireHomePageState();
}

class _SkynaireHomePageState extends ConsumerState<SkynaireHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load posts when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if user is authenticated before loading
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && !authState.isLoading) {
        // Fetch both media and articles to populate the ai feed comprehensively
        await Future.wait([
          ref.read(postsProvider.notifier).fetchPosts(),
        ]);
        if (mounted) {
          ref.read(aiFeedProvider.notifier).refreshFeed();
        }
        
        // Request notification permission contextually
        _requestNotificationPermission();
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('notification_prompted') ?? false;

    if (hasPrompted) return;

    final status = await Permission.notification.status;
    if (status.isGranted) return;

    if (mounted) {
      // Show custom dialog first to build trust (Soft Request)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Colors.blue),
              SizedBox(width: 12),
              Text('Stay Updated?'),
            ],
          ),
          content: const Text(
            'Would you like to receive notifications for new likes, comments, and mentions? We promise not to spam you!',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setBool('notification_prompted', true);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await prefs.setBool('notification_prompted', true);
                // Trigger system permission request
                if (mounted) {
                  await PermissionService.checkAndRequest(Permission.notification, context);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check when dependencies change (e.g., after login)
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated && !authState.isLoading) {
      // Trigger a refresh if both providers are empty
      if (ref.read(postsProvider).posts.isEmpty) {
        Future.microtask(() {
          ref.read(postsProvider.notifier).fetchPosts();
          ref.read(aiFeedProvider.notifier).refreshFeed();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiFeedState = ref.watch(aiFeedProvider);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: () async {
            await Future.wait([
               ref.read(postsProvider.notifier).fetchPosts(),
            ]);
          await ref.read(aiFeedProvider.notifier).refreshFeed();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Feed type selector
            _buildFeedTypeSelector(theme, aiFeedState),

            // Stories Section
            _buildStoriesSection(theme),

            // AI-powered feed
            _buildAIFeed(aiFeedState, currentUser?.uid),

            // Loading indicator
            if (aiFeedState.isLoading && aiFeedState.posts.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          // App logo/name
          Text(
            'Skynaire',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),

          // Action buttons
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),

        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildFeedTypeSelector(ThemeData theme, AIFeedState aiFeedState) {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildFeedTypeTab(
              theme,
              'For You',
              FeedType.forYou,
              aiFeedState.currentFeedType,
              Icons.auto_awesome,
            ),
            _buildFeedTypeTab(
              theme,
              'Following',
              FeedType.following,
              aiFeedState.currentFeedType,
              Icons.people,
            ),
            _buildFeedTypeTab(
              theme,
              'Trending',
              FeedType.trending,
              aiFeedState.currentFeedType,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTypeTab(
    ThemeData theme,
    String label,
    FeedType feedType,
    FeedType currentFeedType,
    IconData icon,
  ) {
    final isSelected = feedType == currentFeedType;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(aiFeedProvider.notifier).switchFeedType(feedType),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection(ThemeData theme) {
    return const SliverToBoxAdapter(child: StoryBar());
  }

  Widget _buildAIFeed(AIFeedState aiFeedState, String? currentUserId) {
    // Filter to show only media posts (not articles) in home feed
    final feedPosts = aiFeedState.posts
        .where((post) => post.postType == 'media' && post.isArchived != true)
        .toList();

    if (aiFeedState.isLoading && feedPosts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (aiFeedState.error != null && feedPosts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading feed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                aiFeedState.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(aiFeedProvider.notifier).refreshFeed(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (feedPosts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateTitle(aiFeedState.currentFeedType),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyStateMessage(aiFeedState.currentFeedType),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = feedPosts[index];
        return SkynaireFeedCard(
          key: ValueKey(post.id),
          post: post,
          currentUserId: currentUserId,
        );
      }, childCount: feedPosts.length),
    );
  }

  String _getEmptyStateTitle(FeedType feedType) {
    switch (feedType) {
      case FeedType.forYou:
        return 'Welcome to Skynaire!';
      case FeedType.following:
        return 'No posts from following';
      case FeedType.trending:
        return 'No trending posts';
      case FeedType.recommended:
        return 'No recommendations yet';
    }
  }

  String _getEmptyStateMessage(FeedType feedType) {
    switch (feedType) {
      case FeedType.forYou:
        return 'Start following people to see personalized content';
      case FeedType.following:
        return 'Follow people to see their posts here';
      case FeedType.trending:
        return 'Check back later for trending content';
      case FeedType.recommended:
        return 'Interact with posts to get recommendations';
    }
  }

  void _handleNotifications() {
    // Navigate to notifications
    // You can implement this based on your navigation system
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


}
