# Cloudinary Integration Setup Guide

## Overview
This guide will help you set up Cloudinary for media and image handling in your Flutter social media app. Cloudinary provides powerful image and video management capabilities including upload, storage, optimization, and transformation.

## Prerequisites
- Flutter development environment
- Cloudinary account (free tier available)
- Basic understanding of Flutter and Dart

## Step 1: Create Cloudinary Account

1. Go to [Cloudinary](https://cloudinary.com/) and sign up for a free account
2. After registration, you'll get access to your dashboard
3. Note down your credentials from the dashboard:
   - Cloud Name
   - API Key
   - API Secret

## Step 2: Configure Upload Preset

1. In your Cloudinary dashboard, go to **Settings** → **Upload**
2. Scroll down to **Upload presets**
3. Click **Add upload preset**
4. Configure the preset with these exact settings:

### Basic Settings:
- **Upload preset name**: `social_media_upload`
- **Signing mode**: **Unsigned** ⚠️ (Important: Select 'Unsigned' for uploading directly from the browser)

### Asset Organization:
- **Asset folder**: `social_media` (This will organize all uploads in a social_media folder)
- **Overwrite assets with the same public ID**: ✅ Enabled (allows updating profile pictures)

### Public ID Generation:
- **Generated public ID**: Select **"Auto-generate an unguessable public ID value"**
- **Generated display name**: Select **"Use the filename of the uploaded file as the asset's display name"**

### File Restrictions (Optional but Recommended):
- **Allowed formats**: `jpg,png,gif,webp,mp4,mov,jpeg`
- **Max file size**: `10MB` (adjust based on your needs)
- **Max image width**: `2048px`
- **Max image height**: `2048px`

### Transformations (Optional):
- **Quality**: `auto:good` (automatic quality optimization)
- **Format**: `auto` (automatic format selection - WebP when supported)

5. **Save the preset**

### Important Notes:
- ⚠️ **Signing Mode MUST be "Unsigned"** - This allows direct uploads from your Flutter app
- The **Asset folder** helps organize your media but doesn't affect the public ID path
- **Auto-generate public ID** ensures unique identifiers for each upload
- These settings match exactly what the integration expects

## Step 3: Update App Configuration

1. Open `lib/core/config/app_config.dart`
2. Replace the placeholder values with your actual Cloudinary credentials:

```dart
// Cloudinary Configuration
static const String cloudinaryCloudName = 'your-actual-cloud-name';
static const String cloudinaryApiKey = 'your-actual-api-key';
static const String cloudinaryApiSecret = 'your-actual-api-secret';
static const String cloudinaryUploadPreset = 'social_media_upload'; // Your preset name
```

## Step 4: Install Dependencies

The required dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  cloudinary_public: ^0.23.1
  cloudinary_url_gen: ^1.6.0
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
```

Run the following command to install them:

```bash
flutter pub get
```

## Step 5: Initialize Cloudinary Service

The Cloudinary service is automatically initialized in `main.dart`. No additional setup required.

## Step 6: Usage Examples

### Basic Image Upload

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/media_upload_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final result = await ref
            .read(mediaUploadProvider.notifier)
            .uploadImageFromGallery(
              folder: 'posts',
              tags: {'tags': ['user-content']},
            );
        
        if (result != null) {
          print('Image uploaded: ${result.secureUrl}');
        }
      },
      child: Text('Upload Image'),
    );
  }
}
```

### Using MediaUploadWidget

```dart
import '../core/widgets/media_upload_widget.dart';

MediaUploadWidget(
  folder: 'posts',
  tags: {'tags': ['post', 'user-content']},
  allowVideo: true,
  allowMultiple: false,
  onUploadSuccess: (result) {
    print('Upload successful: ${result.secureUrl}');
  },
  onUploadError: (error) {
    print('Upload failed: $error');
  },
)
```

### Profile Picture Upload

```dart
import '../core/widgets/media_upload_widget.dart';

ProfilePictureUploadWidget(
  currentImageUrl: user.profilePictureUrl,
  onUploadSuccess: (result) {
    // Update user profile with new image URL
    updateUserProfile(result.secureUrl);
  },
)
```

### Story Upload

```dart
StoryUploadWidget(
  onUploadSuccess: (result) {
    // Create new story with uploaded media
    createStory(result);
  },
)
```

## Step 7: Image Optimization

Cloudinary automatically optimizes images. You can get different sizes:

```dart
final cloudinaryService = CloudinaryService();

// Get optimized URLs
final thumbnailUrl = cloudinaryService.getThumbnailUrl(publicId, size: 150);
final profileUrl = cloudinaryService.getProfilePictureUrl(publicId, size: 200);
final postUrl = cloudinaryService.getPostImageUrl(publicId, size: 600);

// Custom optimization
final customUrl = cloudinaryService.getOptimizedImageUrl(
  publicId,
  width: 800,
  height: 600,
  quality: 'auto',
  crop: true,
);
```

## Step 8: Environment Variables (Optional)

For better security, you can use environment variables:

1. Create `.env` file in your project root:
```
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
CLOUDINARY_UPLOAD_PRESET=your-upload-preset
```

2. Add `flutter_dotenv` to your dependencies
3. Load environment variables in your app

## Features Included

### ✅ Image Upload
- Gallery selection
- Camera capture
- Multiple image upload
- Progress tracking
- Error handling

### ✅ Video Upload
- Video selection from gallery
- Video recording
- Automatic thumbnail generation

### ✅ Image Optimization
- Automatic format conversion (WebP, AVIF)
- Quality optimization
- Responsive images
- Custom transformations

### ✅ Specialized Widgets
- Profile picture upload with circular crop
- Story upload with 9:16 aspect ratio
- Post image upload with square crop
- Generic media upload widget

### ✅ State Management
- Riverpod integration
- Upload progress tracking
- Error state handling
- Success callbacks

### ✅ URL Generation
- Thumbnail URLs
- Profile picture URLs
- Post image URLs
- Story image URLs
- Custom transformation URLs

## Folder Structure

The integration creates the following folder structure in Cloudinary:

```
social_media/
├── posts/          # Post images
├── profiles/       # Profile pictures
├── stories/        # Story media (temporary)
└── videos/         # Video content
```

## Security Considerations

1. **Upload Presets**: Use unsigned upload presets for client-side uploads
2. **Folder Organization**: Organize media in folders for better management
3. **File Size Limits**: Set appropriate file size limits in your upload preset
4. **Format Restrictions**: Limit allowed file formats for security
5. **Auto-moderation**: Enable Cloudinary's auto-moderation features if needed

## Troubleshooting

### Common Issues

1. **Upload Fails with "Invalid upload preset"**
   - ✅ Check upload preset name matches exactly: `social_media_upload`
   - ✅ Verify preset exists in your Cloudinary dashboard
   - ✅ Ensure preset is saved and active

2. **Upload Fails with "Unauthorized"**
   - ✅ Verify Signing Mode is set to **"Unsigned"**
   - ✅ Check your Cloudinary credentials (Cloud Name, API Key)
   - ✅ Ensure you're using the correct cloud name

3. **Images Not Loading**
   - ✅ Check the generated URLs in browser
   - ✅ Verify images exist in Cloudinary Media Library
   - ✅ Check network connectivity
   - ✅ Verify public ID is correct

4. **Slow Upload**
   - ✅ Reduce image quality in ImagePicker settings
   - ✅ Implement image compression before upload
   - ✅ Check network speed
   - ✅ Consider smaller file size limits

5. **File Format Rejected**
   - ✅ Check allowed formats in upload preset
   - ✅ Verify file extension is supported
   - ✅ Ensure file isn't corrupted

### Upload Preset Verification

To verify your upload preset is configured correctly:

1. **Test Upload via Cloudinary Console**:
   - Go to Media Library in Cloudinary dashboard
   - Try uploading a test image
   - Select your `social_media_upload` preset
   - Verify it works

2. **Check Preset Settings**:
   ```
   Settings → Upload → Upload presets → social_media_upload
   ```
   Verify:
   - Signing Mode: Unsigned ✅
   - Asset Folder: social_media ✅
   - Status: Active ✅

3. **Test API Call**:
   You can test the preset with a simple curl command:
   ```bash
   curl -X POST \
     https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload \
     -F "file=@test_image.jpg" \
     -F "upload_preset=social_media_upload"
   ```

### Debug Mode

Enable debug logging in your Flutter app:

```dart
import 'dart:developer' as developer;

// In CloudinaryService
developer.log('Uploading to Cloudinary with preset: ${AppConfig.cloudinaryUploadPreset}');
developer.log('Cloud name: ${AppConfig.cloudinaryCloudName}');
```

## Performance Tips

1. **Image Compression**: Compress images before upload
2. **Lazy Loading**: Use `cached_network_image` for efficient loading
3. **Thumbnail Generation**: Use Cloudinary's automatic thumbnail generation
4. **Progressive Loading**: Implement progressive image loading
5. **Caching**: Enable proper caching for uploaded images

## Next Steps

1. Test the integration with sample uploads
2. Customize the UI components to match your app design
3. Implement additional features like image filters or effects
4. Set up proper error handling and user feedback
5. Configure analytics and monitoring

## Support

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Cached Network Image](https://pub.dev/packages/cached_network_image)

## Cost Considerations

Cloudinary offers a generous free tier:
- 25 GB storage
- 25 GB bandwidth per month
- 1,000 transformations per month

Monitor your usage in the Cloudinary dashboard and upgrade as needed.

---

Your Cloudinary integration is now ready! The app supports image and video uploads with automatic optimization and responsive delivery.