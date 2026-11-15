import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'posts_provider.dart';

final savedPostsProvider =
    StateNotifierProvider<SavedPostsNotifier, SavedPostsState>((ref) {
      final authState = ref.watch(authProvider);
      return SavedPostsNotifier(authState.user, ref);
    });

final userSavedPostsProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserSavedPostsStream(userId);
});

class SavedPostsState {
  final List<String> savedPostIds;
  final List<PostModel> savedPosts;
  final bool isLoading;
  final String? error;

  SavedPostsState({
    this.savedPostIds = const [],
    this.savedPosts = const [],
    this.isLoading = false,
    this.error,
  });

  SavedPostsState copyWith({
    List<String>? savedPostIds,
    List<PostModel>? savedPosts,
    bool? isLoading,
    String? error,
  }) {
    return SavedPostsState(
      savedPostIds: savedPostIds ?? this.savedPostIds,
      savedPosts: savedPosts ?? this.savedPosts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SavedPostsNotifier extends StateNotifier<SavedPostsState> {
  final UserModel? user;
  final Ref ref;

  SavedPostsNotifier(this.user, this.ref) : super(SavedPostsState()) {
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get saved posts from the posts collection where saves array contains user ID
      final allPosts = await FirestoreService.getAllPosts();
      final savedPosts = allPosts
          .where((post) => post.isSavedBy(user!.uid))
          .toList();
      final savedPostIds = savedPosts.map((post) => post.id).toList();

      state = state.copyWith(
        savedPostIds: savedPostIds,
        savedPosts: savedPosts,
        isLoading: false,
      );

      dev.log(
        '✅ Loaded ${savedPosts.length} saved posts for user: ${user!.uid}',
      );
    } catch (e) {
      dev.log('❌ Error loading saved posts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load saved posts: $e',
      );
    }
  }

  Future<void> savePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Check if already saved
      if (isPostSaved(postId)) {
        dev.log('⚠️ Post already saved: $postId');
        return;
      }

      // Optimistic update - add to saved posts
      final updatedSavedPostIds = [...state.savedPostIds, postId];
      state = state.copyWith(savedPostIds: updatedSavedPostIds);

      // Update the post in the posts provider as well
      ref.read(postsProvider.notifier).savePost(postId);

      // Update in Firestore
      await FirestoreService.savePost(postId, currentUser.uid);

      // Reload saved posts to get the full post data
      await _loadSavedPosts();

      dev.log('✅ Post saved: $postId');
    } catch (e) {
      dev.log('❌ Error saving post: $e');

      // Revert optimistic update on error
      final revertedSavedPostIds = state.savedPostIds
          .where((id) => id != postId)
          .toList();
      state = state.copyWith(
        savedPostIds: revertedSavedPostIds,
        error: 'Failed to save post: $e',
      );
    }
  }

  Future<void> unsavePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Check if actually saved
      if (!isPostSaved(postId)) {
        dev.log('⚠️ Post not saved: $postId');
        return;
      }

      // Optimistic update - remove from saved posts
      final updatedSavedPostIds = state.savedPostIds
          .where((id) => id != postId)
          .toList();
      final updatedSavedPosts = state.savedPosts
          .where((post) => post.id != postId)
          .toList();

      state = state.copyWith(
        savedPostIds: updatedSavedPostIds,
        savedPosts: updatedSavedPosts,
      );

      // Update the post in the posts provider as well
      ref
          .read(postsProvider.notifier)
          .savePost(postId); // This will toggle it off

      // Update in Firestore
      await FirestoreService.unsavePost(postId, currentUser.uid);

      dev.log('✅ Post unsaved: $postId');
    } catch (e) {
      dev.log('❌ Error unsaving post: $e');

      // Revert optimistic update on error
      state = state.copyWith(error: 'Failed to unsave post: $e');
      await _loadSavedPosts(); // Reload to get correct state
    }
  }

  Future<void> toggleSave(String postId) async {
    if (isPostSaved(postId)) {
      await unsavePost(postId);
    } else {
      await savePost(postId);
    }
  }

  bool isPostSaved(String postId) {
    return state.savedPostIds.contains(postId);
  }

  List<PostModel> getSavedPosts() {
    return List.from(state.savedPosts);
  }

  Future<List<PostModel>> getSavedPostsForUser(String userId) async {
    try {
      // Get all posts and filter by saves array
      final allPosts = await FirestoreService.getAllPosts();
      final savedPosts = allPosts
          .where((post) => post.isSavedBy(userId))
          .toList();

      // Sort by creation date (newest first)
      savedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return savedPosts;
    } catch (e) {
      dev.log('❌ Error getting saved posts for user $userId: $e');
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await _loadSavedPosts();
  }

  // Handle post deletion - remove from saved posts if the post is deleted
  void handlePostDeleted(String postId) {
    if (isPostSaved(postId)) {
      final updatedSavedPostIds = state.savedPostIds
          .where((id) => id != postId)
          .toList();
      final updatedSavedPosts = state.savedPosts
          .where((post) => post.id != postId)
          .toList();

      state = state.copyWith(
        savedPostIds: updatedSavedPostIds,
        savedPosts: updatedSavedPosts,
      );

      dev.log('✅ Removed deleted post from saved posts: $postId');
    }
  }

  // Sync with posts provider when posts are updated
  void syncWithPostsProvider(List<PostModel> allPosts) {
    if (user == null) return;

    // Filter posts that are saved by current user
    final savedPosts = allPosts
        .where((post) => post.isSavedBy(user!.uid))
        .toList();
    final savedPostIds = savedPosts.map((post) => post.id).toList();

    // Only update if there are changes
    if (!_listsEqual(savedPostIds, state.savedPostIds)) {
      state = state.copyWith(
        savedPostIds: savedPostIds,
        savedPosts: savedPosts,
      );

      dev.log('✅ Synced saved posts with posts provider');
    }
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
