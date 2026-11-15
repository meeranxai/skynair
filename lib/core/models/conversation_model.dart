import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, bool> isTyping;
  final Map<String, DateTime> lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    this.unreadCount = const {},
    this.isTyping = const {},
    this.lastSeen = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? isTyping,
    Map<String, DateTime>? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isUserTyping(String userId) {
    return isTyping[userId] ?? false;
  }

  DateTime? getUserLastSeen(String userId) {
    return lastSeen[userId];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'lastSeen': lastSeen.map(
        (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
      ),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        return DateTime.now();
      }
    }

    Map<String, DateTime> parseLastSeen(dynamic value) {
      if (value is Map) {
        return value.map(
          (key, val) => MapEntry(key.toString(), parseDate(val)),
        );
      }
      return {};
    }

    return ConversationModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: parseDate(map['lastMessageTime']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isTyping: Map<String, bool>.from(map['isTyping'] ?? {}),
      lastSeen: parseLastSeen(map['lastSeen']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel.fromMap(json);

  @override
  String toString() {
    return 'ConversationModel(id: $id, participants: $participants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
