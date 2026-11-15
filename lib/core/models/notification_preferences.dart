class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool likesAndCommentsEnabled;
  final bool newFollowersEnabled;

  const NotificationPreferences({
    this.pushNotificationsEnabled = true,
    this.likesAndCommentsEnabled = true,
    this.newFollowersEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? likesAndCommentsEnabled,
    bool? newFollowersEnabled,
  }) {
    return NotificationPreferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      likesAndCommentsEnabled: likesAndCommentsEnabled ?? this.likesAndCommentsEnabled,
      newFollowersEnabled: newFollowersEnabled ?? this.newFollowersEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'likesAndCommentsEnabled': likesAndCommentsEnabled,
      'newFollowersEnabled': newFollowersEnabled,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      pushNotificationsEnabled: map['pushNotificationsEnabled'] as bool? ?? true,
      likesAndCommentsEnabled: map['likesAndCommentsEnabled'] as bool? ?? true,
      newFollowersEnabled: map['newFollowersEnabled'] as bool? ?? true,
    );
  }
}
