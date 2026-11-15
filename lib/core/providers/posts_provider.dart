import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/socket_service.dart';
import '../services/media_upload_service.dart';
import '../services/post_interaction_service.dart';
import '../config/firebase_config.dart';
import 'auth_provider.dart';
import 'user_providers.dart';
import 'notification_provider.dart';

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = PostsNotifier(authState.user, ref, postType: 'media');

  // When user logs in, refresh posts
  ref.listen(authProvider.select((state) => state.user?.uid), (previous, next) {
    if (previous == null && next != null) {
      Future.microtask(() => notifier.fetchPosts());
    } else if (previous != null && next == null) {
      notifier.clearPosts();
    }
  });

  // Listen to media posts stream
  ref.listen(postsStreamProvider, (previous, next) {
    next.whenData((posts) {
      notifier.updatePostsFromStream(posts);
    });
  });

  return notifier;
});



final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return FirestoreService.getPostsStream(limit: 50, postType: 'media');
});



final singlePostProvider = FutureProvider.family<PostModel?, String>((
  ref,
  postId,
) async {
  final postsNotifier = ref.read(postsProvider.notifier);
  return await postsNotifier.getPostById(postId);
});

final singlePostStreamProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  return FirestoreService.getPostStream(postId);
});

final userPostsProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserPostsStream(userId);
});



final archivedPostsProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  userId,
) {
  return FirestoreService.getArchivedPostsStream(userId);
});



