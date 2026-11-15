class FirebaseConfig {
  // Firestore Collections
  static const String userProfiles = 'userProfiles';
  static const String posts = 'posts';
  static const String comments = 'comments';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String notifications = 'notifications';
  static const String stories = 'stories';
  static const String follows = 'follows';
  static const String followRequests = 'followRequests';
  static const String reports = 'reports';
  static const String blocks = 'blocks';

  // Storage Paths
  static const String profilePictures = 'profile-pictures';
  static const String postImages = 'post-images';
  static const String storyImages = 'story-images';
  static const String messageImages = 'message-images';

  // Validation Constants
  static const int maxUsernameLength = 30;
  static const int maxDisplayNameLength = 50;
  static const int maxBioLength = 150;
  static const int maxPostTitleLength = 100;
  static const int maxPostDescriptionLength = 2000;
  static const int maxCommentLength = 500;
  static const int maxMessageLength = 1000;

  // File Size Limits (in bytes)
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxPostImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxStoryImageSize = 8 * 1024 * 1024; // 8MB

  // Allowed Image Types
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  // Post Categories
  static const List<String> postCategories = [
    'General',
    'Technology',
    'Sports',
    'Entertainment',
    'News',
    'Education',
    'Travel',
    'Food',
    'Fashion',
    'Health',
    'Business',
    'Art',
  ];

  // Notification Types
  static const String notificationLike = 'like';
  static const String notificationComment = 'comment';
  static const String notificationFollow = 'follow';
  static const String notificationMessage = 'message';
  static const String notificationMention = 'mention';
}
