import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';

/// Available profile actions
enum ProfileAction {
  editProfile,
  settings,
  viewFollowers,
  viewFollowing,
  managePosts,
  insights,
  archive,
  share,
  follow,
  unfollow,
  message,
  viewPosts,
  report,
  block,
}

/// Available post actions
enum PostAction {
  like,
  comment,
  share,
  save,
  edit,
  delete,
  changeVisibility,
  viewInsights,
  cropMedia,
  report,
  mute,
  block,
  archive,
}

/// Available profile menu options
enum ProfileMenuOption {
  settings,
  insights,
  archive,
  activity,
  share,
  copyLink,
  report,
  block,
}

/// Utility class to determine available actions based on user roles
class RoleBasedActions {
  /// Get available profile actions for a user
  static List<ProfileAction> getProfileActions({
    required UserModel profileUser,
    required String? currentUserId,
    required bool isFollowing,
  }) {
    final isOwnProfile = currentUserId == profileUser.uid;

    if (isOwnProfile) {
      return _getOwnProfileActions();
    } else {
      return _getOtherUserProfileActions(isFollowing);
    }
  }

  /// Get available post actions for a post
  static List<PostAction> getPostActions({
    required PostModel post,
    required String? currentUserId,
  }) {
    final isOwner = currentUserId == post.authorId;

    if (isOwner) {
      return _getOwnerPostActions();
    } else {
      return _getViewerPostActions();
    }
  }

  /// Get profile menu options
  static List<ProfileMenuOption> getProfileMenuOptions({
    required UserModel profileUser,
    required String? currentUserId,
  }) {
    final isOwnProfile = currentUserId == profileUser.uid;

    if (isOwnProfile) {
      return _getOwnProfileMenuOptions();
    } else {
      return _getOtherUserMenuOptions();
    }
  }

  // Private methods for own profile actions
  static List<ProfileAction> _getOwnProfileActions() {
    return [
      ProfileAction.editProfile,
      ProfileAction.settings,
      ProfileAction.viewFollowers,
      ProfileAction.viewFollowing,
      ProfileAction.managePosts,
      ProfileAction.insights,
      ProfileAction.archive,
      ProfileAction.share,
    ];
  }

  // Private methods for other user profile actions
  static List<ProfileAction> _getOtherUserProfileActions(bool isFollowing) {
    return [
      isFollowing ? ProfileAction.unfollow : ProfileAction.follow,
      ProfileAction.message,
      ProfileAction.viewPosts,
      ProfileAction.share,
      ProfileAction.report,
      ProfileAction.block,
    ];
  }

  // Private methods for owner post actions
  static List<PostAction> _getOwnerPostActions() {
    return [
      PostAction.edit,
      PostAction.delete,
      // PostAction.changeVisibility,
      // PostAction.viewInsights,
      PostAction.share,
      // PostAction.cropMedia,
      PostAction.archive,
    ];
  }

  // Private methods for viewer post actions
  static List<PostAction> _getViewerPostActions() {
    return [
      PostAction.like,
      PostAction.comment,
      PostAction.share,
      PostAction.save,
      PostAction.report,
      PostAction.mute,
      PostAction.block,
    ];
  }

  // Private methods for own profile menu options
  static List<ProfileMenuOption> _getOwnProfileMenuOptions() {
    return [
      ProfileMenuOption.settings,
      ProfileMenuOption.insights,
      ProfileMenuOption.archive,
      ProfileMenuOption.activity,
      ProfileMenuOption.share,
    ];
  }

  // Private methods for other user menu options
  static List<ProfileMenuOption> _getOtherUserMenuOptions() {
    return [
      ProfileMenuOption.share,
      ProfileMenuOption.copyLink,
      ProfileMenuOption.report,
      ProfileMenuOption.block,
    ];
  }

  /// Check if user can perform specific action
  static bool canPerformAction({
    required String action,
    required String? currentUserId,
    String? targetUserId,
    PostModel? post,
  }) {
    switch (action) {
      case 'edit_profile':
        return currentUserId == targetUserId;
      case 'edit_post':
        return post != null && currentUserId == post.authorId;
      case 'delete_post':
        return post != null && currentUserId == post.authorId;
      case 'view_insights':
        return post != null && currentUserId == post.authorId;
      case 'follow':
        return currentUserId != null && currentUserId != targetUserId;
      case 'message':
        return currentUserId != null && currentUserId != targetUserId;
      default:
        return true;
    }
  }
}

