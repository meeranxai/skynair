import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../config/app_config.dart';

enum MediaType { image, video }

class MediaUploadResult {
  final String publicId; // For Supabase, this is the file path
  final String secureUrl; // The public URL
  final String originalUrl; // Same as secureUrl for Supabase
  final MediaType type;
  final Map<String, dynamic> metadata;

  MediaUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.originalUrl,
    required this.type,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'secureUrl': secureUrl,
    'originalUrl': originalUrl,
    'type': type.name,
    'metadata': metadata,
  };

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      publicId: json['publicId'],
      secureUrl: json['secureUrl'],
      originalUrl: json['originalUrl'],
      type: MediaType.values.firstWhere((e) => e.name == json['type']),
      metadata: json['metadata'] ?? {},
    );
  }
}

class MediaUploadService {
  static final MediaUploadService _instance = MediaUploadService._internal();
  factory MediaUploadService() => _instance;
  MediaUploadService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick and upload image from gallery
  Future<MediaUploadResult?> pickAndUploadImageFromGallery({
    String? folder,
    Map<String, dynamic>? tags,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      return await uploadXFile(image, folder: folder, tags: tags);
    } catch (e) {
      throw MediaUploadException(
        'Failed to pick and upload image from gallery: $e',
      );
    }
  }

  /// Pick and upload image from camera
  Future<MediaUploadResult?> pickAndUploadImageFromCamera({
    String? folder,
    Map<String, dynamic>? tags,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      return await uploadXFile(image, folder: folder, tags: tags);
    } catch (e) {
      throw MediaUploadException(
        'Failed to pick and upload image from camera: $e',
      );
    }
  }

  /// Pick and upload video
  Future<MediaUploadResult?> pickAndUploadVideo({
    String? folder,
    Map<String, dynamic>? tags,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (video == null) return null;

      return await uploadVideoXFile(video, folder: folder, tags: tags);
    } catch (e) {
      throw MediaUploadException('Failed to pick and upload video: $e');
    }
  }

  /// Upload XFile (Images)
  Future<MediaUploadResult> uploadXFile(
    XFile imageFile, {
    String? folder,
    Map<String, dynamic>? tags,
    String? customPublicId,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileSize = bytes.length;

      if (fileSize > AppConfig.maxImageSize) {
        throw MediaUploadException(
          'File size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds maximum allowed size (${AppConfig.maxImageSize / (1024 * 1024)}MB)',
        );
      }

      dev.log(
        '📤 Uploading image: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
      );

      final fileName = customPublicId ?? _generatePublicId('img');

      final publicUrl = await _uploadWithRetry(() async {
        return await _supabaseService.uploadImage(
          imageFile,
          folder: folder ?? 'posts',
          customFileName: fileName,
        );
      });

      final storagePath = '${folder ?? 'posts'}/$fileName';

      return MediaUploadResult(
        publicId: storagePath,
        secureUrl: publicUrl,
        originalUrl: publicUrl,
        type: MediaType.image,
        metadata: {
          'publicId': storagePath,
          'url': publicUrl,
          'secureUrl': publicUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'fileSize': fileSize,
        },
      );
    } catch (e) {
      dev.log('❌ Failed to upload XFile: $e');
      throw MediaUploadException('Failed to upload XFile: $e');
    }
  }

  /// Upload image file (Keep for legacy but redirected)
  Future<MediaUploadResult> uploadImageFile(
    String filePath, {
    String? folder,
    Map<String, dynamic>? tags,
    String? customPublicId,
  }) async {
    if (kIsWeb) {
      throw MediaUploadException('uploadImageFile (path) is not supported on Web. Use uploadXFile.');
    }
    return uploadXFile(XFile(filePath), folder: folder, tags: tags, customPublicId: customPublicId);
  }

  /// Upload image from bytes
  Future<MediaUploadResult> uploadImageFromBytes(
    Uint8List bytes,
    String fileName, {
    String? folder,
    Map<String, dynamic>? tags,
    String? customPublicId,
  }) async {
    try {
      // Validate file size
      if (bytes.length > AppConfig.maxImageSize) {
        throw MediaUploadException(
          'File size (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds maximum allowed size (${AppConfig.maxImageSize / (1024 * 1024)}MB)',
        );
      }

      dev.log(
        '📤 Uploading image from bytes: ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB',
      );

      final customFileName = customPublicId ?? _generatePublicId('img');

      final publicUrl = await _uploadWithRetry(() async {
        return await _supabaseService.uploadImageFromBytes(
          bytes,
          fileName: customFileName,
          folder: folder ?? 'posts',
        );
      });

      final filePath = '${folder ?? 'posts'}/$customFileName';

      return MediaUploadResult(
        publicId: filePath,
        secureUrl: publicUrl,
        originalUrl: publicUrl,
        type: MediaType.image,
        metadata: {
          'publicId': filePath,
          'url': publicUrl,
          'secureUrl': publicUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'fileSize': bytes.length,
        },
      );
    } catch (e) {
      dev.log('❌ Failed to upload image from bytes: $e');
      throw MediaUploadException('Failed to upload image from bytes: $e');
    }
  }

