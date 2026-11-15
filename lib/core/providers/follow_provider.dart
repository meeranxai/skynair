import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/follow_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((
  ref,
) {
  final authState = ref.watch(authProvider);
  return FollowNotifier(authState.user?.uid, ref);
});

// Provider to check if current user is following a specific user (Real-time)
final isFollowingProvider = StreamProvider.family<bool, String>((ref, userId) {
  final authState = ref.watch(authProvider);
  final currentUserId = authState.user?.uid;

  if (currentUserId == null || currentUserId == userId) {
    return Stream.value(false);
  }

  return FollowService.getFollowStatusStream(currentUserId, userId);
});

// Provider to get followers list for a user
final followersProvider = StreamProvider.family<List<String>, String>((
  ref,
  userId,
) {
  return FollowService.getFollowersStream(userId);
});

// Provider to get following list for a user
final followingProvider = StreamProvider.family<List<String>, String>((
  ref,
  userId,
) {
  return FollowService.getFollowingStream(userId);
});

// Provider to check if current user has requested to follow a specific user (Real-time)
final isFollowRequestedProvider =
    StreamProvider.family<bool, String>((ref, userId) {
      final authState = ref.watch(authProvider);
      final currentUserId = authState.user?.uid;

      if (currentUserId == null || currentUserId == userId) {
        return Stream.value(false);
      }

      return FollowService.getFollowRequestStatusStream(currentUserId, userId);
    });

// Provider to get incoming follow requests for the current user
final incomingFollowRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final authState = ref.watch(authProvider);
      final currentUserId = authState.user?.uid;

      if (currentUserId == null) {
        return Stream.value([]);
      }

      return FollowService.getIncomingFollowRequestsStream(currentUserId);
    });

class FollowState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> followingStatus;
  final Map<String, bool> requestedStatus;

  FollowState({
    this.isLoading = false,
    this.error,
    this.followingStatus = const {},
    this.requestedStatus = const {},
  });

  FollowState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? followingStatus,
    Map<String, bool>? requestedStatus,
  }) {
    return FollowState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      followingStatus: followingStatus ?? this.followingStatus,
      requestedStatus: requestedStatus ?? this.requestedStatus,
    );
  }
}

class FollowNotifier extends StateNotifier<FollowState> {
  final String? _currentUserId;
  final Ref _ref;
  final SocketService _socketService = SocketService();

  FollowNotifier(this._currentUserId, this._ref) : super(FollowState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onFollowUpdate = (data) {
      final followerId = data['followerId'] as String;
      final followingId = data['followingId'] as String;
      final type = data['type'] as String;

      // If the action was performed BY the current user (e.g. on another device)
      if (followerId == _currentUserId) {
        state = state.copyWith(
          followingStatus: {
            ...state.followingStatus,
            followingId: type == 'follow',
          },
        );
      }
    };
  }

  Future<void> followUser(String userId) async {
    if (_currentUserId == null || _currentUserId == userId) return;

    print('🔄 FollowProvider: followUser called for $userId');
    print('📝 Current user: $_currentUserId');

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 1. Check if target user is private
      final isPrivate = await FollowService.isUserPrivate(userId);
      
      if (isPrivate) {
        // Optimistic update for request
        state = state.copyWith(
          requestedStatus: {...state.requestedStatus, userId: true},
        );
        
        await FollowService.sendFollowRequest(_currentUserId!, userId);
        
        // Create follow request notification
        try {
          _ref.read(notificationProvider.notifier).createFollowRequestNotification(userId: userId);
        } catch (e) {
          print('⚠️ Notification failed: $e');
        }
      } else {
        // Optimistic update for direct follow
        state = state.copyWith(
          followingStatus: {...state.followingStatus, userId: true},
        );

        await FollowService.followUser(_currentUserId!, userId);

        // Create follow notification
        try {
          _ref.read(notificationProvider.notifier).createFollowNotification(followedUserId: userId);
        } catch (e) {
          print('⚠️ Notification failed: $e');
        }

        // Emit socket event
        try {
          _socketService.emitFollowUpdate(
            followerId: _currentUserId,
            followingId: userId,
            isFollowing: true,
          );
        } catch (e) {
          print('⚠️ Socket failed: $e');
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('❌ Follow error: $e');
      // Revert optimistic updates
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to follow user: $e',
        followingStatus: {...state.followingStatus, userId: false},
        requestedStatus: {...state.requestedStatus, userId: false},
      );
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId) async {
    if (_currentUserId == null || _currentUserId == userId) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Optimistic update
      state = state.copyWith(
        followingStatus: {...state.followingStatus, userId: false},
      );

      await FollowService.unfollowUser(_currentUserId, userId);

      // Emit socket event
      _socketService.emitFollowUpdate(
        followerId: _currentUserId,
        followingId: userId,
        isFollowing: false,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unfollow user: $e',
        followingStatus: {...state.followingStatus, userId: true},
      );
      rethrow;
    }
  }

  Future<void> cancelFollowRequest(String userId) async {
    if (_currentUserId == null || _currentUserId == userId) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      state = state.copyWith(
        requestedStatus: {...state.requestedStatus, userId: false},
      );

      await FollowService.cancelFollowRequest(_currentUserId, userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel follow request: $e',
        requestedStatus: {...state.requestedStatus, userId: true},
      );
      rethrow;
    }
  }

  Future<void> acceptFollowRequest(String followerId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await FollowService.acceptFollowRequest(followerId, _currentUserId);

      // Notify the follower that their request was accepted
      _ref
          .read(notificationProvider.notifier)
          .createFollowRequestAcceptedNotification(followerId: followerId);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to accept request: $e',
      );
      rethrow;
    }
  }

  Future<void> declineFollowRequest(String followerId) async {
    if (_currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      await FollowService.declineFollowRequest(followerId, _currentUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to decline request: $e',
      );
      rethrow;
    }
  }

  Future<void> toggleFollow(
    String userId, {
    required bool isFollowing,
    required bool isRequested,
  }) async {
    if (isFollowing) {
      await unfollowUser(userId);
    } else if (isRequested) {
      await cancelFollowRequest(userId);
    } else {
      await followUser(userId);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
