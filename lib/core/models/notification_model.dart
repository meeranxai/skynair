import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 2)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'follow', 'follow_request', 'follow_request_accepted', 'like', 'comment', 'mention', 'share', 'article_like', 'article_comment'

  @HiveField(2)
  final String fromUserId;

  @HiveField(3)
  final String fromUsername;

  @HiveField(4)
  final String? fromUserAvatar;

  @HiveField(5)
  final String toUserId;

  @HiveField(6)
  final String? postId; // null for follow notifications

  @HiveField(7)
  final String message;

  @HiveField(8)
  final bool isRead;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserAvatar,
    required this.toUserId,
    this.postId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  NotificationModel copyWith({
    String? id,
    String? type,
    String? fromUserId,
    String? fromUsername,
    String? fromUserAvatar,
    String? toUserId,
    String? postId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      toUserId: toUserId ?? this.toUserId,
      postId: postId ?? this.postId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserAvatar': fromUserAvatar,
      'toUserId': toUserId,
      'postId': postId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Helper function to convert various date formats to DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return NotificationModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUsername: map['fromUsername'] ?? '',
      fromUserAvatar: map['fromUserAvatar'],
      toUserId: map['toUserId'] ?? '',
      postId: map['postId'],
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: parseDateTime(map['createdAt']),
      readAt: parseOptionalDateTime(map['readAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromMap(json);

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, fromUsername: $fromUsername, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods for notification types
  bool get isFollowNotification => type == 'follow';
  bool get isFollowRequest => type == 'follow_request';
  bool get isFollowRequestAccepted => type == 'follow_request_accepted';
  bool get isLikeNotification => type == 'like' || type == 'article_like';
  bool get isCommentNotification => type == 'comment' || type == 'article_comment';
  bool get isMentionNotification => type == 'mention';
  bool get isShareNotification => type == 'share';

  // Helper method to create notification messages
  static String createFollowMessage(String username) {
    return '$username started following you';
  }

  static String createFollowRequestMessage(String username) {
    return '$username requested to follow you';
  }

  static String createFollowRequestAcceptedMessage(String username) {
    return '$username accepted your follow request';
  }

  static String createLikeMessage(String username, [bool isArticle = false]) {
    return isArticle ? '$username liked your article' : '$username liked your post';
  }

  static String createCommentMessage(String username, [bool isArticle = false]) {
    return isArticle ? '$username commented on your article' : '$username commented on your post';
  }

  static String createMentionMessage(String username, [bool isComment = false]) {
    return isComment ? '$username mentioned you in a comment' : '$username mentioned you in a post';
  }

  static String createShareMessage(String username) {
    return '$username shared your post';
  }
}
