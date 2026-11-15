import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import '../models/comment_model.dart';

class CommentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comments for a post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => _commentFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  // Get comments stream for real-time updates
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _commentFromFirestore(doc)).toList(),
        );
  }

  // Add a new comment
  Future<CommentModel> addComment({
    required String postId,
    required String content,
    required String authorId,
    required String author,
    String? authorUsername,
    String? authorAvatar,
    String? parentCommentId,
  }) async {
    try {
      final now = DateTime.now();
      final commentData = {
        'postId': postId,
        'content': content,
        'authorId': authorId,
        'author': author,
        'authorUsername': authorUsername,
        'authorAvatar': authorAvatar,
        'likes': <String>[],
        'parentCommentId': parentCommentId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isEdited': false,
      };

      final docRef = await _firestore.collection('comments').add(commentData);

      // Update post comment count
      await _updatePostCommentCount(postId, 1);

      // Return CommentModel directly instead of using fromJson with DateTime objects
      return CommentModel(
        id: docRef.id,
        postId: postId,
        content: content,
        authorId: authorId,
        author: author,
        authorUsername: authorUsername,
        authorAvatar: authorAvatar,
        likes: const <String>[],
        parentCommentId: parentCommentId,
        createdAt: now,
        updatedAt: now,
        isEdited: false,
      );
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Update a comment
  Future<void> updateComment(String commentId, String newContent) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'content': newContent,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isEdited': true,
      });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      // Get comment data first to get postId
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();
      if (!commentDoc.exists) return;

      final commentData = commentDoc.data()!;
      final postId = commentData['postId'] as String;

      // Delete the comment
      await _firestore.collection('comments').doc(commentId).delete();

      // Delete all replies to this comment
      final repliesQuery = await _firestore
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .get();

      final batch = _firestore.batch();
      for (final reply in repliesQuery.docs) {
        batch.delete(reply.reference);
      }
      await batch.commit();

      // Update post comment count
      final totalDeleted = 1 + repliesQuery.docs.length;
      await _updatePostCommentCount(postId, -totalDeleted);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) return;

        final commentData = commentDoc.data()!;
        final likes = List<String>.from(commentData['likes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        transaction.update(commentRef, {
          'likes': likes,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Get comment by ID
  Future<CommentModel?> getComment(String commentId) async {
    try {
      final doc = await _firestore.collection('comments').doc(commentId).get();
      if (!doc.exists) return null;

      return _commentFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get comment: $e');
    }
  }

  // Get replies for a comment
  Future<List<CommentModel>> getReplies(String parentCommentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => _commentFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load replies: $e');
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get comment count: $e');
    }
  }

  // Report a comment
  Future<void> reportComment(String commentId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'type': 'comment',
        'targetId': commentId,
        'reason': reason,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }

  // Private helper to update post comment count
  Future<void> _updatePostCommentCount(String postId, int increment) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['commentsCount'] ?? 0;
        final newCount = (currentCount + increment)
            .clamp(0, double.infinity)
            .toInt();

        transaction.update(postRef, {
          'commentsCount': newCount,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      // Don't throw here as it's a secondary operation
      log('Failed to update post comment count: $e');
    }
  }

  // Batch operations for better performance
  Future<void> batchDeleteComments(List<String> commentIds) async {
    try {
      final batch = _firestore.batch();

      for (final commentId in commentIds) {
        batch.delete(_firestore.collection('comments').doc(commentId));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch delete comments: $e');
    }
  }

  // Get user's comments
  Future<List<CommentModel>> getUserComments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _commentFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user comments: $e');
    }
  }

  // Search comments
  Future<List<CommentModel>> searchComments(
    String query, {
    String? postId,
  }) async {
    try {
      Query commentsQuery = _firestore.collection('comments');

      if (postId != null) {
        commentsQuery = commentsQuery.where('postId', isEqualTo: postId);
      }

      final querySnapshot = await commentsQuery
          .orderBy('createdAt', descending: true)
          .get();

      // Filter by content (Firestore doesn't support full-text search natively)
      final filteredComments = querySnapshot.docs
          .where((doc) {
            final content = doc.data() as Map<String, dynamic>;
            return content['content'].toString().toLowerCase().contains(
              query.toLowerCase(),
            );
          })
          .map((doc) => _commentFromFirestore(doc))
          .toList();

      return filteredComments;
    } catch (e) {
      throw Exception('Failed to search comments: $e');
    }
  }

  // Helper method to convert Firestore document to CommentModel
  CommentModel _commentFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely convert Firestore Timestamps to DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return DateTime.now(); // Fallback
    }

    // Safely get string values
    String getString(String key, [String defaultValue = '']) {
      final value = data[key];
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Safely get nullable string values
    String? getNullableString(String key) {
      final value = data[key];
      if (value == null) return null;
      return value.toString();
    }

    // Safely get list values
    List<String> getStringList(String key) {
      final value = data[key];
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Safely get boolean values
    bool getBool(String key, [bool defaultValue = false]) {
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is bool) return value;
      return defaultValue;
    }

    return CommentModel(
      id: doc.id,
      postId: getString('postId'),
      content: getString('content'),
      authorId: getString('authorId'),
      author: getString('author'),
      authorUsername: getNullableString('authorUsername'),
      authorAvatar: getNullableString('authorAvatar'),
      likes: getStringList('likes'),
      parentCommentId: getNullableString('parentCommentId'),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      isEdited: getBool('isEdited'),
    );
  }
}