  /// Upload XFile (Videos)
  Future<MediaUploadResult> uploadVideoXFile(
    XFile videoFile, {
    String? folder,
    Map<String, dynamic>? tags,
    String? customPublicId,
  }) async {
    try {
      final bytes = await videoFile.readAsBytes();
      final fileSize = bytes.length;
      const maxVideoSize = 50 * 1024 * 1024; // 50MB

      if (fileSize > maxVideoSize) {
        throw MediaUploadException(
          'Video size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds maximum allowed size (${maxVideoSize / (1024 * 1024)}MB)',
        );
      }

      dev.log(
        '📤 Uploading video: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
      );

      final fileName = customPublicId ?? _generatePublicId('vid');

      final publicUrl = await _uploadWithRetry(() async {
        return await _supabaseService.uploadVideo(
          videoFile,
          folder: folder ?? 'videos',
          customFileName: fileName,
        );
      });

      final videoPath = '${folder ?? 'videos'}/$fileName';

      return MediaUploadResult(
        publicId: videoPath,
        secureUrl: publicUrl,
        originalUrl: publicUrl,
        type: MediaType.video,
        metadata: {
          'publicId': videoPath,
          'url': publicUrl,
          'secureUrl': publicUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'fileSize': fileSize,
        },
      );
    } catch (e) {
      dev.log('❌ Failed to upload video XFile: $e');
      throw MediaUploadException('Failed to upload video XFile: $e');
    }
  }

  /// Upload video file (Keep for legacy but redirected)
  Future<MediaUploadResult> uploadVideoFile(
    String filePath, {
    String? folder,
    Map<String, dynamic>? tags,
    String? customPublicId,
  }) async {
    if (kIsWeb) {
      throw MediaUploadException('uploadVideoFile (path) is not supported on Web. Use uploadVideoXFile.');
    }
    return uploadVideoXFile(XFile(filePath), folder: folder, tags: tags, customPublicId: customPublicId);
  }

  /// Upload profile picture
  Future<MediaUploadResult?> uploadProfilePicture({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image == null) return null;

      return await uploadXFile(
        image,
        folder: 'profiles',
        tags: {
          'tags': ['profile', 'avatar'],
        },
      );
    } catch (e) {
      throw MediaUploadException('Failed to upload profile picture: $e');
    }
  }

  /// Upload story media
  Future<MediaUploadResult?> uploadStoryMedia({
    required MediaType type,
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      if (type == MediaType.image) {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1920, // 9:16 aspect ratio
          imageQuality: 85,
        );

        if (image == null) return null;

        return await uploadXFile(
          image,
          folder: 'stories',
          tags: {
            'tags': ['story', 'temporary'],
          },
        );
      } else {
        final XFile? video = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );

        if (video == null) return null;

        return await uploadVideoXFile(
          video,
          folder: 'stories',
          tags: {
            'tags': ['story', 'temporary', 'video'],
          },
        );
      }
    } catch (e) {
      throw MediaUploadException('Failed to upload story media: $e');
    }
  }

  /// Upload multiple images
  Future<List<MediaUploadResult>> uploadMultipleImages({
    String? folder,
    Map<String, dynamic>? tags,
    int? maxImages,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return [];

      final List<XFile> selectedImages =
          maxImages != null && images.length > maxImages
          ? images.take(maxImages).toList()
          : images;

      final List<MediaUploadResult> results = [];

      for (final image in selectedImages) {
        final result = await uploadXFile(
          image,
          folder: folder,
          tags: tags,
        );
        results.add(result);
      }

      return results;
    } catch (e) {
      throw MediaUploadException('Failed to upload multiple images: $e');
    }
  }

  /// Delete media from Supabase
  Future<bool> deleteMedia(
    String publicIdOrUrl, {
    MediaType type = MediaType.image,
  }) async {
    try {
      // If it's a full URL, use deleteImage, otherwise construct the URL
      if (publicIdOrUrl.startsWith('http')) {
        await _supabaseService.deleteImage(publicIdOrUrl);
      } else {
        // It's a file path, construct the URL
        final url = _supabaseService.getPublicUrl(publicIdOrUrl);
        await _supabaseService.deleteImage(url);
      }
      return true;
    } catch (e) {
      dev.log('❌ Failed to delete media: $e');
      return false;
    }
  }

  /// Upload with retry logic
  Future<T> _uploadWithRetry<T>(Future<T> Function() uploadFunction) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        return await uploadFunction();
      } catch (e) {
        retryCount++;
        dev.log('❌ Upload attempt $retryCount failed: $e');

        if (retryCount < maxRetries) {
          dev.log('🔄 Retrying upload in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          rethrow;
        }
      }
    }

    throw MediaUploadException('Upload failed after $maxRetries attempts');
  }

  /// Generate unique public ID
  String _generatePublicId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 8);
    return '${prefix}_${timestamp}_$uuid';
  }

  /// Get optimized URLs for different use cases
  /// Note: Supabase doesn't have built-in image transformations
  /// All URLs return the same original image
  Map<String, String> getOptimizedUrls(String publicIdOrUrl) {
    final url = publicIdOrUrl.startsWith('http')
        ? publicIdOrUrl
        : _supabaseService.getPublicUrl(publicIdOrUrl);

    return {
      'thumbnail': url,
      'small': url,
      'medium': url,
      'large': url,
      'original': url,
    };
  }
}

class MediaUploadException implements Exception {
  final String message;
  MediaUploadException(this.message);

  @override
  String toString() => 'MediaUploadException: $message';
}
