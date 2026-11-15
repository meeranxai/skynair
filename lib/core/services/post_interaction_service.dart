import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../config/firebase_config.dart';
import '../models/post_model.dart';

class PostInteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Like/Unlike post
  static Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw 'Post not found';
        }

        final post = PostModel.fromMap(postDoc.data()!);
        final likes = List<String>.from(post.likes);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        transaction.update(postRef, {
          'likes': likes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      log('✅ Post like toggled: $postId by $userId');
    } catch (e) {
      log('❌ Error toggling like: $e');
      rethrow;
    }
  }

  // Save/Unsave post
  static Future<void> toggleSave(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw 'Post not found';
        }

        final post = PostModel.fromMap(postDoc.data()!);
        final saves = List<String>.from(post.saves);

        if (saves.contains(userId)) {
          saves.remove(userId);
        } else {
          saves.add(userId);
        }

        transaction.update(postRef, {
          'saves': saves,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      log('✅ Post save toggled: $postId by $userId');
    } catch (e) {
      log('❌ Error toggling save: $e');
      rethrow;
    }
  }

  // Share post (increment share count) - Fixed to prevent multiple increments
  static Future<void> sharePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);
      final shareRef = _firestore
          .collection('post_shares')
          .doc('${postId}_$userId');

      await _firestore.runTransaction((transaction) async {
        // Check if user already shared this post
        final shareDoc = await transaction.get(shareRef);

        if (shareDoc.exists) {
          // User already shared this post, don't increment again
          log('⚠️ Post already shared by user: $postId by $userId');
          return;
        }

        // Create share record
        transaction.set(shareRef, {
          'postId': postId,
          'userId': userId,
          'sharedAt': FieldValue.serverTimestamp(),
        });

        // Increment share count
        transaction.update(postRef, {
          'shareCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      log('✅ Post shared: $postId by $userId');
    } catch (e) {
      log('❌ Error sharing post: $e');
      rethrow;
    }
  }

  // Report post
  static Future<void> reportPost(
    String postId,
    String userId,
    String reason,
  ) async {
    try {
      final reportRef = _firestore.collection('reports').doc();

      await reportRef.set({
        'postId': postId,
        'reportedBy': userId,
        'reason': reason,
        'type': 'post',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('✅ Post reported: $postId by $userId');
    } catch (e) {
      log('❌ Error reporting post: $e');
      rethrow;
    }
  }

  // Block user
  static Future<void> blockUser(
    String currentUserId,
    String blockedUserId,
  ) async {
    try {
      final blockRef = _firestore
          .collection('blocks')
          .doc('${currentUserId}_$blockedUserId');

      await blockRef.set({
        'blockerId': currentUserId,
        'blockedId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('✅ User blocked: $blockedUserId by $currentUserId');
    } catch (e) {
      log('❌ Error blocking user: $e');
      rethrow;
    }
  }

  // Mute user
  static Future<void> muteUser(String currentUserId, String mutedUserId) async {
    try {
      final muteRef = _firestore
          .collection('mutes')
          .doc('${currentUserId}_$mutedUserId');

      await muteRef.set({
        'muterId': currentUserId,
        'mutedId': mutedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('✅ User muted: $mutedUserId by $currentUserId');
    } catch (e) {
      log('❌ Error muting user: $e');
      rethrow;
    }
  }

  // Delete post (owner only)
  static Future<void> deletePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      // Verify ownership
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw 'Post not found';
      }

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != userId) {
        throw 'Unauthorized: Only post owner can delete';
      }

      await postRef.delete();

      // Update user's post count
      final userRef = _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId);
      await userRef.update({
        'postsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Post deleted: $postId by $userId');
    } catch (e) {
      log('❌ Error deleting post: $e');
      rethrow;
    }
  }

  // Update post visibility (owner only)
  static Future<void> updatePostVisibility(
    String postId,
    String userId,
    String visibility,
  ) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      // Verify ownership
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw 'Post not found';
      }

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != userId) {
        throw 'Unauthorized: Only post owner can update visibility';
      }

      await postRef.update({
        'visibility': visibility,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Post visibility updated: $postId to $visibility');
    } catch (e) {
      log('❌ Error updating post visibility: $e');
      rethrow;
    }
  }

  // Update post content (owner only)
  static Future<void> updatePost(
    String postId,
    String userId, {
    String? title,
    String? description,
    String? category,
  }) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      // Verify ownership
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw 'Post not found';
      }

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != userId) {
        throw 'Unauthorized: Only post owner can update post';
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;

      await postRef.update(updates);

      log('✅ Post updated: $postId by $userId');
    } catch (e) {
      log('❌ Error updating post: $e');
      rethrow;
    }
  }

  // Get post insights (owner only)
  static Future<Map<String, dynamic>> getPostInsights(
    String postId,
    String userId,
  ) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      // Verify ownership
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw 'Post not found';
      }

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != userId) {
        throw 'Unauthorized: Only post owner can view insights';
      }

      // Calculate insights
      final insights = {
        'totalLikes': post.likes.length,
        'totalSaves': post.saves.length,
        'totalShares': post.shareCount,
        'totalComments': post.commentsCount,
        'engagement':
            (post.likes.length +
            post.saves.length +
            post.shareCount +
            post.commentsCount),
        'createdAt': post.createdAt.toIso8601String(),
        'daysSinceCreated': DateTime.now().difference(post.createdAt).inDays,
      };

      log('✅ Post insights retrieved: $postId');
      return insights;
    } catch (e) {
      log('❌ Error getting post insights: $e');
      rethrow;
    }
  }

  // Toggle post archive status (owner only)
  static Future<void> toggleArchive(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);

      // Verify ownership
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw 'Post not found';
      }

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != userId) {
        throw 'Unauthorized: Only post owner can archive';
      }

      await postRef.update({
        'isArchived': !post.isArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Post archive toggled: $postId to ${!post.isArchived}');
    } catch (e) {
      log('❌ Error toggling post archive: $e');
      rethrow;
    }
  }
}
