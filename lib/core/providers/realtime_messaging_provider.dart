import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/realtime_messaging_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

// Conversations stream provider
final conversationsProvider =
    StreamProvider.autoDispose<List<ConversationModel>>((ref) {
      final currentUser = ref.watch(authProvider).user;
      if (currentUser == null) {
        return Stream.value([]);
      }
      return RealtimeMessagingService.getConversationsStream(currentUser.uid);
    });

// Messages stream provider for a specific chat
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, chatId) {
      return RealtimeMessagingService.getMessagesStream(chatId);
    });

// Total unread count provider
final totalUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final currentUser = ref.watch(authProvider).user;
  if (currentUser == null) return 0;
  return RealtimeMessagingService.getTotalUnreadCount(currentUser.uid);
});

// Messaging state notifier
final realtimeMessagingProvider =
    StateNotifierProvider<RealtimeMessagingNotifier, RealtimeMessagingState>((
      ref,
    ) {
      final authState = ref.watch(authProvider);
      return RealtimeMessagingNotifier(authState.user?.uid, ref);
    });

class RealtimeMessagingState {
  final Map<String, bool> typingStatus; // chatId -> isTyping
  final Map<String, DateTime> lastSeen; // userId -> lastSeen
  final bool isLoading;
  final String? error;

  RealtimeMessagingState({
    this.typingStatus = const {},
    this.lastSeen = const {},
    this.isLoading = false,
    this.error,
  });

  RealtimeMessagingState copyWith({
    Map<String, bool>? typingStatus,
    Map<String, DateTime>? lastSeen,
    bool? isLoading,
    String? error,
  }) {
    return RealtimeMessagingState(
      typingStatus: typingStatus ?? this.typingStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isUserTyping(String chatId) {
    return typingStatus[chatId] ?? false;
  }

  DateTime? getUserLastSeen(String userId) {
    return lastSeen[userId];
  }
}

class RealtimeMessagingNotifier extends StateNotifier<RealtimeMessagingState> {
  final String? _currentUserId;
  final Ref _ref;
  final SocketService _socketService = SocketService();
  Timer? _typingTimer;

  RealtimeMessagingNotifier(this._currentUserId, this._ref)
    : super(RealtimeMessagingState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _socketService.onNewMessage = (messageData) {
      // Messages are handled by stream provider
      // Just refresh conversations if needed
      _ref.invalidate(conversationsProvider);
    };

    // Listen for typing status
    _socketService.onTyping = (data) {
      final chatId = data['chatId'] as String;
      final userId = data['userId'] as String;

      // Only update if it's not the current user typing
      if (userId != _currentUserId) {
        state = state.copyWith(
          typingStatus: {...state.typingStatus, chatId: true},
        );

        // Auto-clear typing status after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            state = state.copyWith(
              typingStatus: {...state.typingStatus, chatId: false},
            );
          }
        });
      }
    };

    // Listen for stop typing
    _socketService.onStopTyping = (data) {
      final chatId = data['chatId'] as String;
      state = state.copyWith(
        typingStatus: {...state.typingStatus, chatId: false},
      );
    };

    // Listen for user online/offline
    _socketService.onUserOnline = (data) {
      final userId = data['userId'] as String;
      state = state.copyWith(
        lastSeen: {...state.lastSeen, userId: DateTime.now()},
      );
    };

    _socketService.onUserOffline = (data) {
      final userId = data['userId'] as String;
      final lastSeen = data['lastSeen'] != null
          ? DateTime.parse(data['lastSeen'] as String)
          : DateTime.now();
      state = state.copyWith(lastSeen: {...state.lastSeen, userId: lastSeen});
    };
  }

  /// Get or create conversation with another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final chatId = await RealtimeMessagingService.getOrCreateConversation(
        _currentUserId!,
        otherUserId,
      );

      state = state.copyWith(isLoading: false);
      return chatId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create conversation: $e',
      );
      rethrow;
    }
  }

  /// Send text message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    String? replyToId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await RealtimeMessagingService.sendMessage(
        chatId: chatId,
        senderId: _currentUserId!,
        receiverId: receiverId,
        content: content,
        type: MessageType.text,
        replyToId: replyToId,
      );

      // Stop typing after sending
      stopTyping(chatId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message: $e');
      rethrow;
    }
  }

  /// Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String receiverId,
    required String imageUrl,
    String? caption,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await RealtimeMessagingService.sendMessage(
        chatId: chatId,
        senderId: _currentUserId!,
        receiverId: receiverId,
        content: caption ?? 'Image',
        type: MessageType.image,
        imageUrl: imageUrl,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to send image: $e');
      rethrow;
    }
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    if (_currentUserId == null) return;

    try {
      await RealtimeMessagingService.markChatAsRead(chatId, _currentUserId!);
    } catch (e) {
      // Silently fail
    }
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    if (_currentUserId == null) return;

    // Cancel existing timer
    _typingTimer?.cancel();

    // Set typing status
    RealtimeMessagingService.setTypingStatus(
      chatId: chatId,
      userId: _currentUserId!,
      isTyping: true,
    );

    // Auto-stop typing after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping(chatId);
    });
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    if (_currentUserId == null) return;

    _typingTimer?.cancel();

    RealtimeMessagingService.setTypingStatus(
      chatId: chatId,
      userId: _currentUserId!,
      isTyping: false,
    );
  }

  /// Set typing status (convenience method)
  void setTypingStatus(String chatId, bool isTyping) {
    if (isTyping) {
      startTyping(chatId);
    } else {
      stopTyping(chatId);
    }
  }

  /// Update last seen
  void updateLastSeen(String chatId) {
    if (_currentUserId == null) return;

    RealtimeMessagingService.updateLastSeen(chatId, _currentUserId!);
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (_currentUserId == null) return;

    try {
      // This would typically update all unread messages in the chat
      // For now, we'll just update the last seen
      updateLastSeen(chatId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark messages as read: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await RealtimeMessagingService.deleteMessage(chatId, messageId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message: $e');
      rethrow;
    }
  }

  /// Search messages in chat
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      return await RealtimeMessagingService.searchMessages(chatId, query);
    } catch (e) {
      return [];
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}
