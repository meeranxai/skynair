import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story_model.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class StoryModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String? userAvatar;

  @HiveField(4)
  final List<StoryItem> items;

  @HiveField(5)
  @JsonKey(fromJson: _dateTimeFromTimestamp)
  final DateTime createdAt;

  @HiveField(6)
  @JsonKey(fromJson: _dateTimeFromTimestamp)
  final DateTime expiresAt;

  @HiveField(7)
  final List<String> viewers;

  @HiveField(8)
  final int viewCount;

  @HiveField(9)
  final int replyCount;

  @HiveField(10)
  final bool isHighlight;

  @HiveField(11)
  final String? highlightTitle;

  @HiveField(12)
  final List<String> likes;

  @HiveField(13)
  final int likesCount;

  @HiveField(14)
  final bool isArchived;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.items,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.viewCount = 0,
    this.replyCount = 0,
    this.likes = const [],
    this.likesCount = 0,
    this.isHighlight = false,
    this.highlightTitle,
    this.isArchived = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // Convert Firestore Timestamps to ISO strings for json_serializable
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] = (json['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (json['expiresAt'] is Timestamp) {
      json['expiresAt'] = (json['expiresAt'] as Timestamp).toDate().toIso8601String();
    }
    return _$StoryModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StoryModelToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasUnviewedItems => items.any((item) => !item.isViewed);

  bool isViewedBy(String userId) => viewers.contains(userId);
  bool isLikedBy(String userId) => likes.contains(userId);

  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    List<StoryItem>? items,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewers,
    int? viewCount,
    int? replyCount,
    List<String>? likes,
    int? likesCount,
    bool? isHighlight,
    String? highlightTitle,
    bool? isArchived,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewers: viewers ?? this.viewers,
      viewCount: viewCount ?? this.viewCount,
      replyCount: replyCount ?? this.replyCount,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      isHighlight: isHighlight ?? this.isHighlight,
      highlightTitle: highlightTitle ?? this.highlightTitle,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 5)
@JsonSerializable()
class StoryItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final StoryType type;

  @HiveField(2)
  final String? mediaUrl;

  @HiveField(3)
  final String? thumbnailUrl;

  @HiveField(4)
  final String? text;

  @HiveField(5)
  final Duration duration;

  @HiveField(6)
  final List<StorySticker> stickers;

  @HiveField(7)
  final StoryBackground? background;

  @HiveField(8)
  final Map<String, dynamic> effects;

  @HiveField(9)
  @JsonKey(fromJson: _dateTimeFromTimestamp)
  final DateTime createdAt;

  @HiveField(10)
  final bool isViewed;

  @HiveField(11)
  final List<String> mentions;

  @HiveField(12)
  final String? musicId;

  @HiveField(13)
  final String? musicTitle;

  const StoryItem({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.text,
    this.duration = const Duration(seconds: 30),
    this.stickers = const [],
    this.background,
    this.effects = const {},
    required this.createdAt,
    this.isViewed = false,
    this.mentions = const [],
    this.musicId,
    this.musicTitle,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] = (json['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return _$StoryItemFromJson(json);
  }

  Map<String, dynamic> toJson() => _$StoryItemToJson(this);

  StoryItem copyWith({
    String? id,
    StoryType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? text,
    Duration? duration,
    List<StorySticker>? stickers,
    StoryBackground? background,
    Map<String, dynamic>? effects,
    DateTime? createdAt,
    bool? isViewed,
    List<String>? mentions,
    String? musicId,
    String? musicTitle,
  }) {
    return StoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      text: text ?? this.text,
      duration: duration ?? this.duration,
      stickers: stickers ?? this.stickers,
      background: background ?? this.background,
      effects: effects ?? this.effects,
      createdAt: createdAt ?? this.createdAt,
      isViewed: isViewed ?? this.isViewed,
      mentions: mentions ?? this.mentions,
      musicId: musicId ?? this.musicId,
      musicTitle: musicTitle ?? this.musicTitle,
    );
  }
}

@HiveType(typeId: 6)
enum StoryType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  text,
  @HiveField(3)
  boomerang,
  @HiveField(4)
  live,
}

@HiveType(typeId: 7)
@JsonSerializable()
class StorySticker {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final StickerType type;

  @JsonKey(fromJson: _offsetFromJson, toJson: _offsetToJson)
  final Offset position;

  @HiveField(2)
  final double rotation;

  @HiveField(3)
  final double scale;

  @HiveField(4)
  final Map<String, dynamic> data;

  const StorySticker({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.data = const {},
  });

  factory StorySticker.fromJson(Map<String, dynamic> json) =>
      _$StoryStickerFromJson(json);

  Map<String, dynamic> toJson() => _$StoryStickerToJson(this);
}

// Offset converter functions
Offset _offsetFromJson(Map<String, dynamic> json) {
  return Offset(json['dx'] as double, json['dy'] as double);
}

Map<String, dynamic> _offsetToJson(Offset offset) {
  return {'dx': offset.dx, 'dy': offset.dy};
}

@HiveType(typeId: 8)
enum StickerType {
  @HiveField(0)
  emoji,
  @HiveField(1)
  text,
  @HiveField(2)
  mention,
  @HiveField(3)
  location,
  @HiveField(4)
  music,
  @HiveField(5)
  poll,
  @HiveField(6)
  question,
  @HiveField(7)
  countdown,
  @HiveField(8)
  gif,
}

@HiveType(typeId: 9)
@JsonSerializable()
class StoryBackground {
  @HiveField(0)
  final BackgroundType type;

  @HiveField(1)
  final String? color;

  @HiveField(2)
  final List<String>? gradientColors;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final String? videoUrl;

  const StoryBackground({
    required this.type,
    this.color,
    this.gradientColors,
    this.imageUrl,
    this.videoUrl,
  });

  factory StoryBackground.fromJson(Map<String, dynamic> json) =>
      _$StoryBackgroundFromJson(json);

  Map<String, dynamic> toJson() => _$StoryBackgroundToJson(this);
}

@HiveType(typeId: 10)
enum BackgroundType {
  @HiveField(0)
  color,
  @HiveField(1)
  gradient,
  @HiveField(2)
  image,
  @HiveField(3)
  video,
}

@HiveType(typeId: 11)
@JsonSerializable()
class StoryReply {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String storyId;

  @HiveField(2)
  final String fromUserId;

  @HiveField(3)
  final String fromUserName;

  @HiveField(4)
  final String? fromUserAvatar;

  @HiveField(5)
  final String message;

  @HiveField(6)
  @JsonKey(fromJson: _dateTimeFromTimestamp)
  final DateTime createdAt;

  @HiveField(7)
  final bool isRead;

  const StoryReply({
    required this.id,
    required this.storyId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory StoryReply.fromJson(Map<String, dynamic> json) =>
      _$StoryReplyFromJson(json);

  Map<String, dynamic> toJson() => _$StoryReplyToJson(this);
}

// Helper for Firestore Timestamps
DateTime _dateTimeFromTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is DateTime) {
    return value;
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now();
}

// Extension for Offset serialization
extension OffsetExtension on Offset {
  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};

  static Offset fromJson(Map<String, dynamic> json) =>
      Offset(json['dx']?.toDouble() ?? 0.0, json['dy']?.toDouble() ?? 0.0);
}
