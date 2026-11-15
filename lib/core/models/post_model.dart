import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'post_model.g.dart';

@HiveType(typeId: 1)
class PostModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String? image;

  @HiveField(5)
  final List<String>? imageUrls;

  @HiveField(6)
  final String author;

  @HiveField(7)
  final String authorId;

  @HiveField(8)
  final String? authorAvatar;

  @HiveField(9)
  final String? authorUsername;

  @HiveField(10)
  final List<String> likes;

  @HiveField(11)
  final List<String> saves;

  @HiveField(12)
  final int shareCount;

  @HiveField(13)
  final int commentsCount;

  @HiveField(14)
  final String visibility;

  @HiveField(15)
  final bool allowComments;

  @HiveField(16)
  final bool allowSharing;

  @HiveField(17)
  final DateTime createdAt;

  @HiveField(18)
  final DateTime updatedAt;

  @HiveField(19)
  final String postType; // 'media' or 'article'

  @HiveField(20)
  final bool isDraft;

  @HiveField(21)
  final bool isArchived;

  PostModel({
    required this.id,
    required this.description,
    required this.title,
    required this.category,
    this.image,
    this.imageUrls,
    required this.author,
    required this.authorId,
    this.authorAvatar,
    this.authorUsername,
    this.likes = const [],
    this.saves = const [],
    this.shareCount = 0,
    this.commentsCount = 0,
    this.visibility = 'public',
    this.allowComments = true,
    this.allowSharing = true,
    required this.createdAt,
    required this.updatedAt,
    this.postType = 'media', // default to media for backward compatibility
    this.isDraft = false,
    this.isArchived = false,
  });

  PostModel copyWith({
    String? id,
    String? description,
    String? title,
    String? category,
    String? image,
    List<String>? imageUrls,
    String? author,
    String? authorId,
    String? authorAvatar,
    String? authorUsername,
    List<String>? likes,
    List<String>? saves,
    int? shareCount,
    int? commentsCount,
    String? visibility,
    bool? allowComments,
    bool? allowSharing,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? postType,
    bool? isDraft,
    bool? isArchived,
  }) {
    return PostModel(
      id: id ?? this.id,
      description: description ?? this.description,
      title: title ?? this.title,
      category: category ?? this.category,
      image: image ?? this.image,
      imageUrls: imageUrls ?? this.imageUrls,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorUsername: authorUsername ?? this.authorUsername,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      shareCount: shareCount ?? this.shareCount,
      commentsCount: commentsCount ?? this.commentsCount,
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      allowSharing: allowSharing ?? this.allowSharing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postType: postType ?? this.postType,
      isDraft: isDraft ?? this.isDraft,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  bool isLikedBy(String userId) => likes.contains(userId);
  bool isSavedBy(String userId) => saves.contains(userId);
  int get likesCount => likes.length;

  // Compatibility getters for UI components
  String? get imageUrl => image;
  String? get authorPhotoUrl => authorAvatar;
  String get authorName => authorUsername ?? 'Unknown';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'title': title,
      'category': category,
      'image': image,
      'imageUrls': imageUrls,
      'author': author,
      'authorId': authorId,
      'authorAvatar': authorAvatar,
      'authorUsername': authorUsername,
      'likes': likes,
      'saves': saves,
      'shareCount': shareCount,
      'commentsCount': commentsCount,
      'visibility': visibility,
      'allowComments': allowComments,
      'allowSharing': allowSharing,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'postType': postType,
      'isDraft': isDraft,
      'isArchived': isArchived,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        return DateTime.now();
      }
    }

    return PostModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      image: map['image'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : null,
      author: map['author'] ?? '',
      authorId: map['authorId'] ?? '',
      authorAvatar: map['authorAvatar'],
      authorUsername: map['authorUsername'],
      likes: map['likes'] != null ? List<String>.from(map['likes']) : [],
      saves: map['saves'] != null ? List<String>.from(map['saves']) : [],
      shareCount: map['shareCount']?.toInt() ?? 0,
      commentsCount: map['commentsCount']?.toInt() ?? 0,
      visibility: map['visibility'] ?? 'public',
      allowComments: map['allowComments'] ?? true,
      allowSharing: map['allowSharing'] ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      postType: map['postType'] ?? 'media', // default to media for old posts
      isDraft: map['isDraft'] ?? false,
      isArchived: map['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory PostModel.fromJson(Map<String, dynamic> json) =>
      PostModel.fromMap(json);

  @override
  String toString() {
    return 'PostModel(id: $id, title: $title, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
