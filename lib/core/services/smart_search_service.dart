import 'dart:math';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// Smart Search Service with AI-powered fuzzy matching and ranking
class SmartSearchService {
  /// Calculate Levenshtein distance (edit distance) between two strings
  /// Used for fuzzy matching - how many edits needed to transform one string to another
  static int _levenshteinDistance(String s1, String s2) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(min(v1[j] + 1, v0[j + 1] + 1), v0[j] + cost);
      }

      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  /// 1.0 = perfect match, 0.0 = completely different
  static double _similarityScore(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = max(s1.length, s2.length);
    return 1.0 - (distance / maxLength);
  }

  /// Check if query matches text with fuzzy matching
  /// Returns score from 0.0 to 1.0
  static double _fuzzyMatch(String query, String text) {
    query = query.toLowerCase().trim();
    text = text.toLowerCase().trim();

    if (query.isEmpty) return 0.0;
    if (text.isEmpty) return 0.0;

    // Exact match - highest score
    if (text == query) return 1.0;

    // Contains query - high score
    if (text.contains(query)) {
      // Score based on position (earlier = better)
      final position = text.indexOf(query);
      final positionScore = 1.0 - (position / text.length);
      return 0.9 + (positionScore * 0.1);
    }

    // Check if query words are in text
    final queryWords = query.split(' ');
    final textWords = text.split(' ');

    double wordMatchScore = 0.0;
    int matchedWords = 0;

    for (final queryWord in queryWords) {
      double bestWordScore = 0.0;

      for (final textWord in textWords) {
        // Exact word match
        if (textWord == queryWord) {
          bestWordScore = 1.0;
          break;
        }

        // Word starts with query
        if (textWord.startsWith(queryWord)) {
          bestWordScore = max(bestWordScore, 0.8);
        }

        // Fuzzy word match
        final similarity = _similarityScore(queryWord, textWord);
        if (similarity > 0.7) {
          bestWordScore = max(bestWordScore, similarity * 0.7);
        }
      }

      if (bestWordScore > 0.5) {
        matchedWords++;
        wordMatchScore += bestWordScore;
      }
    }

    if (matchedWords > 0) {
      return (wordMatchScore / queryWords.length) * 0.8;
    }

    // Character-level fuzzy matching as fallback
    final similarity = _similarityScore(query, text);
    if (similarity > 0.6) {
      return similarity * 0.5;
    }

    return 0.0;
  }

  /// Search posts with intelligent ranking
  static List<PostModel> searchPosts(String query, List<PostModel> posts) {
    if (query.trim().isEmpty) return posts;

    final results = <({PostModel post, double score})>[];

    for (final post in posts) {
      double score = 0.0;

      // Search in description (highest weight)
      if (post.description.isNotEmpty) {
        final descScore = _fuzzyMatch(query, post.description);
        score += descScore * 3.0; // 3x weight for description
      }

      // Search in title (high weight)
      if (post.title.isNotEmpty) {
        final titleScore = _fuzzyMatch(query, post.title);
        score += titleScore * 2.5; // 2.5x weight for title
      }

      // Search in author name (medium weight)
      if (post.authorName.isNotEmpty) {
        final authorScore = _fuzzyMatch(query, post.authorName);
        score += authorScore * 1.5; // 1.5x weight for author
      }

      // Search in category (medium weight)
      if (post.category.isNotEmpty) {
        final categoryScore = _fuzzyMatch(query, post.category);
        score += categoryScore * 2.0; // 2x weight for category
      }

      // Extract hashtags from description
      final hashtags = _extractHashtagsFromText(post.description);
      for (final tag in hashtags) {
        final tagScore = _fuzzyMatch(query, tag);
        if (tagScore > 0.5) {
          score += tagScore * 2.0; // 2x weight for hashtags
        }
      }

      // Boost recent posts slightly
      final daysSincePost = DateTime.now().difference(post.createdAt).inDays;
      final recencyBoost = max(0.0, 1.0 - (daysSincePost / 30.0)) * 0.2;
      score += recencyBoost;

      // Boost popular posts slightly
      final popularityBoost = min(1.0, post.likes.length / 100.0) * 0.3;
      score += popularityBoost;

      // Only include if score is above threshold
      if (score > 0.3) {
        results.add((post: post, score: score));
      }
    }

    // Sort by score (highest first)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((r) => r.post).toList();
  }

  /// Extract hashtags from text
  static List<String> _extractHashtagsFromText(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Search users with intelligent ranking
  static List<UserModel> searchUsers(String query, List<UserModel> users) {
    if (query.trim().isEmpty) return users;

    final results = <({UserModel user, double score})>[];

    for (final user in users) {
      double score = 0.0;

      // Search in username (highest weight)
      final usernameScore = _fuzzyMatch(query, user.username);
      score += usernameScore * 3.0;

      // Search in display name (high weight)
      final displayNameScore = _fuzzyMatch(query, user.displayName);
      score += displayNameScore * 2.5;

      // Search in bio (medium weight)
      if (user.bio?.isNotEmpty == true) {
        final bioScore = _fuzzyMatch(query, user.bio!);
        score += bioScore * 1.5;
      }

      // Boost verified users
      if (user.isVerified) {
        score += 0.5;
      }

      // Boost users with more followers
      final followerBoost = min(1.0, user.followersCount / 1000.0) * 0.3;
      score += followerBoost;

      // Only include if score is above threshold
      if (score > 0.3) {
        results.add((user: user, score: score));
      }
    }

    // Sort by score (highest first)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((r) => r.user).toList();
  }

  /// Extract and rank hashtags from query
  static List<String> extractHashtags(String query) {
    final words = query.toLowerCase().split(' ');
    final hashtags = <String>[];

    for (final word in words) {
      if (word.startsWith('#')) {
        hashtags.add(word.substring(1));
      } else if (word.isNotEmpty) {
        hashtags.add(word);
      }
    }

    return hashtags;
  }

  /// Get search suggestions based on query
  static List<String> getSearchSuggestions(
    String query,
    List<PostModel> posts,
    List<UserModel> users,
  ) {
    final suggestions = <String>{};

    if (query.length < 2) return [];

    // Add matching usernames
    for (final user in users.take(50)) {
      if (user.username.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add('@${user.username}');
      }
      if (user.displayName.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(user.displayName);
      }
    }

    // Add matching hashtags from posts
    for (final post in posts.take(100)) {
      final hashtags = _extractHashtagsFromText(post.description);
      for (final tag in hashtags) {
        if (tag.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add('#$tag');
        }
      }
    }

    // Add matching categories
    for (final post in posts.take(50)) {
      if (post.category.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(post.category);
      }
    }

    return suggestions.take(10).toList();
  }

  /// Highlight matching text in search results
  static List<TextSpan> highlightMatches(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int currentIndex = 0;

    while (currentIndex < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add remaining text
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }

      // Add text before match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, matchIndex)));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xFFFFEB3B), // Yellow highlight
          ),
        ),
      );

      currentIndex = matchIndex + query.length;
    }

    return spans;
  }
}
