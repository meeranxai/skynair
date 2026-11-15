import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../config/firebase_config.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // text, image, file
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'text',
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'],
    );
  }
}

class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.unreadCounts = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSender': lastMessageSender,
      'unreadCounts': unreadCounts,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSender: map['lastMessageSender'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Chat Management
  static Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      // Create a consistent chat ID
      final participants = [userId1, userId2]..sort();
      final chatId = participants.join('_');

      final chatDoc = await _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        // Create new chat
        final chat = Chat(
          id: chatId,
          participants: participants,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(FirebaseConfig.chats)
            .doc(chatId)
            .set(chat.toMap());

        log('✅ Chat created: $chatId');
      }

      return chatId;
    } catch (e) {
      log('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  static Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Chat.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      log('❌ Error getting chat: $e');
      return null;
    }
  }

  static Stream<List<Chat>> getUserChatsStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.chats)
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Chat.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Message Management
  static Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create message
      final messageRef = _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .collection(FirebaseConfig.messages)
          .doc();

      final message = Message(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      // Use batch to update both message and chat
      final batch = _firestore.batch();

      // Add message
      batch.set(messageRef, message.toMap());

      // Get current chat to safely update unread count
      final chatDoc = await _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .get();
      final currentUnreadCount = chatDoc.exists
          ? (chatDoc.data()?['unreadCounts']?[receiverId] ?? 0) as int
          : 0;

      // Update chat with last message info and increment unread count
      final chatRef = _firestore.collection(FirebaseConfig.chats).doc(chatId);
      batch.update(chatRef, {
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts.$receiverId': currentUnreadCount + 1, // Safe increment
      });

      await batch.commit();
      log('✅ Message sent: ${message.id}');
      return message.id;
    } catch (e) {
      log('❌ Error sending message: $e');
      rethrow;
    }
  }

  static Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection(FirebaseConfig.chats)
        .doc(chatId)
        .collection(FirebaseConfig.messages)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList(),
        );
  }

  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Reset unread count in chat to 0
      await _firestore.collection(FirebaseConfig.chats).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      // Mark messages as read (optional - for detailed read receipts)
      final batch = _firestore.batch();
      final unreadMessages = await _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .collection(FirebaseConfig.messages)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(50) // Limit to prevent large batch operations
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }

      log(
        '✅ Messages marked as read for user: $userId (${unreadMessages.docs.length} messages)',
      );
    } catch (e) {
      log('❌ Error marking messages as read: $e');
      // Don't rethrow - this is not critical for app functionality
    }
  }

  static Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(FirebaseConfig.chats)
          .doc(chatId)
          .collection(FirebaseConfig.messages)
          .doc(messageId)
          .delete();
      log('✅ Message deleted: $messageId');
    } catch (e) {
      log('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // Utility methods
  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      final chats = await _firestore
          .collection(FirebaseConfig.chats)
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (final doc in chats.docs) {
        final chat = Chat.fromMap(doc.data());
        totalUnread += chat.unreadCounts[userId] ?? 0;
      }

      return totalUnread;
    } catch (e) {
      log('❌ Error getting unread count: $e');
      return 0;
    }
  }

  static Stream<int> getUnreadMessageCountStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.chats)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            final chat = Chat.fromMap(doc.data());
            totalUnread += chat.unreadCounts[userId] ?? 0;
          }
          return totalUnread;
        });
  }
}
