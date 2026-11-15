import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_upload_service.dart';
import '../services/supabase_service.dart';

// Upload state
enum UploadStatus { idle, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? error;
  final MediaUploadResult? result;

  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.error,
    this.result,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
    MediaUploadResult? result,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }
}

// Media upload provider
class MediaUploadNotifier extends StateNotifier<UploadState> {
  MediaUploadNotifier() : super(const UploadState());

  final MediaUploadService _mediaUploadService = MediaUploadService();

  /// Upload image from gallery
  Future<MediaUploadResult?> uploadImageFromGallery({
    String? folder,
    Map<String, dynamic>? tags,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final result = await _mediaUploadService.pickAndUploadImageFromGallery(
        folder: folder,
        tags: tags,
      );

      if (result != null) {
        state = state.copyWith(
          status: UploadStatus.success,
          progress: 1.0,
          result: result,
        );
      } else {
        state = state.copyWith(status: UploadStatus.idle);
      }

      return result;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return null;
    }
  }

  /// Upload image from camera
  Future<MediaUploadResult?> uploadImageFromCamera({
    String? folder,
    Map<String, dynamic>? tags,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final result = await _mediaUploadService.pickAndUploadImageFromCamera(
        folder: folder,
        tags: tags,
      );

      if (result != null) {
        state = state.copyWith(
          status: UploadStatus.success,
          progress: 1.0,
          result: result,
        );
      } else {
        state = state.copyWith(status: UploadStatus.idle);
      }

      return result;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return null;
    }
  }

  /// Upload video
  Future<MediaUploadResult?> uploadVideo({
    String? folder,
    Map<String, dynamic>? tags,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final result = await _mediaUploadService.pickAndUploadVideo(
        folder: folder,
        tags: tags,
      );

      if (result != null) {
        state = state.copyWith(
          status: UploadStatus.success,
          progress: 1.0,
          result: result,
        );
      } else {
        state = state.copyWith(status: UploadStatus.idle);
      }

      return result;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return null;
    }
  }

  /// Upload profile picture
  Future<MediaUploadResult?> uploadProfilePicture({
    ImageSource source = ImageSource.gallery,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final result = await _mediaUploadService.uploadProfilePicture(
        source: source,
      );

      if (result != null) {
        state = state.copyWith(
          status: UploadStatus.success,
          progress: 1.0,
          result: result,
        );
      } else {
        state = state.copyWith(status: UploadStatus.idle);
      }

      return result;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return null;
    }
  }

  /// Upload story media
  Future<MediaUploadResult?> uploadStoryMedia({
    required MediaType type,
    ImageSource source = ImageSource.camera,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final result = await _mediaUploadService.uploadStoryMedia(
        type: type,
        source: source,
      );

      if (result != null) {
        state = state.copyWith(
          status: UploadStatus.success,
          progress: 1.0,
          result: result,
        );
      } else {
        state = state.copyWith(status: UploadStatus.idle);
      }

      return result;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return null;
    }
  }

  /// Upload multiple images
  Future<List<MediaUploadResult>> uploadMultipleImages({
    String? folder,
    Map<String, dynamic>? tags,
    int? maxImages,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      final results = await _mediaUploadService.uploadMultipleImages(
        folder: folder,
        tags: tags,
        maxImages: maxImages,
      );

      state = state.copyWith(status: UploadStatus.success, progress: 1.0);

      return results;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, error: e.toString());
      return [];
    }
  }

  /// Reset state
  void reset() {
    state = const UploadState();
  }

  /// Delete media
  Future<bool> deleteMedia(
    String publicId, {
    MediaType type = MediaType.image,
  }) async {
    try {
      return await _mediaUploadService.deleteMedia(publicId, type: type);
    } catch (e) {
      return false;
    }
  }
}

// Providers
final mediaUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, UploadState>(
      (ref) => MediaUploadNotifier(),
    );

// Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Media upload service provider
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService();
});

// Helper providers for specific use cases
final profilePictureUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, UploadState>(
      (ref) => MediaUploadNotifier(),
    );

final storyUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, UploadState>(
      (ref) => MediaUploadNotifier(),
    );

final postUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, UploadState>(
      (ref) => MediaUploadNotifier(),
    );
