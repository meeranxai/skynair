import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/ai_feed_service.dart';
import '../services/follow_service.dart';
import 'auth_provider.dart';
import 'posts_provider.dart';
import 'blocking_provider.dart';

/// Feed type enum
enum FeedType {
  forYou, // AI-powered personalized feed
  following, // Posts from followed users
  trending, // Trending posts
  recommended, // Recommended based on similar users
}

/// AI Feed State
class AIFeedState {
  final List<PostModel> posts;
  final FeedType currentFeedType;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? analytics;

  AIFeedState({
    this.posts = const [],
    this.currentFeedType = FeedType.forYou,
    this.isLoading = false,
    this.error,
    this.analytics,
  });

  AIFeedState copyWith({
    List<PostModel>? posts,
    FeedType? currentFeedType,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? analytics,
  }) {
    return AIFeedState(
      posts: posts ?? this.posts,
      currentFeedType: currentFeedType ?? this.currentFeedType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      analytics: analytics ?? this.analytics,
    );
  }
}

/// AI Feed Provider
final aiFeedProvider = StateNotifierProvider<AIFeedNotifier, AIFeedState>((
  ref,
) {
  return AIFeedNotifier(ref);
});

class AIFeedNotifier extends StateNotifier<AIFeedState> {
  final Ref ref;
  final List<PostModel> _recentlyShownPosts = [];
  final Map<FeedType, List<PostModel>> _cache = {};

  AIFeedNotifier(this.ref) : super(AIFeedState()) {
    // Initialize with For You feed
    generateFeed(FeedType.forYou);

    // Listen to postsProvider for real-time updates
    ref.listen(postsProvider, (previous, next) {
      if (previous != null && (previous.posts != next.posts || previous.isLoading != next.isLoading)) {
        _syncWithPosts(next.posts);
      }
    });



    // Listen to blockedUserIdsProvider to refresh feed when blocking/unblocking
    ref.listen(blockedUserIdsProvider, (previous, next) {
      if (next.hasValue) {
        refreshFeed();
      }
    });
  }

  /// Sync local feed posts with updated posts from main provider
  void _syncWithPosts(List<PostModel> updatedPosts) {
    if (!mounted) return;
    
    final blockedIds = ref.read(blockedUserIdsProvider).valueOrNull ?? [];
    
    // If current state is empty, check if we should trigger a full feed generation
    if (state.posts.isEmpty && !state.isLoading) {
      final relevantPosts = updatedPosts.where((p) => !blockedIds.contains(p.authorId)).toList();
      if (relevantPosts.isNotEmpty) {
        // Use a slight delay to ensure other providers have finished updates
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) generateFeed(state.currentFeedType);
        });
        return;
      }
    }

    if (state.posts.isEmpty && _cache.isEmpty) return;

    // Sync current state
    if (state.posts.isNotEmpty) {
      state = state.copyWith(posts: _filterAndSyncPosts(state.posts, updatedPosts, blockedIds));
    }

    // Sync cache
    _cache.forEach((key, value) {
      _cache[key] = _filterAndSyncPosts(value, updatedPosts, blockedIds);
    });
  }

  List<PostModel> _filterAndSyncPosts(List<PostModel> currentPosts, List<PostModel> updatedPosts, List<String> blockedIds) {
    final Map<String, PostModel> updatedPostsMap = {
      for (var post in updatedPosts) 
        if (!blockedIds.contains(post.authorId))
          post.id: post,
    };

    return currentPosts
        .where((post) => !blockedIds.contains(post.authorId))
        .map((post) {
      if (updatedPostsMap.containsKey(post.id)) {
        return updatedPostsMap[post.id]!;
      }
      return post;
    }).toList();
  }

  /// Generate feed based on type
  Future<void> generateFeed(FeedType feedType, {bool isRefresh = false}) async {
    try {
      // If we have cached posts and it's not a refresh, show them immediately
      if (!isRefresh && _cache.containsKey(feedType) && _cache[feedType]!.isNotEmpty) {
        state = state.copyWith(
          posts: _cache[feedType]!,
          currentFeedType: feedType,
          isLoading: false,
          error: null,
        );
        // We still trigger a background refresh to keep it fresh
      } else {
        state = state.copyWith(
          isLoading: true,
          error: null,
          currentFeedType: feedType,
          // Don't clear posts if we are refreshing or if we have data for this type
          posts: isRefresh ? state.posts : (_cache[feedType] ?? []),
        );
      }

      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Get blocked users
      final blockedIds = ref.read(blockedUserIdsProvider).value ?? [];

      // Get all posts and articles and filter out blocked ones
      final postsState = ref.read(postsProvider);
      
      final allPosts = postsState.posts.where((post) => 
          !blockedIds.contains(post.authorId) && post.isArchived != true
      ).toList();

      if (allPosts.isEmpty) {
        _cache[feedType] = [];
        state = state.copyWith(isLoading: false, posts: []);
        return;
      }

      List<PostModel> feed;
      Map<String, dynamic>? analytics;

      switch (feedType) {
        case FeedType.forYou:
          feed = AIFeedService.generatePersonalizedFeed(
            allPosts: allPosts,
            currentUser: currentUser,
            recentlyShownPosts: _recentlyShownPosts,
            limit: 20,
          );
          analytics = AIFeedService.getFeedAnalytics(
            feed: feed,
            currentUser: currentUser,
          );
          break;

        case FeedType.following:
          final followingIds = await FollowService.getFollowing(
            currentUser.uid,
          );

          if (followingIds.isEmpty) {
            feed = [];
          } else {
            feed = AIFeedService.getFollowingFeed(
              allPosts: allPosts,
              followingIds: followingIds,
              limit: 20,
            );
          }
          break;

        case FeedType.trending:
          feed = AIFeedService.getTrendingPosts(allPosts, limit: 20);
          break;

        case FeedType.recommended:
          feed = AIFeedService.generatePersonalizedFeed(
            allPosts: allPosts,
            currentUser: currentUser,
            recentlyShownPosts: _recentlyShownPosts,
            limit: 20,
          );
          break;
      }

      // Track shown posts for diversity
      _recentlyShownPosts.addAll(feed);
      if (_recentlyShownPosts.length > 50) {
        _recentlyShownPosts.removeRange(0, _recentlyShownPosts.length - 50);
      }

      // Update cache
      _cache[feedType] = feed;

      state = state.copyWith(
        isLoading: false,
        posts: feed,
        analytics: analytics,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate feed: $e',
      );
    }
  }

  /// Refresh current feed
  Future<void> refreshFeed() async {
    await generateFeed(state.currentFeedType, isRefresh: true);
  }

  /// Switch feed type
  Future<void> switchFeedType(FeedType feedType) async {
    if (state.currentFeedType != feedType) {
      await generateFeed(feedType);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
