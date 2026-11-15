import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:developer';
import 'package:path/path.dart' as path;

/// Supabase Service - Handles all media storage operations
/// Replaces Cloudinary for image and video uploads
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _bucketName = 'images';

  // Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  bool _isInitialized = false;

  /// Initialize Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      log('🔄 Initializing Supabase...');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _instance._isInitialized = true;
      log('✅ Supabase initialized successfully');

      // Check if bucket exists, create if not
      await _instance._ensureBucketExists();
    } catch (e) {
      log('❌ Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Ensure storage bucket exists
  Future<void> _ensureBucketExists() async {
    try {
      log('🔄 Checking if storage bucket exists...');

      // Try to get bucket info
      final buckets = await _client.storage.listBuckets();
      final bucketExists = buckets.any((b) => b.name == _bucketName);

      if (!bucketExists) {
        log('📝 Creating storage bucket: $_bucketName');
        await _client.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: true,
            fileSizeLimit: '8388608', // 8MB as string (matching AppConfig)
            allowedMimeTypes: [
              'image/jpeg',
              'image/jpg',
              'image/png',
              'image/gif',
              'image/webp',
              'video/mp4',
              'video/quicktime',
            ],
          ),
        );
        log('✅ Storage bucket created successfully');
      } else {
        log('✅ Storage bucket already exists');
      }
    } catch (e) {
      log('⚠️ Error checking/creating bucket: $e');
      // Don't throw - bucket might exist but we don't have permission to list
    }
  }

  /// Upload image from XFile
  Future<String> uploadImage(
    XFile imageFile, {
    String folder = 'posts',
    String? customFileName,
    bool upsert = false,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    try {
      log('🔄 Uploading image to Supabase...');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get extension from name (web-compatible) or path (mobile)
      String extension = '';
      if (imageFile.name.isNotEmpty) {
        // Use name for web (e.g., "photo.jpg")
        extension = path.extension(imageFile.name);
      } else if (imageFile.path.isNotEmpty &&
          !imageFile.path.startsWith('blob:')) {
        // Use path for mobile (e.g., "/path/to/photo.jpg")
        extension = path.extension(imageFile.path);
      }

      // Fallback to .jpg if no extension found
      if (extension.isEmpty) {
        extension = '.jpg';
      }

      final fileName = customFileName ?? 'image_$timestamp$extension';
      final filePath = '$folder/$fileName';

      // Get MIME type from name first, then path, then default
      String? mimeType;
      if (imageFile.name.isNotEmpty) {
        mimeType = lookupMimeType(imageFile.name);
      }
      if (mimeType == null && imageFile.path.isNotEmpty) {
        mimeType = lookupMimeType(imageFile.path);
      }
      mimeType ??= 'image/jpeg';

      log('📤 Uploading to: $filePath');
      log('📊 File size: ${bytes.length} bytes');
      log('📋 MIME type: $mimeType');

      // Get current user ID for owner metadata (only if using Supabase Auth)
      final userId = _client.auth.currentUser?.id;

      // Upload to Supabase Storage
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true, // ALWAYS upsert to avoid duplicate conflict errors
              // Only attach owner metadata if we actually have a Supabase user
              // Otherwise, we rely on bucket policies for 'anon' role
              metadata: userId != null ? {'owner': userId} : {}, 
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      log('✅ Image uploaded successfully');
      log('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      log('❌ Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload image from File/XFile (Legacy wrapper)
  Future<String> uploadImageFromFile(
    XFile imageFile, {
    String folder = 'posts',
    String? customFileName,
    bool upsert = false,
  }) async {
    return uploadImage(imageFile, folder: folder, customFileName: customFileName, upsert: upsert);
  }

  /// Upload image from bytes
  Future<String> uploadImageFromBytes(
    Uint8List bytes, {
    required String fileName,
    String folder = 'posts',
    String mimeType = 'image/jpeg',
    bool upsert = false,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    try {
      log('🔄 Uploading image from bytes to Supabase...');

      final filePath = '$folder/$fileName';

      log('📤 Uploading to: $filePath');
      log('📊 File size: ${bytes.length} bytes');

      // Get current user ID for owner metadata
      final userId = _client.auth.currentUser?.id;

      // Upload to Supabase Storage
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: upsert,
              metadata: userId != null ? {'owner': userId} : {},
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      log('✅ Image uploaded successfully');
      log('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      log('❌ Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete image
  Future<void> deleteImage(String imageUrl) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    try {
      log('🔄 Deleting image from Supabase...');

      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and file path
      final bucketIndex = pathSegments.indexOf('object');
      if (bucketIndex == -1 || bucketIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid Supabase URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 2).join('/');

      log('🗑️ Deleting: $filePath');

      // Delete from Supabase Storage
      await _client.storage.from(_bucketName).remove([filePath]);

      log('✅ Image deleted successfully');
    } catch (e) {
      log('❌ Error deleting image: $e');
      rethrow;
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String filePath) {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    return _client.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// List files in a folder
  Future<List<FileObject>> listFiles({String folder = 'posts'}) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    try {
      log('🔄 Listing files in folder: $folder');

      final files = await _client.storage.from(_bucketName).list(path: folder);

      log('✅ Found ${files.length} files');

      return files;
    } catch (e) {
      log('❌ Error listing files: $e');
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Generate optimized image URL with transformations
  /// Supabase doesn't have built-in transformations like Cloudinary,
  /// so we return the original URL. For production, consider using
  /// a CDN with image transformation capabilities.
  String getOptimizedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
    bool crop = true,
  }) {
    // For Supabase, we return the original URL
    // In production, you might want to use a service like imgix or Cloudflare Images
    return imageUrl;
  }

  /// Generate thumbnail URL
  String getThumbnailUrl(
    String imageUrl, {
    int size = 150,
    String quality = 'auto',
  }) {
    return getOptimizedImageUrl(
      imageUrl,
      width: size,
      height: size,
      quality: quality,
      crop: true,
    );
  }

  /// Generate profile picture URL
  String getProfilePictureUrl(String imageUrl, {int size = 200}) {
    return getOptimizedImageUrl(
      imageUrl,
      width: size,
      height: size,
      crop: true,
    );
  }

  /// Generate story image URL (9:16 aspect ratio)
  String getStoryImageUrl(
    String imageUrl, {
    int width = 400,
    int height = 711, // 9:16 aspect ratio
  }) {
    return getOptimizedImageUrl(
      imageUrl,
      width: width,
      height: height,
      crop: true,
    );
  }

  /// Generate post image URL (1:1 aspect ratio)
  String getPostImageUrl(String imageUrl, {int size = 600}) {
    return getOptimizedImageUrl(
      imageUrl,
      width: size,
      height: size,
      crop: true,
    );
  }

  /// Generate video thumbnail
  String getVideoThumbnail(
    String videoUrl, {
    int width = 400,
    int height = 300,
  }) {
    // Supabase doesn't generate video thumbnails automatically
    // Return the video URL as-is
    return videoUrl;
  }

  /// Upload video from File/XFile (Legacy wrapper)
  Future<String> uploadVideoFromFile(
    XFile videoFile, {
    String folder = 'videos',
    String? customFileName,
    bool upsert = false,
  }) async {
    return uploadVideo(videoFile, folder: folder, customFileName: customFileName, upsert: upsert);
  }

  /// Upload video from XFile
  Future<String> uploadVideo(
    XFile videoFile, {
    String folder = 'videos',
    String? customFileName,
    bool upsert = false,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }

    try {
      log('🔄 Uploading video to Supabase...');

      // Read file as bytes
      final bytes = await videoFile.readAsBytes();

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get extension from name (web-compatible) or path (mobile)
      String extension = '';
      if (videoFile.name.isNotEmpty) {
        extension = path.extension(videoFile.name);
      } else if (videoFile.path.isNotEmpty &&
          !videoFile.path.startsWith('blob:')) {
        extension = path.extension(videoFile.path);
      }

      // Fallback to .mp4 if no extension found
      if (extension.isEmpty) {
        extension = '.mp4';
      }

      final fileName = customFileName ?? 'video_$timestamp$extension';
      final filePath = '$folder/$fileName';

      // Get MIME type
      String? mimeType;
      if (videoFile.name.isNotEmpty) {
        mimeType = lookupMimeType(videoFile.name);
      }
      if (mimeType == null && videoFile.path.isNotEmpty) {
        mimeType = lookupMimeType(videoFile.path);
      }
      mimeType ??= 'video/mp4';

      log('📤 Uploading video to: $filePath');
      log('📊 File size: ${bytes.length} bytes');
      log('📋 MIME type: $mimeType');

      // Get current user ID for owner metadata
      final userId = _client.auth.currentUser?.id;

      // Upload to Supabase Storage with owner metadata
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true, // ALWAYS upsert to avoid duplicate conflict errors
              metadata: userId != null ? {'owner': userId} : null,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      log('✅ Video uploaded successfully');
      log('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      log('❌ Error uploading video: $e');
      rethrow;
    }
  }
}

/// Extension for easy URL generation (compatibility with Cloudinary)
extension SupabaseImageUrl on String {
  String toSupabaseUrl({
    int? width,
    int? height,
    String quality = 'auto',
    bool crop = true,
  }) {
    return SupabaseService().getOptimizedImageUrl(
      this,
      width: width,
      height: height,
      quality: quality,
      crop: crop,
    );
  }

  String toThumbnail({int size = 150}) {
    return SupabaseService().getThumbnailUrl(this, size: size);
  }

  String toProfilePicture({int size = 200}) {
    return SupabaseService().getProfilePictureUrl(this, size: size);
  }
}
