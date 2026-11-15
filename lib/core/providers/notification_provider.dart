import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final authState = ref.watch(authProvider);
      return NotificationNotifier(authState.user, ref);
    });

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }
  return FirestoreService.getNotificationsStream(authState.user!.uid);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return 0;
  }
  return FirestoreService.getUnreadNotificationCount(authState.user!.uid);
});

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final UserModel? user;
  final Ref ref;
  final SocketService _socketService = SocketService();

  NotificationNotifier(this.user, this.ref) : super(NotificationState()) {
    _setupSocketListeners();
    _loadNotifications();
  }

  void _setupSocketListeners() {
    _socketService.onNewNotification = (notificationData) {
      try {
        final notification = NotificationModel.fromMap(notificationData);

        // Only add if it's for the current user
        if (user != null && notification.toUserId == user!.uid) {
          final updatedNotifications = [notification, ...state.notifications];
          final newUnreadCount =
              state.unreadCount + (notification.isRead ? 0 : 1);

          state = state.copyWith(
            notifications: updatedNotifications,
            unreadCount: newUnreadCount,
          );

          dev.log('✅ Real-time notification added: ${notification.type}');
        }
      } catch (e) {
        dev.log('❌ Error processing real-time notification: $e');
      }
    };

    _socketService.onNotificationUpdate = (notificationData) {
      try {
        final updatedNotification = NotificationModel.fromMap(notificationData);

        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == updatedNotification.id) {
            return updatedNotification;
          }
          return notification;
        }).toList();

        // Recalculate unread count
        final newUnreadCount = updatedNotifications
            .where((n) => !n.isRead)
            .length;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );

        dev.log('✅ Real-time notification updated: ${updatedNotification.id}');
      } catch (e) {
        dev.log('❌ Error processing notification update: $e');
      }
    };
  }

  Future<void> _loadNotifications() async {
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load unread count
      final unreadCount = await FirestoreService.getUnreadNotificationCount(
        user!.uid,
      );

      state = state.copyWith(isLoading: false, unreadCount: unreadCount);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  // Create like notification
  Future<void> createLikeNotification({
    required String postId,
    required String postAuthorId,
    bool isArticle = false,
  }) async {
    if (user == null || user!.uid == postAuthorId) return;

    await createNotification(
      type: isArticle ? 'article_like' : 'like',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: postAuthorId,
      postId: postId,
    );
  }

  // Create comment notification
  Future<void> createCommentNotification({
    required String postId,
    required String postAuthorId,
    required String commentText,
    bool isArticle = false,
  }) async {
    if (user == null || user!.uid == postAuthorId) return;

    await createNotification(
      type: isArticle ? 'article_comment' : 'comment',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: postAuthorId,
      postId: postId,
    );
  }

  // Create mention notification
  Future<void> createMentionNotification({
    required String postId,
    required String toUserId,
    bool isComment = false,
  }) async {
    if (user == null || user!.uid == toUserId) return;

    await createNotification(
      type: 'mention',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: toUserId,
      postId: postId,
    );
  }

  // Create share notification
  Future<void> createShareNotification({
    required String postId,
    required String postAuthorId,
  }) async {
    if (user == null || user!.uid == postAuthorId) return;

    await createNotification(
      type: 'share',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: postAuthorId,
      postId: postId,
    );
  }

  // Create follow notification
  Future<void> createFollowNotification({
    required String followedUserId,
  }) async {
    if (user == null || user!.uid == followedUserId) return;

    await createNotification(
      type: 'follow',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: followedUserId,
    );
  }

  // Create follow request notification
  Future<void> createFollowRequestNotification({
    required String userId,
  }) async {
    if (user == null || user!.uid == userId) return;

    await createNotification(
      type: 'follow_request',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: userId,
    );
  }

  // Create follow request accepted notification
  Future<void> createFollowRequestAcceptedNotification({
    required String followerId,
  }) async {
    if (user == null || user!.uid == followerId) return;

    await createNotification(
      type: 'follow_request_accepted',
      fromUserId: user!.uid,
      fromUsername: user!.displayName,
      fromUserAvatar: user!.photoURL,
      toUserId: followerId,
    );
  }

  Future<void> createNotification({
    required String type,
    required String fromUserId,
    required String fromUsername,
    String? fromUserAvatar,
    required String toUserId,
    String? postId,
  }) async {
    try {
      // Don't create notification for self
      if (fromUserId == toUserId) return;

      // Check for duplicate notifications to prevent spam
      final exists = await FirestoreService.notificationExists(
        type: type,
        fromUserId: fromUserId,
        toUserId: toUserId,
        postId: postId,
      );

      if (exists) {
        dev.log(
          '⚠️ Duplicate notification prevented: $type from $fromUsername',
        );
        return;
      }

      // Create notification message
      String message;
      switch (type) {
        case 'follow':
          message = NotificationModel.createFollowMessage(fromUsername);
          break;
        case 'follow_request':
          message = NotificationModel.createFollowRequestMessage(fromUsername);
          break;
        case 'follow_request_accepted':
          message = NotificationModel.createFollowRequestAcceptedMessage(fromUsername);
          break;
        case 'like':
          message = NotificationModel.createLikeMessage(fromUsername);
          break;
        case 'article_like':
          message = NotificationModel.createLikeMessage(fromUsername, true);
          break;
        case 'comment':
          message = NotificationModel.createCommentMessage(fromUsername);
          break;
        case 'article_comment':
          message = NotificationModel.createCommentMessage(fromUsername, true);
          break;
        case 'mention':
          message = NotificationModel.createMentionMessage(fromUsername);
          break;
        case 'share':
          message = NotificationModel.createShareMessage(fromUsername);
          break;
        default:
          message = '$fromUsername interacted with your content';
      }

      final notification = NotificationModel(
        id: const Uuid().v4(),
        type: type,
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        fromUserAvatar: fromUserAvatar,
        toUserId: toUserId,
        postId: postId,
        message: message,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createNotification(notification);
      
      // Send Push Notification
      try {
        final targetUser = await FirestoreService.getUserProfile(toUserId);
        if (targetUser?.fcmToken != null) {
          await NotificationService.sendPushNotification(
            token: targetUser!.fcmToken!,
            title: message,
            body: 'Tap to view',
            data: {
              'type': type,
              'postId': postId ?? '',
              'notificationId': notification.id,
            },
          );
          dev.log('🚀 Push notification sent to target user: $toUserId');
        }
      } catch (e) {
        dev.log('⚠️ Failed to send push notification: $e');
      }

      // Emit to socket for real-time updates
      _socketService.emitNewNotification(notification.toMap());

      dev.log('✅ Notification created: $type from $fromUsername to $toUserId');
    } catch (e) {
      dev.log('❌ Error creating notification: $e');
      state = state.copyWith(error: 'Failed to create notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (user == null) return;

    try {
      // Optimistic update
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId && !notification.isRead) {
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications
          .where((n) => !n.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // Update in Firestore
      await FirestoreService.markNotificationAsRead(notificationId);

      // Emit to socket for real-time updates
      _socketService.emitNotificationUpdate({
        'id': notificationId,
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      });

      dev.log('✅ Notification marked as read: $notificationId');
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
      // Revert optimistic update on error
      _loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    if (user == null) return;

    try {
      // Optimistic update
      final updatedNotifications = state.notifications.map((notification) {
        if (!notification.isRead) {
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );

      // Update in Firestore
      await FirestoreService.markAllNotificationsAsRead(user!.uid);

      dev.log('✅ All notifications marked as read');
    } catch (e) {
      dev.log('❌ Error marking all notifications as read: $e');
      state = state.copyWith(
        error: 'Failed to mark all notifications as read: $e',
      );
      // Revert optimistic update on error
      _loadNotifications();
    }
  }

  Future<void> clearAll() async {
    if (user == null) return;

    try {
      // Optimistic update
      state = state.copyWith(notifications: [], unreadCount: 0);

      // Clear in Firestore
      await FirestoreService.clearAllNotifications(user!.uid);

      dev.log('✅ All notifications cleared');
    } catch (e) {
      dev.log('❌ Error clearing all notifications: $e');
      state = state.copyWith(error: 'Failed to clear notifications: $e');
      // Revert optimistic update on error
      _loadNotifications();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // Optimistic update
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final newUnreadCount = updatedNotifications
          .where((n) => !n.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // Delete from Firestore
      await FirestoreService.deleteNotification(notificationId);

      dev.log('✅ Notification deleted: $notificationId');
    } catch (e) {
      dev.log('❌ Error deleting notification: $e');
      state = state.copyWith(error: 'Failed to delete notification: $e');
      // Revert optimistic update on error
      _loadNotifications();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh notifications from server
  Future<void> refresh() async {
    await _loadNotifications();
  }
}
