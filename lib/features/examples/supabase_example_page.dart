import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/media_upload_widget.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/services/supabase_service.dart';

class SupabaseExamplePage extends ConsumerStatefulWidget {
  const SupabaseExamplePage({super.key});

  @override
  ConsumerState<SupabaseExamplePage> createState() =>
      _SupabaseExamplePageState();
}

class _SupabaseExamplePageState extends ConsumerState<SupabaseExamplePage> {
  List<MediaUploadResult> uploadedImages = [];
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Storage Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supabase Media Upload Demo',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test image and video uploads with Supabase Storage',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Sections
            _buildUploadSection(
              'Single Image Upload',
              'Upload one image from gallery or camera',
              MediaUploadWidget(
                folder: 'demo/single',
                tags: {
                  'tags': ['demo', 'single-upload'],
                },
                uploadText: 'Upload Single Image',
                onUploadSuccess: (result) {
                  setState(() {
                    uploadedImages.add(result);
                  });
                  _showSuccessSnackBar('Image uploaded successfully!');
                },
                onUploadError: (error) {
                  _showErrorSnackBar('Upload failed: $error');
                },
              ),
            ),

            const SizedBox(height: 16),

            _buildUploadSection(
              'Multiple Images Upload',
              'Upload multiple images at once',
              MediaUploadWidget(
                folder: 'demo/multiple',
                tags: {
                  'tags': ['demo', 'multiple-upload'],
                },
                allowMultiple: true,
                uploadText: 'Upload Multiple Images',
                onUploadSuccess: (result) {
                  setState(() {
                    uploadedImages.add(result);
                  });
                  _showSuccessSnackBar('Image uploaded successfully!');
                },
                onUploadError: (error) {
                  _showErrorSnackBar('Upload failed: $error');
                },
              ),
            ),

            const SizedBox(height: 16),

            _buildUploadSection(
              'Video Upload',
              'Upload videos with automatic thumbnail generation',
              MediaUploadWidget(
                folder: 'demo/videos',
                tags: {
                  'tags': ['demo', 'video-upload'],
                },
                allowVideo: true,
                uploadText: 'Upload Video',
                onUploadSuccess: (result) {
                  setState(() {
                    uploadedImages.add(result);
                  });
                  _showSuccessSnackBar('Video uploaded successfully!');
                },
                onUploadError: (error) {
                  _showErrorSnackBar('Upload failed: $error');
                },
              ),
            ),

            const SizedBox(height: 24),

            // Profile Picture Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Profile Picture Upload Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ProfilePictureUploadWidget(
                      onUploadSuccess: (result) {
                        setState(() {
                          uploadedImages.add(result);
                        });
                        _showSuccessSnackBar('Profile picture updated!');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Story Upload Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Story Upload Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StoryUploadWidget(
                          onUploadSuccess: (result) {
                            setState(() {
                              uploadedImages.add(result);
                            });
                            _showSuccessSnackBar('Story media uploaded!');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Uploaded Images Gallery
            if (uploadedImages.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uploaded Media (${uploadedImages.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                uploadedImages.clear();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: uploadedImages.length,
                        itemBuilder: (context, index) {
                          final media = uploadedImages[index];
                          return _buildMediaTile(media);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // URL Generation Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploaded URLs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (uploadedImages.isNotEmpty) ...[
                      _buildUrlExample(
                        'Original URL',
                        uploadedImages.first.secureUrl,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Supabase returns original images. For transformations, consider using a CDN like Cloudflare Images or imgix.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Upload an image to see the URL',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(
    String title,
    String description,
    Widget uploadWidget,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            uploadWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTile(MediaUploadResult media) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.type == MediaType.image)
            Image.network(
              media.secureUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.red),
                );
              },
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.play_circle_filled, size: 48),
              ),
            ),

          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                media.type == MediaType.image ? Icons.image : Icons.videocam,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Text(
                media.publicId.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlExample(String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              url,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
