import 'dart:math';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// AI-Powered Feed Service
/// Provides personalized feed based on user preferences, interactions, and behavior
class AIFeedService {
  /// Calculate user interest score for a post
  /// Returns score from 0.0 to 1.0
  /// Extract hashtags from text
  static Set<String> _extractTags(String text) {
    if (text.isEmpty) return {};
    final regex = RegExp(r'#[a-zA-Z0-9_]+');
    return regex.allMatches(text).map((m) => m.group(0)!).toSet();
  }

  /// Calculate user interest score for a post (10x Logic)
  static double _calculateInterestScore(
    PostModel post,
    UserModel currentUser,
    Map<String, dynamic> userInteractions,
  ) {
    double score = 0.0;

    // 1. Topic Affinity (Category + Tags) - 40% Weight
    final categoryScores = userInteractions['categories'] as Map<String, double>? ?? {};
    // Normalized score (0-1)
    final maxCatScore = categoryScores.values.isEmpty ? 1.0 : categoryScores.values.reduce(max);
    final catScoreRaw = categoryScores[post.category] ?? 0.0;
    
    // Tag Affinity
    final tagScores = userInteractions['tags'] as Map<String, double>? ?? {};
    final postTags = _extractTags(post.description);
    double tagsScoreSum = 0.0;
    for (final tag in postTags) {
      tagsScoreSum += tagScores[tag] ?? 0.0;
    }
    // Normalize logic
    final topicScore = min(1.0, (catScoreRaw + tagsScoreSum) / max(10, maxCatScore));
    score += topicScore * 0.4;

    // 2. Author Affinity - 30% Weight
    final authorScores = userInteractions['authors'] as Map<String, double>? ?? {};
    final maxAuthScore = authorScores.values.isEmpty ? 1.0 : authorScores.values.reduce(max);
    final authScoreRaw = authorScores[post.authorId] ?? 0.0;
    final authorAffinity = min(1.0, authScoreRaw / max(10, maxAuthScore));
    score += authorAffinity * 0.3;

    // 3. Social & Viral Signals - 20% Weight
    // Here we use general engagement as a proxy for social proof
    final viralScore = _calculateEngagementScore(post); // 0-1 range
    score += viralScore * 0.2;

    // 4. Content Type Match - 10% Weight
    final hasImage = post.image != null;
    final prefersImages = userInteractions['prefersImages'] as bool? ?? true;
    if (hasImage == prefersImages) {
      score += 0.1;
    }

    return score; // Range 0.0 to 1.0
  }

  /// Calculate engagement score (Logarithmic Scale)
  static double _calculateEngagementScore(PostModel post) {
    // 1000 likes should be significantly better than 10, but 100k not 100x better than 10k
    final rawScore = (post.likes.length * 1.0) + 
                     (post.commentsCount * 2.5) + 
                     (post.shareCount * 4.0);
    
    if (rawScore == 0) return 0.0;
    
    // Log10 scale: 10 -> 1, 100 -> 2, 1000 -> 3
    final logScore = log(rawScore + 1) / ln10; 
    
    // Normalize to 0-1 range (assuming 4 (10k interactions) is 'max' relevant for feed mix)
    return min(1.0, logScore / 4.0); 
  }

  /// Calculate recency score (Gravity Decay)
  static double _calculateRecencyScore(DateTime postTime) {
    // Not used in main scoring anymore, integrated into Gravity for Trending
    // But useful for simple sorting if needed
    final hours = DateTime.now().difference(postTime).inHours;
    return 1.0 / pow((hours + 2), 1.5);
  }

  /// Calculate diversity bonus (Novelty)
  static double _calculateDiversityBonus(
    PostModel post,
    List<PostModel> recentlyShownPosts,
  ) {
    // Penalize if author seen recently
    final seenAuthors = recentlyShownPosts.map((p) => p.authorId).toSet();
    if (seenAuthors.contains(post.authorId)) return -0.15; // Penalize repetition

    // Boost if category unseen
    final seenCats = recentlyShownPosts.map((p) => p.category).toSet();
    if (!seenCats.contains(post.category)) return 0.15; // Boost variety

    return 0.0;
  }

