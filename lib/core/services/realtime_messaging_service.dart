import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import 'socket_service.dart';

class RealtimeMessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SocketService _socketService = SocketService();
  static final _uuid = const Uuid();

  // Collections
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  /// Get or create conversation between two users
  static Future<String> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Create conversation ID (sorted to ensure consistency)
      final participants = [userId1, userId2]..sort();
      final conversationId = '${participants[0]}_${participants[1]}';

      final conversationRef = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId);

      final conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) {
        // Create new conversation
        final conversation = ConversationModel(
          id: conversationId,
          participants: participants,
          lastMessage: '',
          lastMessageSenderId: '',
          lastMessageTime: DateTime.now(),
          unreadCount: {userId1: 0, userId2: 0},
          isTyping: {userId1: false, userId2: false},
          lastSeen: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await conversationRef.set(conversation.toMap());
      }

      return conversationId;
    } catch (e) {
      throw Exception('Failed to get/create conversation: $e');
    }
  }

  /// Send message
  static Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? videoUrl,
    String? replyToId,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        timestamp: now,
        isRead: false,
        isDelivered: false,
        replyToId: replyToId,
      );

      // Save message to Firestore
      await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      // Update conversation
      await _updateConversation(
        chatId: chatId,
        lastMessage: content,
        lastMessageSenderId: senderId,
        lastMessageTime: now,
        receiverId: receiverId,
      );

      // Emit real-time event
      _socketService.emitNewMessage(message.toMap());

      // Mark as delivered immediately (optimistic)
      await markMessageAsDelivered(chatId, messageId);

      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Update conversation after new message
  static Future<void> _updateConversation({
    required String chatId,
    required String lastMessage,
    required String lastMessageSenderId,
    required DateTime lastMessageTime,
    required String receiverId,
  }) async {
    try {
      final conversationRef = _firestore
          .collection(_conversationsCollection)
          .doc(chatId);

      final conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) return;

      final conversation = ConversationModel.fromMap(conversationDoc.data()!);
      final currentUnreadCount = conversation.unreadCount[receiverId] ?? 0;

      await conversationRef.update({
        'lastMessage': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
        'unreadCount.$receiverId': currentUnreadCount + 1,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Get messages stream for a chat
  static Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// Get conversations stream for a user
  static Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// Mark message as delivered
  static Future<void> markMessageAsDelivered(
    String chatId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
            'isDelivered': true,
            'deliveredAt': DateTime.now().millisecondsSinceEpoch,
          });

      // Emit real-time event
      _socketService.emitMessageDelivered(messageId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
            'isRead': true,
            'readAt': DateTime.now().millisecondsSinceEpoch,
          });

      // Emit real-time event
      _socketService.emitMessageRead(messageId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all messages in chat as read
  static Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Get unread messages
      final unreadMessages = await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark all as read
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      await batch.commit();

      // Reset unread count in conversation
      await _firestore.collection(_conversationsCollection).doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      // Emit real-time event
      _socketService.emitChatRead(chatId, userId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Set typing status
  static Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection(_conversationsCollection).doc(chatId).update({
        'isTyping.$userId': isTyping,
      });

      // Emit real-time event
      _socketService.emitTypingStatus(chatId, userId, isTyping);
    } catch (e) {
      // Silently fail
    }
  }

  /// Update last seen
  static Future<void> updateLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection(_conversationsCollection).doc(chatId).update({
        'lastSeen.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete message
  static Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .delete();

      // Emit real-time event
      _socketService.emitMessageDeleted(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get total unread count for user
  static Future<int> getTotalUnreadCount(String userId) async {
    try {
      final conversations = await _firestore
          .collection(_conversationsCollection)
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (final doc in conversations.docs) {
        final conversation = ConversationModel.fromMap(doc.data());
        totalUnread += conversation.getUnreadCount(userId);
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }

  /// Search messages
  static Future<List<MessageModel>> searchMessages(
    String chatId,
    String query,
  ) async {
    try {
      final messages = await _firestore
          .collection(_conversationsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      return messages.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .where(
            (message) =>
                message.content.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}