/// Extension to get display names and icons for profile actions
extension ProfileActionExtension on ProfileAction {
  String get displayName {
    switch (this) {
      case ProfileAction.editProfile:
        return 'Edit Profile';
      case ProfileAction.settings:
        return 'Settings';
      case ProfileAction.viewFollowers:
        return 'View Followers';
      case ProfileAction.viewFollowing:
        return 'View Following';
      case ProfileAction.managePosts:
        return 'Manage Posts';
      case ProfileAction.insights:
        return 'Insights';
      case ProfileAction.archive:
        return 'Archive';
      case ProfileAction.share:
        return 'Share Profile';
      case ProfileAction.follow:
        return 'Follow';
      case ProfileAction.unfollow:
        return 'Unfollow';
      case ProfileAction.message:
        return 'Message';
      case ProfileAction.viewPosts:
        return 'View Posts';
      case ProfileAction.report:
        return 'Report User';
      case ProfileAction.block:
        return 'Block User';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileAction.editProfile:
        return Icons.edit_outlined;
      case ProfileAction.settings:
        return Icons.settings_outlined;
      case ProfileAction.viewFollowers:
        return Icons.people_outline;
      case ProfileAction.viewFollowing:
        return Icons.person_add_outlined;
      case ProfileAction.managePosts:
        return Icons.grid_on_outlined;
      case ProfileAction.insights:
        return Icons.analytics_outlined;
      case ProfileAction.archive:
        return Icons.archive_outlined;
      case ProfileAction.share:
        return Icons.share_outlined;
      case ProfileAction.follow:
        return Icons.person_add_outlined;
      case ProfileAction.unfollow:
        return Icons.person_remove_outlined;
      case ProfileAction.message:
        return Icons.chat_bubble_outline;
      case ProfileAction.viewPosts:
        return Icons.grid_on_outlined;
      case ProfileAction.report:
        return Icons.report_outlined;
      case ProfileAction.block:
        return Icons.block_outlined;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case ProfileAction.report:
      case ProfileAction.block:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

/// Extension to get display names and icons for post actions
extension PostActionExtension on PostAction {
  String get displayName {
    switch (this) {
      case PostAction.like:
        return 'Like';
      case PostAction.comment:
        return 'Comment';
      case PostAction.share:
        return 'Share';
      case PostAction.save:
        return 'Save';
      case PostAction.edit:
        return 'Edit Post';
      case PostAction.delete:
        return 'Delete Post';
      case PostAction.changeVisibility:
        return 'Change Visibility';
      case PostAction.viewInsights:
        return 'View Insights';
      case PostAction.cropMedia:
        return 'Crop Media';
      case PostAction.report:
        return 'Report Post';
      case PostAction.mute:
        return 'Mute User';
      case PostAction.block:
        return 'Block User';
      case PostAction.archive:
        return 'Archive Post';
    }
  }

  IconData get icon {
    switch (this) {
      case PostAction.like:
        return Icons.favorite_border;
      case PostAction.comment:
        return Icons.chat_bubble_outline;
      case PostAction.share:
        return Icons.share_outlined;
      case PostAction.save:
        return Icons.bookmark_border;
      case PostAction.edit:
        return Icons.edit_outlined;
      case PostAction.delete:
        return Icons.delete_outlined;
      case PostAction.changeVisibility:
        return Icons.visibility_outlined;
      case PostAction.viewInsights:
        return Icons.analytics_outlined;
      case PostAction.cropMedia:
        return Icons.crop_outlined;
      case PostAction.report:
        return Icons.report_outlined;
      case PostAction.mute:
        return Icons.volume_off_outlined;
      case PostAction.block:
        return Icons.block_outlined;
      case PostAction.archive:
        return Icons.archive_outlined;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case PostAction.delete:
      case PostAction.report:
      case PostAction.mute:
      case PostAction.block:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

/// Extension to get display names and icons for profile menu options
extension ProfileMenuOptionExtension on ProfileMenuOption {
  String get displayName {
    switch (this) {
      case ProfileMenuOption.settings:
        return 'Settings';
      case ProfileMenuOption.insights:
        return 'Insights';
      case ProfileMenuOption.archive:
        return 'Archive';
      case ProfileMenuOption.activity:
        return 'Activity';
      case ProfileMenuOption.share:
        return 'Share Profile';
      case ProfileMenuOption.copyLink:
        return 'Copy Profile Link';
      case ProfileMenuOption.report:
        return 'Report User';
      case ProfileMenuOption.block:
        return 'Block User';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileMenuOption.settings:
        return Icons.settings_outlined;
      case ProfileMenuOption.insights:
        return Icons.analytics_outlined;
      case ProfileMenuOption.archive:
        return Icons.archive_outlined;
      case ProfileMenuOption.activity:
        return Icons.history_outlined;
      case ProfileMenuOption.share:
        return Icons.share_outlined;
      case ProfileMenuOption.copyLink:
        return Icons.link_outlined;
      case ProfileMenuOption.report:
        return Icons.report_outlined;
      case ProfileMenuOption.block:
        return Icons.block_outlined;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case ProfileMenuOption.report:
      case ProfileMenuOption.block:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}