  /// Track user interactions for learning (Weighted Model)
  static Map<String, dynamic> _buildUserInteractions(
    List<PostModel> allPosts,
    String currentUserId,
  ) {
    final interactions = <String, dynamic>{
      'categories': <String, double>{},
      'authors': <String, double>{},
      'tags': <String, double>{}, // New: Tag-based interest
      'prefersImages': true,
    };

    void scoreInteraction(PostModel post, double weight) {
      // Score Category
      final catScore = interactions['categories'][post.category] ?? 0.0;
      interactions['categories'][post.category] = catScore + (10.0 * weight);

      // Score Author
      final authScore = interactions['authors'][post.authorId] ?? 0.0;
      interactions['authors'][post.authorId] = authScore + (10.0 * weight);

      // Score Tags
      final tags = _extractTags(post.description);
      for (final tag in tags) {
        final tagScore = interactions['tags'][tag] ?? 0.0;
        interactions['tags'][tag] = tagScore + (5.0 * weight);
      }
    }

    // Analyze Feed History (Weighted)
    // Likes = 1x
    final likedPosts = allPosts.where((p) => p.isLikedBy(currentUserId));
    for (final post in likedPosts) scoreInteraction(post, 1.0);

    // Comments = 2x
    // Ideally we would filter purely by user's comments, but assuming high engagement posts are relevant
    
    // Saves = 3x (Strong intent)
    final savedPosts = allPosts.where((p) => p.isSavedBy(currentUserId));
    for (final post in savedPosts) scoreInteraction(post, 3.0);

    // Image Preference
    final likedWithImages = likedPosts.where((p) => p.image != null).length;
    final likedWithoutImages = likedPosts.where((p) => p.image == null).length;
    interactions['prefersImages'] = likedWithImages >= likedWithoutImages;

    return interactions;
  }

  /// Generate personalized feed using AI ranking
  static List<PostModel> generatePersonalizedFeed({
    required List<PostModel> allPosts,
    required UserModel currentUser,
    List<PostModel> recentlyShownPosts = const [],
    int limit = 20,
  }) {
    if (allPosts.isEmpty) return [];

    // Build user interaction profile
    final userInteractions = _buildUserInteractions(allPosts, currentUser.uid);

    // Calculate scores for each post
    final scoredPosts = <({PostModel post, double score})>[];

    for (final post in allPosts) {
      // Skip user's own posts (optional - can be configured)
      // if (post.authorId == currentUser.uid) continue;

      // Calculate base interest score
      double score = _calculateInterestScore(
        post,
        currentUser,
        userInteractions,
      );

      // Add diversity bonus
      final diversityBonus = _calculateDiversityBonus(post, recentlyShownPosts);
      score += diversityBonus;

      // Add randomness factor (5%) to avoid being too predictable
      final randomFactor = (Random().nextDouble() * 0.05);
      score += randomFactor;

      // Ensure score is between 0 and 1
      score = min(1.0, max(0.0, score));

      scoredPosts.add((post: post, score: score));
    }

    // Sort by score (highest first)
    scoredPosts.sort((a, b) => b.score.compareTo(a.score));

    // Apply smart mixing algorithm
    final finalFeed = _applySmartMixing(scoredPosts, limit);

    return finalFeed;
  }

  /// Apply smart mixing to avoid monotony
  /// Ensures variety in feed while maintaining relevance
  static List<PostModel> _applySmartMixing(
    List<({PostModel post, double score})> scoredPosts,
    int limit,
  ) {
    final result = <PostModel>[];
    final usedCategories = <String>{};
    final usedAuthors = <String>{};

    // First pass: Add top-scored posts with diversity
    for (final item in scoredPosts) {
      if (result.length >= limit) break;

      final post = item.post;
      final category = post.category;
      final author = post.authorId;

      // Add post if it brings diversity or has very high score
      if (item.score > 0.8 ||
          !usedCategories.contains(category) ||
          !usedAuthors.contains(author)) {
        result.add(post);
        usedCategories.add(category);
        usedAuthors.add(author);
      }
    }

    // Second pass: Fill remaining slots with best remaining posts
    if (result.length < limit) {
      for (final item in scoredPosts) {
        if (result.length >= limit) break;
        if (!result.contains(item.post)) {
          result.add(item.post);
        }
      }
    }

    return result;
  }

  /// Get trending posts (Gravity-based algorithm)
  /// Uses weighted engagement and time decay to identify viral content
  static List<PostModel> getTrendingPosts(
    List<PostModel> allPosts, {
    int limit = 20,
  }) {
    final now = DateTime.now();
    // Expand window to 7 days to catch viral content that is slightly older but still hot
    final validPeriod = now.subtract(const Duration(days: 7));

    // Filter viable posts first
    final validPosts = allPosts.where((p) => p.createdAt.isAfter(validPeriod));

    final scoredPosts = validPosts.map((post) {
      // 1. Calculate Weighted Engagement (Quality of interaction matters)
      // Likes = 1x
      // Comments = 2.5x (Higher effort)
      // Shares = 4x (High virality signal)
      // Saves = 3x (High value signal)
      final engagement = (post.likes.length * 1.0) +
          (post.commentsCount * 2.5) +
          (post.shareCount * 4.0) +
          (post.saves.length * 3.0);

      // 2. Calculate Age in Hours
      final ageInMinutes = max(1, now.difference(post.createdAt).inMinutes);
      final ageInHours = ageInMinutes / 60.0;

      // 3. Apply Gravity Formula
      // Score = Engagement / (Age + 2)^Gravity
      // Gravity: 1.8 (Standard news sites use ~1.8. Higher = faster turnover)
      const gravity = 1.8;
      final score = engagement / pow((ageInHours + 2), gravity);

      return (post: post, score: score);
    }).toList();

    // Sort by trending score
    scoredPosts.sort((a, b) => b.score.compareTo(a.score));

    return scoredPosts.take(limit).map((item) => item.post).toList();
  }

