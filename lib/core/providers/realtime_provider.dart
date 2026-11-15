import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/socket_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final realtimeConnectionProvider = Provider<SocketService>((ref) {
  final socketService = SocketService();

  // Listen to auth changes and connect/disconnect socket
  ref.listen(authProvider, (previous, next) {
    if (next.firebaseUser != null &&
        previous?.firebaseUser != next.firebaseUser) {
      socketService.connectWithFirebaseUser(next.firebaseUser!);
    } else if (next.firebaseUser == null && previous?.firebaseUser != null) {
      socketService.disconnect();
    }
  });

  return socketService;
});

final onlineUsersProvider =
    StateNotifierProvider<OnlineUsersNotifier, List<UserModel>>((ref) {
      final socketService = ref.watch(realtimeConnectionProvider);
      return OnlineUsersNotifier(socketService);
    });

final realtimeNotificationsProvider =
    StateNotifierProvider<
      RealtimeNotificationsNotifier,
      List<Map<String, dynamic>>
    >((ref) {
      final socketService = ref.watch(realtimeConnectionProvider);
      return RealtimeNotificationsNotifier(socketService);
    });

final typingIndicatorsProvider =
    StateNotifierProvider<TypingIndicatorsNotifier, Map<String, List<String>>>((
      ref,
    ) {
      final socketService = ref.watch(realtimeConnectionProvider);
      return TypingIndicatorsNotifier(socketService);
    });

class OnlineUsersNotifier extends StateNotifier<List<UserModel>> {
  final SocketService _socketService;

  OnlineUsersNotifier(this._socketService) : super([]) {
    _setupListeners();
  }

  void _setupListeners() {
    _socketService.onUserOnline = (userData) {
      final user = UserModel.fromMap(userData);
      if (!state.any((u) => u.uid == user.uid)) {
        state = [...state, user];
      }
    };

    _socketService.onUserOffline = (userData) {
      final userId = userData['uid'] as String?;
      if (userId != null) {
        state = state.where((user) => user.uid != userId).toList();
      }
    };

    _socketService.onOnlineUsersList = (usersList) {
      final users = usersList
          .map((userData) => UserModel.fromMap(userData))
          .toList();
      state = users;
    };
  }

  bool isUserOnline(String userId) {
    return state.any((user) => user.uid == userId);
  }

  int get onlineCount => state.length;
}

class RealtimeNotificationsNotifier
    extends StateNotifier<List<Map<String, dynamic>>> {
  final SocketService _socketService;

  RealtimeNotificationsNotifier(this._socketService) : super([]) {
    _setupListeners();
  }

  void _setupListeners() {
    _socketService.onNewNotification = (notificationData) {
      state = [notificationData, ...state];
    };
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if (notification['id'] == notificationId) {
        return {...notification, 'read': true};
      }
      return notification;
    }).toList();
  }

  void clearAll() {
    state = [];
  }

  int get unreadCount => state.where((n) => n['read'] != true).length;
}

class TypingIndicatorsNotifier
    extends StateNotifier<Map<String, List<String>>> {
  final SocketService _socketService;

  TypingIndicatorsNotifier(this._socketService) : super({}) {
    _setupListeners();
  }

  void _setupListeners() {
    _socketService.onTyping = (data) {
      final chatId = data['chatId'] as String?;
      final userId = data['userId'] as String?;

      if (chatId != null && userId != null) {
        final currentTyping = state[chatId] ?? [];
        if (!currentTyping.contains(userId)) {
          state = {
            ...state,
            chatId: [...currentTyping, userId],
          };
        }
      }
    };

    _socketService.onStopTyping = (data) {
      final chatId = data['chatId'] as String?;
      final userId = data['userId'] as String?;

      if (chatId != null && userId != null) {
        final currentTyping = state[chatId] ?? [];
        state = {
          ...state,
          chatId: currentTyping.where((id) => id != userId).toList(),
        };

        // Remove empty chat entries
        if (state[chatId]?.isEmpty == true) {
          final newState = Map<String, List<String>>.from(state);
          newState.remove(chatId);
          state = newState;
        }
      }
    };
  }

  List<String> getTypingUsers(String chatId) {
    return state[chatId] ?? [];
  }

  bool isUserTyping(String chatId, String userId) {
    return state[chatId]?.contains(userId) ?? false;
  }

  void startTyping(String chatId, String userId) {
    _socketService.emitTyping(chatId, userId);
  }

  void stopTyping(String chatId, String userId) {
    _socketService.emitStopTyping(chatId, userId);
  }
}
