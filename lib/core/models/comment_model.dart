import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class CommentModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String postId;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String authorId;

  @HiveField(4)
  final String author;

  @HiveField(5)
  final String? authorUsername;

  @HiveField(6)
  final String? authorAvatar;

  @HiveField(7)
  final List<String> likes;

  @HiveField(8)
  final String? parentCommentId; // For replies

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool isEdited;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.author,
    this.authorUsername,
    this.authorAvatar,
    this.likes = const [],
    this.parentCommentId,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);

  CommentModel copyWith({
    String? id,
    String? postId,
    String? content,
    String? authorId,
    String? author,
    String? authorUsername,
    String? authorAvatar,
    List<String>? likes,
    String? parentCommentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likes: likes ?? this.likes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  // Add missing getters for compatibility
  String? get parentId => parentCommentId;
  String get authorName => author;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommentModel{id: $id, postId: $postId, content: $content, author: $author, likes: ${likes.length}, createdAt: $createdAt}';
  }
}