  /// Get posts from followed users (chronological with smart ranking)
  static List<PostModel> getFollowingFeed({
    required List<PostModel> allPosts,
    required List<String> followingIds,
    int limit = 20,
  }) {
    // Filter posts from followed users
    final followingPosts = allPosts
        .where((p) => followingIds.contains(p.authorId))
        .toList();

    // Sort by recency with engagement boost
    final scoredPosts = followingPosts.map((post) {
      final recencyScore = _calculateRecencyScore(post.createdAt);
      final engagementScore = _calculateEngagementScore(post);
      final finalScore = (recencyScore * 0.7) + (engagementScore * 0.3);

      return (post: post, score: finalScore);
    }).toList();

    scoredPosts.sort((a, b) => b.score.compareTo(a.score));

    return scoredPosts.take(limit).map((item) => item.post).toList();
  }

  /// Get recommended posts based on similar users
  static List<PostModel> getRecommendedPosts({
    required List<PostModel> allPosts,
    required UserModel currentUser,
    required List<UserModel> allUsers,
    int limit = 10,
  }) {
    // Find similar users based on interests
    final similarUsers = _findSimilarUsers(currentUser, allUsers, allPosts);

    // Get posts liked by similar users
    final recommendedPosts = <PostModel>[];
    for (final user in similarUsers.take(5)) {
      final userLikedPosts = allPosts
          .where((p) => p.isLikedBy(user.uid) && !p.isLikedBy(currentUser.uid))
          .toList();
      recommendedPosts.addAll(userLikedPosts);
    }

    // Remove duplicates and sort by engagement
    final uniquePosts = recommendedPosts.toSet().toList();
    uniquePosts.sort((a, b) {
      final scoreA = _calculateEngagementScore(a);
      final scoreB = _calculateEngagementScore(b);
      return scoreB.compareTo(scoreA);
    });

    return uniquePosts.take(limit).toList();
  }

  /// Find users with similar interests
  static List<UserModel> _findSimilarUsers(
    UserModel currentUser,
    List<UserModel> allUsers,
    List<PostModel> allPosts,
  ) {
    final currentUserLikes = allPosts
        .where((p) => p.isLikedBy(currentUser.uid))
        .map((p) => p.category)
        .toSet();

    final scoredUsers = <({UserModel user, double score})>[];

    for (final user in allUsers) {
      if (user.uid == currentUser.uid) continue;

      final userLikes = allPosts
          .where((p) => p.isLikedBy(user.uid))
          .map((p) => p.category)
          .toSet();

      // Calculate similarity (Jaccard similarity)
      final intersection = currentUserLikes.intersection(userLikes).length;
      final union = currentUserLikes.union(userLikes).length;
      final similarity = union > 0 ? intersection / union : 0.0;

      if (similarity > 0.2) {
        scoredUsers.add((user: user, score: similarity));
      }
    }

    scoredUsers.sort((a, b) => b.score.compareTo(a.score));
    return scoredUsers.map((item) => item.user).toList();
  }

  /// Get feed analytics for debugging
  static Map<String, dynamic> getFeedAnalytics({
    required List<PostModel> feed,
    required UserModel currentUser,
  }) {
    final categories = <String, int>{};
    final authors = <String, int>{};
    var postsWithImages = 0;
    var postsWithoutImages = 0;
    var totalEngagement = 0;

    for (final post in feed) {
      // Count categories
      categories[post.category] = (categories[post.category] ?? 0) + 1;

      // Count authors
      authors[post.authorId] = (authors[post.authorId] ?? 0) + 1;

      // Count image posts
      if (post.image != null) {
        postsWithImages++;
      } else {
        postsWithoutImages++;
      }

      // Calculate total engagement
      totalEngagement +=
          post.likes.length + post.commentsCount + post.shareCount;
    }

    return {
      'totalPosts': feed.length,
      'categories': categories,
      'authors': authors,
      'postsWithImages': postsWithImages,
      'postsWithoutImages': postsWithoutImages,
      'avgEngagement': feed.isNotEmpty ? totalEngagement / feed.length : 0,
      'diversityScore': categories.length / max(1, feed.length),
    };
  }
}
