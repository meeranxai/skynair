import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    this.videoUrl,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.readAt,
    this.deliveredAt,
    this.replyToId,
    this.metadata,
  });

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    String? imageUrl,
    String? videoUrl,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'readAt': readAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'replyToId': replyToId,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        return DateTime.now();
      }
    }

    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      timestamp: parseDate(map['timestamp']),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
      readAt: map['readAt'] != null ? parseDate(map['readAt']) : null,
      deliveredAt: map['deliveredAt'] != null
          ? parseDate(map['deliveredAt'])
          : null,
      replyToId: map['replyToId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      MessageModel.fromMap(json);

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum MessageType { text, image, video, audio, file, location }

// For backward compatibility with existing code
class Message extends MessageModel {
  Message({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.receiverId,
    required super.content,
    super.type,
    super.imageUrl,
    super.videoUrl,
    required super.timestamp,
    super.isRead,
    super.isDelivered,
    super.readAt,
    super.deliveredAt,
    super.replyToId,
    super.metadata,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final messageModel = MessageModel.fromMap(map);
    return Message(
      id: messageModel.id,
      chatId: messageModel.chatId,
      senderId: messageModel.senderId,
      receiverId: messageModel.receiverId,
      content: messageModel.content,
      type: messageModel.type,
      imageUrl: messageModel.imageUrl,
      videoUrl: messageModel.videoUrl,
      timestamp: messageModel.timestamp,
      isRead: messageModel.isRead,
      isDelivered: messageModel.isDelivered,
      readAt: messageModel.readAt,
      deliveredAt: messageModel.deliveredAt,
      replyToId: messageModel.replyToId,
      metadata: messageModel.metadata,
    );
  }
}
