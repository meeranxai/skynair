import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String username;

  @HiveField(4)
  final String? photoURL;

  @HiveField(5)
  final String? bio;

  @HiveField(6)
  final int followersCount;

  @HiveField(7)
  final int followingCount;

  @HiveField(8)
  final int postsCount;

  @HiveField(16)
  final int articlesCount;

  @HiveField(9)
  final bool isVerified;

  @HiveField(10)
  final bool isOnline;

  @HiveField(11)
  final DateTime? lastSeen;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  @HiveField(14)
  final DateTime? lastDisplayNameChange;

  @HiveField(15)
  final int displayNameChangeCount;

  @HiveField(17)
  final bool isPrivate;

  @HiveField(18)
  final bool showLastSeen;

  @HiveField(19)
  final bool showOnlineStatus;

  @HiveField(20)
  final bool allowReadReceipts;

  @HiveField(21)
  final String whoCanMessage; // 'everyone', 'following'

  @HiveField(22)
  final String whoCanMention; // 'everyone', 'following', 'no_one'

  @HiveField(23)
  final bool allowStorySharing;

  @HiveField(24)
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoURL,
    this.bio,
    this.followersCount = 0, // Start with 0 - will increase as users follow
    this.followingCount =
        0, // Start with 0 - will increase as user follows others
    this.postsCount =
        0, // Start with 0 - will increase as user creates media posts
    this.articlesCount =
        0, // Start with 0 - will increase as user creates articles
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.lastDisplayNameChange,
    this.displayNameChangeCount = 0,
    this.isPrivate = false,
    this.showLastSeen = true,
    this.showOnlineStatus = true,
    this.allowReadReceipts = true,
    this.whoCanMessage = 'everyone',
    this.whoCanMention = 'everyone',
    this.allowStorySharing = true,
    this.fcmToken,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? articlesCount,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastDisplayNameChange,
    int? displayNameChangeCount,
    bool? isPrivate,
    bool? showLastSeen,
    bool? showOnlineStatus,
    bool? allowReadReceipts,
    String? whoCanMessage,
    String? whoCanMention,
    bool? allowStorySharing,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      articlesCount: articlesCount ?? this.articlesCount,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastDisplayNameChange:
          lastDisplayNameChange ?? this.lastDisplayNameChange,
      displayNameChangeCount:
          displayNameChangeCount ?? this.displayNameChangeCount,
      isPrivate: isPrivate ?? this.isPrivate,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowReadReceipts: allowReadReceipts ?? this.allowReadReceipts,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanMention: whoCanMention ?? this.whoCanMention,
      allowStorySharing: allowStorySharing ?? this.allowStorySharing,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'articlesCount': articlesCount,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastDisplayNameChange': lastDisplayNameChange?.millisecondsSinceEpoch,
      'displayNameChangeCount': displayNameChangeCount,
      'isPrivate': isPrivate,
      'showLastSeen': showLastSeen,
      'showOnlineStatus': showOnlineStatus,
      'allowReadReceipts': allowReadReceipts,
      'whoCanMessage': whoCanMessage,
      'whoCanMention': whoCanMention,
      'allowStorySharing': allowStorySharing,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper to handle both Timestamp and int for dates
    DateTime parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      photoURL: map['photoURL'],
      bio: map['bio'],
      followersCount: map['followersCount']?.toInt() ?? 0,
      followingCount: map['followingCount']?.toInt() ?? 0,
      postsCount: map['postsCount']?.toInt() ?? 0,
      articlesCount: map['articlesCount']?.toInt() ?? 0,
      isVerified: map['isVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? parseDate(map['lastSeen']) : null,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastDisplayNameChange: map['lastDisplayNameChange'] != null
          ? parseDate(map['lastDisplayNameChange'])
          : null,
      displayNameChangeCount: map['displayNameChangeCount']?.toInt() ?? 0,
      isPrivate: map['isPrivate'] ?? false,
      showLastSeen: map['showLastSeen'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      allowReadReceipts: map['allowReadReceipts'] ?? true,
      whoCanMessage: map['whoCanMessage'] ?? 'everyone',
      whoCanMention: map['whoCanMention'] ?? 'everyone',
      allowStorySharing: map['allowStorySharing'] ?? true,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
