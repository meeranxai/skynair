import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import 'follow_button.dart';

class ProfileActionButtons extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onSettings;

  const ProfileActionButtons({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.onEditProfile,
    required this.onMessage,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (isOwnProfile) {
      return _buildOwnProfileButtons(theme);
    } else {
      return _buildOtherProfileButtons(context, ref, theme);
    }
  }

  Widget _buildOwnProfileButtons(ThemeData theme) {
    // Remove the settings button since it's already in the top AppBar
    return const SizedBox.shrink(); // No buttons needed for own profile
  }

  Widget _buildOtherProfileButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: FollowButton(
            targetUserId: user.uid,
            targetUsername: user.username,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(
    ThemeData theme,
    VoidCallback onPressed,
    String label,
    IconData icon,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
      ),
    );
  }
}
