import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/post_interaction_service.dart';
import '../services/blocking_service.dart';
import 'auth_provider.dart';

final postInteractionProvider =
    StateNotifierProvider<PostInteractionNotifier, PostInteractionState>((ref) {
      final authState = ref.watch(authProvider);
      return PostInteractionNotifier(authState.user?.uid);
    });

class PostInteractionState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> likedPosts;
  final Map<String, bool> savedPosts;
  final Map<String, bool> mutedUsers;
  final Map<String, bool> blockedUsers;

  PostInteractionState({
    this.isLoading = false,
    this.error,
    this.likedPosts = const {},
    this.savedPosts = const {},
    this.mutedUsers = const {},
    this.blockedUsers = const {},
  });

  PostInteractionState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? likedPosts,
    Map<String, bool>? savedPosts,
    Map<String, bool>? mutedUsers,
    Map<String, bool>? blockedUsers,
  }) {
    return PostInteractionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      likedPosts: likedPosts ?? this.likedPosts,
      savedPosts: savedPosts ?? this.savedPosts,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}

class PostInteractionNotifier extends StateNotifier<PostInteractionState> {
  final String? _currentUserId;

  PostInteractionNotifier(this._currentUserId) : super(PostInteractionState());

  // Toggle like with optimistic update
  Future<void> toggleLike(String postId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      final currentLiked = state.likedPosts[postId] ?? false;
      state = state.copyWith(
        likedPosts: {...state.likedPosts, postId: !currentLiked},
      );

      await PostInteractionService.toggleLike(postId, _currentUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert optimistic update on error
      final currentLiked = state.likedPosts[postId] ?? false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle like: $e',
        likedPosts: {...state.likedPosts, postId: !currentLiked},
      );
    }
  }

  // Toggle save with optimistic update
  Future<void> toggleSave(String postId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      final currentSaved = state.savedPosts[postId] ?? false;
      state = state.copyWith(
        savedPosts: {...state.savedPosts, postId: !currentSaved},
      );

      await PostInteractionService.toggleSave(postId, _currentUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert optimistic update on error
      final currentSaved = state.savedPosts[postId] ?? false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle save: $e',
        savedPosts: {...state.savedPosts, postId: !currentSaved},
      );
    }
  }

  // Share post
  Future<void> sharePost(String postId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await PostInteractionService.sharePost(postId, _currentUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to share post: $e',
      );
    }
  }

  // Report post
  Future<void> reportPost(String postId, String reason) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await PostInteractionService.reportPost(postId, _currentUserId, reason);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to report post: $e',
      );
    }
  }

  // Block user
  Future<void> blockUser(String userId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      state = state.copyWith(
        blockedUsers: {...state.blockedUsers, userId: true},
      );

      // Import BlockingService if needed, but it's likely better to keep logic centralized
      await BlockingService.blockUser(_currentUserId, userId);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert optimistic update on error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to block user: $e',
        blockedUsers: {...state.blockedUsers, userId: false},
      );
    }
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      state = state.copyWith(
        blockedUsers: {...state.blockedUsers, userId: false},
      );

      await BlockingService.unblockUser(_currentUserId, userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert optimistic update on error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unblock user: $e',
        blockedUsers: {...state.blockedUsers, userId: true},
      );
    }
  }

  // Mute user
  Future<void> muteUser(String userId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      state = state.copyWith(mutedUsers: {...state.mutedUsers, userId: true});

      await PostInteractionService.muteUser(_currentUserId, userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert optimistic update on error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to mute user: $e',
        mutedUsers: {...state.mutedUsers, userId: false},
      );
    }
  }

  // Delete post (owner only)
  Future<void> deletePost(String postId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await PostInteractionService.deletePost(postId, _currentUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete post: $e',
      );
    }
  }

  // Update post visibility (owner only)
  Future<void> updatePostVisibility(String postId, String visibility) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await PostInteractionService.updatePostVisibility(
        postId,
        _currentUserId,
        visibility,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update post visibility: $e',
      );
    }
  }

  // Update post content (owner only)
  Future<void> updatePost(
    String postId, {
    String? title,
    String? description,
    String? category,
  }) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await PostInteractionService.updatePost(
        postId,
        _currentUserId,
        title: title,
        description: description,
        category: category,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update post: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider to get post insights (owner only)
final postInsightsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, postId) async {
      final authState = ref.watch(authProvider);
      final currentUserId = authState.user?.uid;

      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      return PostInteractionService.getPostInsights(postId, currentUserId);
    });