class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  PostsState({this.posts = const [], this.isLoading = false, this.error});

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  R when<R>({
    required R Function(List<PostModel> posts) data,
    required R Function() loading,
    required R Function(dynamic error, StackTrace? stackTrace) error,
  }) {
    if (isLoading && posts.isEmpty) return loading();
    if (this.error != null && posts.isEmpty) return error(this.error, null);
    return data(posts);
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final UserModel? user;
  final Ref ref;
  final String? postType;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SocketService _socketService = SocketService();

  PostsNotifier(this.user, this.ref, {this.postType}) : super(PostsState()) {
    _setupSocketListeners();
    fetchPosts(); // Load initial posts
  }

  Future<void> fetchPosts() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final posts = await FirestoreService.getPosts(
        limit: 50,
        postType: postType,
      );

      // Sort posts by createdAt descending (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(isLoading: false, posts: posts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearPosts() {
    state = PostsState(posts: [], isLoading: false);
  }

  void updatePostsFromStream(List<PostModel> posts) {
    // Filter out archived posts and sort by createdAt descending
    final filteredPosts = posts.where((p) => p.isArchived != true).toList();
    filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = state.copyWith(posts: filteredPosts, isLoading: false);
  }

  void _setupSocketListeners() {
    _socketService.onNewPost = (postData) {
      final post = PostModel.fromMap(postData);
      // Avoid duplicate posts
      if (!state.posts.any((p) => p.id == post.id)) {
        final updatedPosts = [post, ...state.posts];
        // Sort to maintain consistency (newest first)
        updatedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(posts: updatedPosts);
      }
    };

    _socketService.onPostUpdate = (postData) {
      final updatedPost = PostModel.fromMap(postData);
      final updatedPosts = state.posts.map((post) {
        return post.id == updatedPost.id ? updatedPost : post;
      }).toList();

      // Maintain sort order after update
      updatedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(posts: updatedPosts);
    };

    // New: Handle real-time likes, shares, and saves
    _socketService.onPostInteraction = (data) {
      final postId = data['postId'] as String;
      final type = data['type'] as String;
      final userId = data['userId'] as String;

      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          if (type == 'like') {
            final newLikes = List<String>.from(post.likes);
            if (newLikes.contains(userId)) {
              newLikes.remove(userId);
            } else {
              newLikes.add(userId);
            }
            return post.copyWith(likes: newLikes);
          } else if (type == 'share') {
            return post.copyWith(shareCount: post.shareCount + 1);
          } else if (type == 'save') {
            if (userId == user?.uid) {
              final newSaves = List<String>.from(post.saves);
              if (newSaves.contains(userId)) {
                newSaves.remove(userId);
              } else {
                newSaves.add(userId);
              }
              return post.copyWith(saves: newSaves);
            }
          }
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    };
  }

  Future<String?> createPost({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
    List<String>? imageUrls,
    dynamic imageFile,
    String postType = 'media',
    bool isDraft = false,
  }) async {
    final currentUser = user;
    if (currentUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      String? uploadedImageUrl;

      // Upload image to Supabase if imageFile is provided
      if (imageFile != null) {
        try {
          final mediaUploadService = MediaUploadService();
          final result = await mediaUploadService.uploadXFile(
            imageFile,
            folder: 'posts/${currentUser.uid}',
            tags: {'type': 'post', 'userId': currentUser.uid},
          );
          uploadedImageUrl = result.secureUrl;
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to upload image: $e',
          );
          return null;
        }
      }

      final post = PostModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        category: category,
        image: uploadedImageUrl ?? imageUrl,
        imageUrls: imageUrls,
        author: currentUser.displayName.isNotEmpty
            ? currentUser.displayName
            : currentUser.email.split('@').first,
        authorId: currentUser.uid,
        authorAvatar: currentUser.photoURL,
        authorUsername: currentUser.username,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        postType: postType,
        isDraft: isDraft,
      );

      // Create a map for Firestore that might include server timestamps
      final postMap = post.toMap();
      // Use server timestamp for better consistency in Firestore
      postMap['createdAt'] = FieldValue.serverTimestamp();
      postMap['updatedAt'] = FieldValue.serverTimestamp();

      dev.log('🚀 Starting post creation: $postType');
      final postId = await _firestore
          .collection(FirebaseConfig.posts)
          .add(postMap)
          .then((doc) => doc.id);
      dev.log('✅ Post doc added: $postId');

      final createdPost = post.copyWith(id: postId);

      // 3. Update User Counts in Firestore (ONLY if not a draft)
      if (!isDraft) {
        final updateData = <String, dynamic>{
          'postsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        dev.log('📈 Updating user counts for ${postType}...');
        
        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(currentUser.uid)
            .set(updateData, SetOptions(merge: true));
            
        dev.log('✅ User counts updated');
  
        // Update local user state
        ref.read(authProvider.notifier).updateUserPostCount(currentUser.postsCount + 1);
      } else {
        dev.log('📝 Post is a draft, skipping count increment');
      }

      // Emit to socket for real-time updates
      _socketService.emitNewPost(createdPost.toMap());

      // Sync stats at the very end to ensure accuracy
      await FirestoreService.syncUserStats(currentUser.uid);

      // Update local state optimisticially
      state = state.copyWith(
        posts: [createdPost, ...state.posts],
        isLoading: false,
      );

      // Force refresh profile-specific providers to ensure "instant" appearance
      ref.invalidate(userPostsProvider(currentUser.uid));
      ref.invalidate(userPostsCountProvider(currentUser.uid));



      // Handle mentions in description before returning
      if (description.isNotEmpty) {
        final mentionRegex = RegExp(r'@(\w+)');
        final matches = mentionRegex.allMatches(description);

        for (final match in matches) {
          final username = match.group(1);
          if (username != null) {
            try {
              final mentionedUser = await FirestoreService.getUserByUsername(
                username,
              );
              if (mentionedUser != null &&
                  mentionedUser.uid != currentUser.uid) {
                ref
                    .read(notificationProvider.notifier)
                    .createMentionNotification(
                      postId: postId,
                      toUserId: mentionedUser.uid,
                      isComment: false,
                    );
              }
            } catch (e) {
              dev.log('❌ Error processing mention for $username: $e');
            }
          }
        }
      }

      dev.log('✨ Post creation complete');
      return postId;
    } catch (e, stack) {
      dev.log('❌ Error in createPost: $e');
      dev.log(stack.toString());
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create post: $e',
      );
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Optimistic update
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          final isLiked = post.isLikedBy(currentUser.uid);
          final newLikes = List<String>.from(post.likes);

          if (isLiked) {
            newLikes.remove(currentUser.uid);
          } else {
            newLikes.add(currentUser.uid);
          }

          return post.copyWith(likes: newLikes);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);

      // Update in Firestore using transaction-based service
      await PostInteractionService.toggleLike(postId, currentUser.uid);

      // Create notification if liked
      final post = updatedPosts.firstWhere((p) => p.id == postId);
      if (post.isLikedBy(currentUser.uid) && currentUser.uid != post.authorId) {
        ref
            .read(notificationProvider.notifier)
            .createLikeNotification(
              postId: post.id,
              postAuthorId: post.authorId,
            );
      }

      // Emit to socket
      _socketService.emitPostInteraction(
        postId: postId,
        type: 'like',
        userId: currentUser.uid,
      );
    } catch (e) {
      dev.log('❌ Error liking post: $e');
      // Revert optimistic update could be done by refetching or manual revert
      state = state.copyWith(error: 'Failed to like post: $e');
    }
  }

  Future<void> savePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Optimistic update
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          final isSaved = post.isSavedBy(currentUser.uid);
          final newSaves = List<String>.from(post.saves);

          if (isSaved) {
            newSaves.remove(currentUser.uid);
          } else {
            newSaves.add(currentUser.uid);
          }

          return post.copyWith(saves: newSaves);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);

      // Update in Firestore using transaction-based service
      await PostInteractionService.toggleSave(postId, currentUser.uid);

      // Emit to socket
      _socketService.emitPostInteraction(
        postId: postId,
        type: 'save',
        userId: currentUser.uid,
      );
    } catch (e) {
      dev.log('❌ Error saving post: $e');
      state = state.copyWith(error: 'Failed to save post: $e');
    }
  }

  // New: Share Post logic
  Future<void> sharePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Optimistic update
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(shareCount: post.shareCount + 1);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);

      // Update in Firestore using transaction-based service
      await PostInteractionService.sharePost(postId, currentUser.uid);

      // Emit to socket
      _socketService.emitPostInteraction(
        postId: postId,
        type: 'share',
        userId: currentUser.uid,
      );
    } catch (e) {
      dev.log('❌ Error sharing post: $e');
      state = state.copyWith(error: 'Failed to share post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 1. Get the post details before deleting to know the type
      final postToDelete = state.posts.firstWhere((p) => p.id == postId);
      final postType = postToDelete.postType;

      await FirestoreService.deletePost(postId);

      // Remove post from local state
      final updatedPosts = state.posts
          .where((post) => post.id != postId)
          .toList();

      // Update counts locally (ONLY if it was not a draft)
      if (postToDelete.isDraft != true) {
        final newPostCount = currentUser.postsCount > 0 ? currentUser.postsCount - 1 : 0;
        ref.read(authProvider.notifier).updateUserPostCount(newPostCount);
      }

      // Sync with Firestore
      await FirestoreService.syncUserStats(currentUser.uid);

      state = state.copyWith(isLoading: false, posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete post: $e',
      );
    }
  }

  Future<void> updatePost({
    required String postId,
    String? title,
    String? description,
    String? category,
    String? visibility,
    dynamic imageFile,
    bool? isDraft,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (visibility != null) updateData['visibility'] = visibility;
      if (isDraft != null) updateData['isDraft'] = isDraft;

      // Handle image update if provided
      String? uploadedImageUrl;
      if (imageFile != null) {
        final mediaUploadService = MediaUploadService();
        final result = await mediaUploadService.uploadXFile(
          imageFile,
          folder: 'posts/${currentUser.uid}',
          tags: {'type': 'post', 'userId': currentUser.uid, 'action': 'update'},
        );
        uploadedImageUrl = result.secureUrl;
        updateData['image'] = uploadedImageUrl;
      }

      // Get old post to check if its draft status is changing
      final oldPost = state.posts.firstWhere((p) => p.id == postId);
      final wasDraft = oldPost.isDraft == true;
      final isNowDraft = isDraft ?? oldPost.isDraft == true;

      await FirestoreService.updatePost(postId, updateData);

      // Handle count update if publication status changed
      if (wasDraft && !isNowDraft) {
        // Post was draft, now published -> Increment count
        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(currentUser.uid)
            .set({
              'postsCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        
        ref.read(authProvider.notifier).updateUserPostCount(currentUser.postsCount + 1);
        
        // Sync to be sure
        await FirestoreService.syncUserStats(currentUser.uid);
      }

      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            title: title ?? post.title,
            description: description ?? post.description,
            category: category ?? post.category,
            visibility: visibility ?? post.visibility,
            image: uploadedImageUrl ?? post.image,
            isDraft: isDraft ?? post.isDraft,
            updatedAt: DateTime.now(),
          );
        }
        return post;
      }).toList();

      state = state.copyWith(isLoading: false, posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update post: $e',
      );
    }
  }

  Future<void> updatePostVisibility(String postId, String visibility) async {
    await updatePost(postId: postId, visibility: visibility);
  }

  Future<void> archivePost(String postId) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      // Optimistic update: Remove from feed since it's now archived
      final updatedPosts = state.posts
          .where((post) => post.id != postId)
          .toList();

      state = state.copyWith(posts: updatedPosts);

      // Backend update
      await PostInteractionService.toggleArchive(postId, currentUser.uid);
    } catch (e) {
      state = state.copyWith(error: 'Failed to archive post: $e');
      // In a real app, you might want to fetch posts again to revert
      fetchPosts();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      final existingPostIndex = state.posts.indexWhere(
        (post) => post.id == postId,
      );
      if (existingPostIndex != -1) {
        return state.posts[existingPostIndex];
      }
    } catch (e) {
      // Post not in current state
    }

    try {
      state = state.copyWith(isLoading: true);

      // Use FirestoreService instead of REST API for consistency and reliability
      final post = await FirestoreService.getPost(postId);

      if (post != null) {
        final updatedPosts = [...state.posts];
        final existingIndex = updatedPosts.indexWhere((p) => p.id == postId);
        if (existingIndex == -1) {
          updatedPosts.add(post);
          state = state.copyWith(posts: updatedPosts);
        }

        state = state.copyWith(isLoading: false);
        return post;
      } else {
        state = state.copyWith(isLoading: false, error: 'Post not found');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch post from Firestore: $e',
      );
    }

    return null;
  }

  void syncUserPostCount() {
    final currentUser = user;
    if (currentUser == null) return;

    final actualPostCount = state.posts
        .where((p) => p.authorId == currentUser.uid)
        .length;

    if (actualPostCount != currentUser.postsCount) {
      FirestoreService.updateUserProfile(currentUser.uid, {
            'postsCount': actualPostCount,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .then((_) {
            ref
                .read(authProvider.notifier)
                .updateUserPostCount(actualPostCount);
          })
          .catchError((e) {
            // Handle error silently
          });
    }
  }
}
