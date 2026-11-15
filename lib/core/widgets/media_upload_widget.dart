import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_upload_provider.dart';
import '../services/media_upload_service.dart';

class MediaUploadWidget extends ConsumerWidget {
  final String? folder;
  final Map<String, dynamic>? tags;
  final Function(MediaUploadResult)? onUploadSuccess;
  final Function(String)? onUploadError;
  final Widget? child;
  final bool allowMultiple;
  final bool allowVideo;
  final String uploadText;

  const MediaUploadWidget({
    super.key,
    this.folder,
    this.tags,
    this.onUploadSuccess,
    this.onUploadError,
    this.child,
    this.allowMultiple = false,
    this.allowVideo = false,
    this.uploadText = 'Upload Media',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(mediaUploadProvider);

    return Column(
      children: [
        if (child != null)
          GestureDetector(
            onTap: () => _showUploadOptions(context, ref),
            child: child!,
          )
        else
          _buildDefaultUploadButton(context, ref),

        if (uploadState.status == UploadStatus.uploading)
          _buildUploadProgress(uploadState.progress),

        if (uploadState.status == UploadStatus.error)
          _buildErrorMessage(uploadState.error ?? 'Upload failed'),
      ],
    );
  }

  Widget _buildDefaultUploadButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showUploadOptions(context, ref),
      icon: const Icon(Icons.cloud_upload),
      label: Text(uploadText),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildUploadProgress(double progress) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            'Uploading... ${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _UploadOptionsSheet(
        folder: folder,
        tags: tags,
        onUploadSuccess: onUploadSuccess,
        onUploadError: onUploadError,
        allowMultiple: allowMultiple,
        allowVideo: allowVideo,
      ),
    );
  }
}

class _UploadOptionsSheet extends ConsumerWidget {
  final String? folder;
  final Map<String, dynamic>? tags;
  final Function(MediaUploadResult)? onUploadSuccess;
  final Function(String)? onUploadError;
  final bool allowMultiple;
  final bool allowVideo;

  const _UploadOptionsSheet({
    this.folder,
    this.tags,
    this.onUploadSuccess,
    this.onUploadError,
    this.allowMultiple = false,
    this.allowVideo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Media Source',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            subtitle: const Text('Choose from your photos'),
            onTap: () {
              Navigator.pop(context);
              if (allowMultiple) {
                _uploadMultipleImages(ref);
              } else {
                _uploadFromGallery(ref);
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            subtitle: const Text('Take a new photo'),
            onTap: () {
              Navigator.pop(context);
              _uploadFromCamera(ref);
            },
          ),

          if (allowVideo)
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              subtitle: const Text('Choose or record a video'),
              onTap: () {
                Navigator.pop(context);
                _uploadVideo(ref);
              },
            ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFromGallery(WidgetRef ref) async {
    try {
      final result = await ref
          .read(mediaUploadProvider.notifier)
          .uploadImageFromGallery(folder: folder, tags: tags);

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      onUploadError?.call(e.toString());
    }
  }

  Future<void> _uploadFromCamera(WidgetRef ref) async {
    try {
      final result = await ref
          .read(mediaUploadProvider.notifier)
          .uploadImageFromCamera(folder: folder, tags: tags);

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      onUploadError?.call(e.toString());
    }
  }

  Future<void> _uploadVideo(WidgetRef ref) async {
    try {
      final result = await ref
          .read(mediaUploadProvider.notifier)
          .uploadVideo(folder: folder, tags: tags);

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      onUploadError?.call(e.toString());
    }
  }

  Future<void> _uploadMultipleImages(WidgetRef ref) async {
    try {
      final results = await ref
          .read(mediaUploadProvider.notifier)
          .uploadMultipleImages(folder: folder, tags: tags, maxImages: 10);

      for (final result in results) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      onUploadError?.call(e.toString());
    }
  }
}

// Specialized widgets for different use cases
class ProfilePictureUploadWidget extends ConsumerWidget {
  final Function(MediaUploadResult)? onUploadSuccess;
  final String? currentImageUrl;

  const ProfilePictureUploadWidget({
    super.key,
    this.onUploadSuccess,
    this.currentImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(profilePictureUploadProvider);

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: currentImageUrl != null
              ? NetworkImage(currentImageUrl!)
              : null,
          child: currentImageUrl == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _uploadProfilePicture(ref),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        if (uploadState.status == UploadStatus.uploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _uploadProfilePicture(WidgetRef ref) async {
    try {
      final result = await ref
          .read(profilePictureUploadProvider.notifier)
          .uploadProfilePicture();

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      // Handle error
    }
  }
}

class StoryUploadWidget extends ConsumerWidget {
  final Function(MediaUploadResult)? onUploadSuccess;

  const StoryUploadWidget({super.key, this.onUploadSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: InkWell(
        onTap: () => _showStoryUploadOptions(context, ref),
        borderRadius: BorderRadius.circular(40),
        child: const Icon(Icons.add, size: 30, color: Colors.grey),
      ),
    );
  }

  void _showStoryUploadOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add to Story',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadStoryPhoto(ref);
              },
            ),

            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _uploadStoryVideo(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadStoryPhoto(WidgetRef ref) async {
    try {
      final result = await ref
          .read(storyUploadProvider.notifier)
          .uploadStoryMedia(type: MediaType.image);

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _uploadStoryVideo(WidgetRef ref) async {
    try {
      final result = await ref
          .read(storyUploadProvider.notifier)
          .uploadStoryMedia(type: MediaType.video);

      if (result != null) {
        onUploadSuccess?.call(result);
      }
    } catch (e) {
      // Handle error
    }
  }
}
