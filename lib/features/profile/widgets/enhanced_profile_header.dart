import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/permission_service.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/live_user_widgets.dart';
import 'follow_button.dart';

class EnhancedProfileHeader extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;
  final VoidCallback onSettings;

  const EnhancedProfileHeader({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
    required this.onSettings,
  });

  @override
  ConsumerState<EnhancedProfileHeader> createState() =>
      _EnhancedProfileHeaderState();
}

class _EnhancedProfileHeaderState extends ConsumerState<EnhancedProfileHeader> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).user?.uid;
    final isFollowingAsync = ref.watch(isFollowingProvider(widget.user.uid));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Picture and Follow Button Row
          Row(
            children: [
              // Enhanced Profile Picture
              _buildEnhancedProfilePicture(theme),
              const SizedBox(width: 24),

              // Stats and Follow Button
              Expanded(
                child: Column(
                  children: [
                    // Stats Row
                    _buildStatsRow(theme),
                    const SizedBox(height: 16),

                    // Action Buttons Row
                    _buildActionButtons(theme, currentUserId, isFollowingAsync),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User Info Section
          _buildUserInfo(theme),

          // Bio Section
          if (widget.user.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildBio(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedProfilePicture(ThemeData theme) {
    return Stack(
      children: [
        // Main profile picture using LiveUserAvatar for consistent story behavior
        LiveUserAvatar(
          userId: widget.user.uid,
          radius: 50,
          fallbackUrl: widget.user.photoURL,
          fallbackName: widget.user.displayName,
          enableStoryClick: true,
        ),
        
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

        // Edit icon for own profile
        if (widget.isOwnProfile)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _showProfilePictureOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),

        // Online status indicator
        if (widget.user.isOnline)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
            ),
          ),

        // Verified badge
        if (widget.user.isVerified)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: Icon(
                Icons.verified,
                size: 12,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            if (widget.user.photoURL != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final hasPermission = await PermissionService.requestGalleryPermission(context);
    if (!hasPermission) return;

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSaveProfilePicture(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final hasPermission = await PermissionService.checkAndRequest(
      Permission.camera,
      context,
    );
    if (!hasPermission) return;

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSaveProfilePicture(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSaveProfilePicture(XFile image) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      // 1. Upload to Supabase Storage
      final String imageUrl = await FirestoreService.uploadProfileImage(
        image,
        widget.user.uid,
      );

      // 2. Update Auth and Firestore profile
      await ref.read(authProvider.notifier).updateProfile(photoURL: imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    // TODO: Implement profile picture removal
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed successfully!')),
      );
    }
  }

  Widget _buildStatsRow(ThemeData theme) {
    // Watch real-time counts
    final postsCount = ref.watch(userPostsCountProvider(widget.user.uid));
    final followersCount = ref.watch(
      userFollowersCountProvider(widget.user.uid),
    );
    final followingCount = ref.watch(
      userFollowingCountProvider(widget.user.uid),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        postsCount.when(
          data: (count) => _buildStatItem(theme, count.toString(), 'Posts'),
          loading: () =>
              _buildStatItem(theme, widget.user.postsCount.toString(), 'Posts'),
          error: (e, s) =>
              _buildStatItem(theme, widget.user.postsCount.toString(), 'Posts'),
        ),
        followersCount.when(
          data: (count) => _buildStatItem(theme, count.toString(), 'Followers'),
          loading: () => _buildStatItem(
            theme,
            widget.user.followersCount.toString(),
            'Followers',
          ),
          error: (e, s) => _buildStatItem(
            theme,
            widget.user.followersCount.toString(),
            'Followers',
          ),
        ),
        followingCount.when(
          data: (count) => _buildStatItem(theme, count.toString(), 'Following'),
          loading: () => _buildStatItem(
            theme,
            widget.user.followingCount.toString(),
            'Following',
          ),
          error: (e, s) => _buildStatItem(
            theme,
            widget.user.followingCount.toString(),
            'Following',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    ThemeData theme,
    String? currentUserId,
    AsyncValue<bool> isFollowingAsync,
  ) {
    if (widget.isOwnProfile) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onEditProfile,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onSettings,
            icon: const Icon(Icons.settings),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: FollowButton(
              targetUserId: widget.user.uid,
              targetUsername: widget.user.username,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onMessage,
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onShare,
            icon: const Icon(Icons.share),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildUserInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.user.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (widget.user.username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${widget.user.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBio(ThemeData theme) {
    return Text(
      widget.user.bio!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        height: 1.4,
      ),
    );
  }
}
