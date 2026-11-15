import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/messaging_service.dart';
import '../services/socket_service.dart';
import '../services/blocking_service.dart';
import 'auth_provider.dart';

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
      final authState = ref.watch(authProvider);
      return MessagingNotifier(authState.user?.uid);
    });

final userChatsProvider = StreamProvider.family<List<Chat>, String>((
  ref,
  userId,
) {
  return MessagingService.getUserChatsStream(userId);
});

final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  return MessagingService.getMessagesStream(chatId);
});

final unreadMessagesCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return MessagingService.getUnreadMessageCountStream(userId);
});

class MessagingState {
  final List<Chat> chats;
  final Map<String, List<Message>> messages;
  final bool isLoading;
  final String? error;

  MessagingState({
    this.chats = const [],
    this.messages = const {},
    this.isLoading = false,
    this.error,
  });

  MessagingState copyWith({
    List<Chat>? chats,
    Map<String, List<Message>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessagingState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final String? _currentUserId;
  final SocketService _socketService = SocketService();

  MessagingNotifier(this._currentUserId) : super(MessagingState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onNewMessage = (messageData) {
      final message = Message.fromMap(messageData);
      _addMessageToState(message);
    };
  }

  void _addMessageToState(Message message) {
    final currentMessages = state.messages[message.chatId] ?? [];
    final updatedMessages = [message, ...currentMessages];

    state = state.copyWith(
      messages: {...state.messages, message.chatId: updatedMessages},
    );
  }

  Future<String> createOrGetChat(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Check for blocks
      final isBlocked = await BlockingService.isEitherBlocked(currentUserId, otherUserId);
      if (isBlocked) {
        throw 'You cannot message this user.';
      }

      final chatId = await MessagingService.createOrGetChat(
        currentUserId,
        otherUserId,
      );

      state = state.copyWith(isLoading: false);
      return chatId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      // Check for blocks
      final isBlocked = await BlockingService.isEitherBlocked(currentUserId, receiverId);
      if (isBlocked) {
        throw 'You cannot message this user.';
      }

      // Create temp message for optimistic update
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      _addMessageToState(tempMessage);

      // Send message to server
      final messageId = await MessagingService.sendMessage(
        chatId: chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        type: type,
        metadata: metadata,
      );

      // Emit to socket for real-time delivery
      _socketService.emitSendMessage({
        'chatId': chatId,
        'senderId': currentUserId,
        'receiverId': receiverId,
        'content': content,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
      });

      // Replace temp message with real message
      final currentMessages = state.messages[chatId] ?? [];
      final updatedMessages = currentMessages.map((msg) {
        if (msg.id == tempMessage.id) {
          return tempMessage.copyWith(id: messageId);
        }
        return msg;
      }).toList();

      state = state.copyWith(
        messages: {...state.messages, chatId: updatedMessages},
      );
    } catch (e) {
      // Remove temp message on error
      final currentMessages = state.messages[chatId] ?? [];
      final updatedMessages = currentMessages
          .where((msg) => !msg.id.startsWith('temp_'))
          .toList();

      state = state.copyWith(
        messages: {...state.messages, chatId: updatedMessages},
        error: 'Failed to send message: $e',
      );
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    try {
      await MessagingService.markMessagesAsRead(chatId, currentUserId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark messages as read: $e');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await MessagingService.deleteMessage(chatId, messageId);

      // Remove message from local state
      final currentMessages = state.messages[chatId] ?? [];
      final updatedMessages = currentMessages
          .where((msg) => msg.id != messageId)
          .toList();

      state = state.copyWith(
        messages: {...state.messages, chatId: updatedMessages},
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message: $e');
    }
  }

  void startTyping(String chatId, String receiverId) {
    final currentUserId = _currentUserId;
    if (currentUserId != null) {
      _socketService.emitTyping(chatId, currentUserId);
    }
  }

  void stopTyping(String chatId, String receiverId) {
    final currentUserId = _currentUserId;
    if (currentUserId != null) {
      _socketService.emitStopTyping(chatId, currentUserId);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Extension to add copyWith method to Message
extension MessageCopyWith on Message {
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
