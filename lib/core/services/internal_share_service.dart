import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';
import 'realtime_messaging_service.dart';
import 'socket_service.dart';

class InternalShareService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SocketService _socketService = SocketService();
  static const _uuid = Uuid();

  /// Share post to user via DM
  static Future<void> sharePostToUser({
    required PostModel post,
    required String senderId,
    required String receiverId,
    String? message,
  }) async {
    try {
      // Get or create conversation
      final chatId = await RealtimeMessagingService.getOrCreateConversation(
        senderId,
        receiverId,
      );

      // Create share message content
      final shareContent = _createShareMessageContent(post, message);

      // Send message with post metadata
      await RealtimeMessagingService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: shareContent,
        type: MessageType.text,
      );

      // Increment share count
      await _incrementShareCount(post.id);

      // Emit socket event
      _socketService.emitPostInteraction(
        postId: post.id,
        type: 'share',
        userId: senderId,
      );
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Share post to multiple users
  static Future<void> sharePostToMultipleUsers({
    required PostModel post,
    required String senderId,
    required List<String> receiverIds,
    String? message,
  }) async {
    try {
      for (final receiverId in receiverIds) {
        await sharePostToUser(
          post: post,
          senderId: senderId,
          receiverId: receiverId,
          message: message,
        );
      }
    } catch (e) {
      throw Exception('Failed to share to multiple users: $e');
    }
  }

  /// Repost (share to own feed)
  static Future<String> repost({
    required PostModel originalPost,
    required String userId,
    String? comment,
  }) async {
    try {
      final repostId = _uuid.v4();
      final now = DateTime.now();

      // Create repost document
      final repost = {
        'id': repostId,
        'originalPostId': originalPost.id,
        'originalAuthorId': originalPost.authorId,
        'originalAuthorName': originalPost.authorName,
        'userId': userId,
        'comment': comment ?? '',
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      await _firestore.collection('reposts').doc(repostId).set(repost);

      // Increment share count
      await _incrementShareCount(originalPost.id);

      // Emit socket event
      _socketService.emitPostInteraction(
        postId: originalPost.id,
        type: 'repost',
        userId: userId,
      );

      return repostId;
    } catch (e) {
      throw Exception('Failed to repost: $e');
    }
  }

  /// Quote post (repost with comment)
  static Future<String> quotePost({
    required PostModel originalPost,
    required String userId,
    required String comment,
  }) async {
    return await repost(
      originalPost: originalPost,
      userId: userId,
      comment: comment,
    );
  }

  /// Get users who shared a post
  static Future<List<String>> getPostSharers(String postId) async {
    try {
      final reposts = await _firestore
          .collection('reposts')
          .where('originalPostId', isEqualTo: postId)
          .get();

      return reposts.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if user has reposted
  static Future<bool> hasUserReposted(String postId, String userId) async {
    try {
      final repost = await _firestore
          .collection('reposts')
          .where('originalPostId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return repost.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Delete repost
  static Future<void> deleteRepost(String postId, String userId) async {
    try {
      final repost = await _firestore
          .collection('reposts')
          .where('originalPostId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (repost.docs.isNotEmpty) {
        await repost.docs.first.reference.delete();

        // Decrement share count
        await _decrementShareCount(postId);
      }
    } catch (e) {
      throw Exception('Failed to delete repost: $e');
    }
  }

  /// Create share message content
  static String _createShareMessageContent(PostModel post, String? message) {
    final buffer = StringBuffer();

    if (message != null && message.isNotEmpty) {
      buffer.writeln(message);
      buffer.writeln();
    }

    buffer.writeln('📤 Shared a post:');
    buffer.writeln();

    if (post.title.isNotEmpty) {
      buffer.writeln('📝 ${post.title}');
    }

    if (post.description.isNotEmpty) {
      final preview = post.description.length > 100
          ? '${post.description.substring(0, 100)}...'
          : post.description;
      buffer.writeln(preview);
    }

    buffer.writeln();
    buffer.writeln('👤 By ${post.authorName}');
    buffer.writeln('❤️ ${post.likes.length} likes');

    return buffer.toString();
  }

  /// Increment share count
  static Future<void> _incrementShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Decrement share count
  static Future<void> _decrementShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shareCount': FieldValue.increment(-1),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Get share analytics
  static Future<Map<String, dynamic>> getShareAnalytics(String postId) async {
    try {
      final reposts = await _firestore
          .collection('reposts')
          .where('originalPostId', isEqualTo: postId)
          .get();

      final messages = await _firestore
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: '📤 Shared a post:')
          .get();

      return {
        'repostCount': reposts.docs.length,
        'dmShareCount': messages.docs.length,
        'totalShares': reposts.docs.length + messages.docs.length,
      };
    } catch (e) {
      return {'repostCount': 0, 'dmShareCount': 0, 'totalShares': 0};
    }
  }
}
