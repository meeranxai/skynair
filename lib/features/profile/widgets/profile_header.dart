import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/user_model.dart';
import '../../../../core/widgets/image_viewer_screen.dart';
import 'profile_stats.dart';
import 'profile_action_buttons.dart';

class ProfileHeader extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onSettings;

  const ProfileHeader({
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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          // Profile Picture with enhanced styling
          _buildProfilePicture(context, theme),
          const SizedBox(height: 16),

          // User Info Section with Edit Profile button
          _buildUserInfoWithEditButton(context, theme),
          const SizedBox(height: 12),

          // Bio Section
          if (user.bio?.isNotEmpty == true) ...[
            _buildBio(theme),
            const SizedBox(height: 16),
          ],

          // Stats Section
          ProfileStats(user: user),

          // Action Buttons - Only add spacing if they'll be visible
          if (!isOwnProfile) ...[
            const SizedBox(height: 20),
            ProfileActionButtons(
              user: user,
              isOwnProfile: isOwnProfile,
              onEditProfile: onEditProfile,
              onMessage: onMessage,
              onSettings: onSettings,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context, ThemeData theme) {
    return Stack(
      children: [
        // Main profile picture with enhanced styling
        GestureDetector(
          onTap: user.photoURL != null && user.photoURL!.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        imageUrl: user.photoURL!,
                        title: user.displayName.isNotEmpty
                            ? user.displayName
                            : user.username,
                        heroTag: 'profile_pic_${user.uid}',
                      ),
                    ),
                  );
                }
              : null,
          child: Hero(
            tag: 'profile_pic_${user.uid}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: Container(
                    width: 104,
                    height: 104,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: user.photoURL != null && user.photoURL!.isNotEmpty && user.photoURL != 'null'
                        ? CachedNetworkImage(
                            imageUrl: user.photoURL!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => _buildDefaultAvatar(theme),
                          )
                        : _buildDefaultAvatar(theme),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Online status indicator
        if (user.showOnlineStatus && user.isOnline)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

        // Verified badge or Private Lock
        if (user.isVerified)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 16),
            ),
          )
      ],
    );
  }

  Widget _buildUserInfoWithEditButton(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display Name & Edit Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName
                      : user.email.split('@').first,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (user.isVerified)
                Icon(Icons.verified, color: theme.colorScheme.primary, size: 22),
              if (isOwnProfile)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditProfile,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: theme.colorScheme.primary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 6),

        // Username & Privacy Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '@${user.username}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBio(ThemeData theme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Text(
          user.bio!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : (user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U'),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
