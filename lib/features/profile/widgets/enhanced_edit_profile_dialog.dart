import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/unified_keyboard_handler.dart';
import '../../../core/widgets/image_viewer_screen.dart';
import '../../../core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';


class EnhancedEditProfileDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const EnhancedEditProfileDialog({super.key, required this.user});

  @override
  ConsumerState<EnhancedEditProfileDialog> createState() =>
      _EnhancedEditProfileDialogState();
}

class _EnhancedEditProfileDialogState
    extends ConsumerState<EnhancedEditProfileDialog>
    with TickerProviderStateMixin {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  final FocusNode _displayNameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  Timer? _debounceTimer;

  XFile? _imageFile;
  bool _isLoading = false;
  bool _isUsernameAvailable = true;
  String? _usernameError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _usernameController = TextEditingController(text: widget.user.username);

    _fadeController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  
  _debounceTimer?.cancel();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    _displayNameFocus.dispose();
    _bioFocus.dispose();
    _usernameFocus.dispose();
    _fadeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
        ),
        IOSUiSettings(
          title: 'Crop Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
        WebUiSettings(
          context: context,
          size: const CropperSize(width: 512, height: 512),
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = XFile(croppedFile.path);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final hasPermission = await PermissionService.requestGalleryPermission(context);
      if (!hasPermission) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 95,
      );


      if (image != null) {
        await _cropImage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final hasPermission = await PermissionService.checkAndRequest(Permission.camera, context);
      if (!hasPermission) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 95,
      );


      if (image != null) {
        await _cropImage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
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
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Change Profile Picture',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_imageFile != null || (widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty))
                          Expanded(
                            child: _buildImageSourceOption(
                              icon: Icons.visibility_outlined,
                              label: 'View',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerScreen(
                                      imageUrl: _imageFile == null ? widget.user.photoURL : null,
                                      imageFile: _imageFile != null ? File(_imageFile!.path) : null,
                                      title: 'Profile Photo',
                                      heroTag: 'profile_pic_edit',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_imageFile != null || (widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty))
                          const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromGallery();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () {
                              Navigator.pop(context);
                              _takePhoto();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final normalizedUsername = username.toLowerCase();
    final currentUsername = widget.user.username.toLowerCase();

    // If username hasn't changed (case-insensitive), it's valid
    if (normalizedUsername == currentUsername) {
      setState(() {
        _isUsernameAvailable = true;
        _usernameError = null;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username must be at least 3 characters';
      });
      return;
    }

    if (username.length > 30) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username cannot exceed 30 characters';
      });
      return;
    }

    // Check for valid characters: lowercase letters, numbers, periods, underscores
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError =
            'Username can only contain lowercase letters, numbers, periods, and underscores';
      });
      return;
    }

    // Check for consecutive periods (..)
    if (username.contains('..')) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username cannot contain consecutive periods';
      });
      return;
    }

    // Check if username ends with period
    if (username.endsWith('.')) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username cannot end with a period';
      });
      return;
    }

    // Check if username starts with period
    if (username.startsWith('.')) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username cannot start with a period';
      });
      return;
    }

    try {
      final isAvailable = await FirestoreService.isUsernameAvailable(
        username.toLowerCase(),
      );
      setState(() {
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Username is already taken';
      });
    } catch (e) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Error checking username availability';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Display name cannot be empty');
      _displayNameFocus.requestFocus();
      return;
    }

    if (_displayNameController.text.trim().length > 30) {
      _showErrorSnackBar('Display name cannot exceed 30 characters');
      _displayNameFocus.requestFocus();
      return;
    }

    if (!_isUsernameAvailable) {
      _showErrorSnackBar(_usernameError ?? 'Please fix username issues');
      _usernameFocus.requestFocus();
      return;
    }

    // Check if display name changed
    final displayNameChanged =
        _displayNameController.text.trim() != widget.user.displayName;

    // Validate display name change restrictions (2 changes per 14 days)
    if (displayNameChanged) {
      final lastChange = widget.user.lastDisplayNameChange;
      final changeCount = widget.user.displayNameChangeCount;

      if (lastChange != null) {
        final daysSinceLastChange = DateTime.now()
            .difference(lastChange)
            .inDays;

        // If within 14 days and already changed 2 times, show error
        if (daysSinceLastChange < 14 && changeCount >= 2) {
          final daysRemaining = 14 - daysSinceLastChange;
          _showDisplayNameLimitDialog(daysRemaining);
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      String? newPhotoURL = widget.user.photoURL;

      // Upload new profile image if selected
      if (_imageFile != null) {
        newPhotoURL = await FirestoreService.uploadProfileImage(
          _imageFile!,
          widget.user.uid,
        );
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Handle display name change tracking
      if (displayNameChanged) {
        final lastChange = widget.user.lastDisplayNameChange;
        final changeCount = widget.user.displayNameChangeCount;

        if (lastChange == null) {
          // First time changing display name
          updateData['lastDisplayNameChange'] = FieldValue.serverTimestamp();
          updateData['displayNameChangeCount'] = 1;
        } else {
          final daysSinceLastChange = DateTime.now()
              .difference(lastChange)
              .inDays;

          if (daysSinceLastChange >= 14) {
            // Reset counter after 14 days
            updateData['lastDisplayNameChange'] = FieldValue.serverTimestamp();
            updateData['displayNameChangeCount'] = 1;
          } else {
            // Increment counter within 14 days
            updateData['lastDisplayNameChange'] = FieldValue.serverTimestamp();
            updateData['displayNameChangeCount'] = changeCount + 1;
          }
        }
      }

      // Only update username if it changed and is valid
      if (_usernameController.text.trim() != widget.user.username &&
          _usernameController.text.trim().isNotEmpty) {
        updateData['username'] = _usernameController.text.trim().toLowerCase();
      }

      // Only update photo URL if new image was uploaded
      if (newPhotoURL != widget.user.photoURL) {
        updateData['photoURL'] = newPhotoURL;
      }

      // Update profile in Firestore
      await FirestoreService.updateUserProfile(widget.user.uid, updateData);

      // Update auth provider with new data
      ref
          .read(authProvider.notifier)
          .updateUserProfile(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim(),
            username: _usernameController.text.trim().isNotEmpty
                ? _usernameController.text.trim().toLowerCase()
                : widget.user.username,
            photoURL: newPhotoURL,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDisplayNameLimitDialog(int daysRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Display Name Limit Reached',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آپ نے 14 دنوں میں 2 بار Display Name تبدیل کر لیا ہے۔',
              style: TextStyle(fontSize: 15, height: 1.5),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'You have already changed your display name 2 times in the last 14 days.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'آپ $daysRemaining دن بعد دوبارہ تبدیل کر سکتے ہیں',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can change it again in $daysRemaining days.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: UnifiedKeyboardHandler(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture Section
                        GestureDetector(
                          onTap: _isLoading ? null : _showImageSourceDialog,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(File(_imageFile!.path))
                                        : (widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty
                                            ? CachedNetworkImageProvider(widget.user.photoURL!)
                                            : null),
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                  child:
                                      _imageFile == null &&
                                          widget.user.photoURL == null
                                      ? Text(
                                          widget.user.displayName.isNotEmpty
                                              ? widget.user.displayName[0]
                                                    .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Change Profile Photo',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Fields
                        _buildTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          label: 'Username',
                          hint: 'username',
                          prefixIcon: Icons.alternate_email_rounded,
                          maxLength: 30,
                          onChanged: (value) {
                            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                              _checkUsernameAvailability(value.trim());
                            });
                          },
                          errorText: _usernameError,
                          suffixIcon:
                              _usernameController.text.trim().isNotEmpty &&
                                  _usernameController.text.trim() !=
                                      widget.user.username
                              ? (_isUsernameAvailable
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 20,
                                      ))
                              : null,
                        ),

                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _displayNameController,
                          focusNode: _displayNameFocus,
                          label: 'Display Name',
                          hint: 'Your Name',
                          prefixIcon: Icons.person_rounded,
                          maxLength: 30,
                        ),

                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _bioController,
                          focusNode: _bioFocus,
                          label: 'Bio',
                          hint: 'Write something about yourself...',
                          prefixIcon: Icons.info_outline_rounded,
                          maxLines: 3,
                          maxLength: 150,
                          alignLabelWithHint: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? errorText,
    Widget? suffixIcon,
    int maxLines = 1,
    int? maxLength,
    bool alignLabelWithHint = false,
    Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
                bottom: alignLabelWithHint ? 24 : 0,
              ),
              child: Icon(
                prefixIcon,
                color: focusNode.hasFocus
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            counterText: maxLength != null ? null : '',
          ),
          textCapitalization: maxLines > 1
              ? TextCapitalization.sentences
              : TextCapitalization.none,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
