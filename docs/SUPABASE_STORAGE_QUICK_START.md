# Supabase Storage Quick Start Guide

## 🚀 Quick Setup

### 1. Verify Configuration
Check `.env.supabase`:
```env
SUPABASE_URL=https://rniqhvmtezowdbabhogz.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_STORAGE_BUCKET=images
```

### 2. Verify Bucket Exists
Go to: https://app.supabase.com/project/rniqhvmtezowdbabhogz/storage/buckets

Bucket `images` should exist with:
- ✅ Public bucket
- ✅ File size limit: 68 MB
- ✅ Allowed MIME types: image/jpeg, image/png, image/webp

### 3. Test Upload
```dart
final supabaseService = SupabaseService();
final imageUrl = await supabaseService.uploadImage(
  imageFile,
  folder: 'test',
);
print('Uploaded: $imageUrl');
```

## 📁 Folder Structure

```
images/
├── posts/              # Post images
├── profiles/           # Profile pictures
├── stories/            # Story media
│   └── {userId}/      # User-specific stories
├── post_images/        # Legacy post images
└── profile_pictures/   # Legacy profile pictures
```

## 🔧 Common Operations

### Upload Image
```dart
final supabaseService = SupabaseService();

// From XFile (image_picker)
final url = await supabaseService.uploadImage(
  xFile,
  folder: 'posts',
  customFileName: 'my_image.jpg',
);

// From File
final url = await supabaseService.uploadImageFromFile(
  file,
  folder: 'profiles',
);

// From Bytes
final url = await supabaseService.uploadImageFromBytes(
  bytes,
  fileName: 'image.jpg',
  folder: 'posts',
);
```

### Upload Video
```dart
// From XFile
final url = await supabaseService.uploadVideo(
  videoFile,
  folder: 'videos',
);

// From File
final url = await supabaseService.uploadVideoFromFile(
  videoFile,
  folder: 'stories/user123',
);
```

### Delete Image
```dart
await supabaseService.deleteImage(imageUrl);
```

### List Files
```dart
final files = await supabaseService.listFiles(folder: 'posts');
for (final file in files) {
  print('${file.name} - ${file.metadata?['size']} bytes');
}
```

## 🎨 Using Media Upload Service

### Upload Profile Picture
```dart
final mediaService = MediaUploadService();
final result = await mediaService.uploadProfilePicture(
  source: ImageSource.gallery,
);
print('Profile picture: ${result?.secureUrl}');
```

### Upload Post Image
```dart
final result = await mediaService.pickAndUploadImageFromGallery(
  folder: 'posts',
  maxWidth: 1080,
  maxHeight: 1080,
  imageQuality: 85,
);
```

### Upload Story
```dart
final result = await mediaService.uploadStoryMedia(
  type: MediaType.image,
  source: ImageSource.camera,
);
```

### Upload Multiple Images
```dart
final results = await mediaService.uploadMultipleImages(
  folder: 'posts',
  maxImages: 5,
);
```

## 🔐 Storage Policies

### View Policies
Go to: https://app.supabase.com/project/rniqhvmtezowdbabhogz/storage/policies

### Required Policies:
1. **Public Read** - Anyone can view images
2. **Authenticated Upload** - Logged-in users can upload
3. **User Update** - Users can update their own files
4. **User Delete** - Users can delete their own files

### Apply Policies (SQL Editor):
```sql
-- Public read access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'images' );

-- Authenticated upload
CREATE POLICY "Authenticated Upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'images' AND
  auth.role() = 'authenticated'
);
```

## 🐛 Troubleshooting

### Error: "Supabase not initialized"
```dart
// Check initialization in main.dart
await SupabaseService.initialize(
  supabaseUrl: AppConfig.supabaseUrl,
  supabaseAnonKey: AppConfig.supabaseAnonKey,
);
```

### Error: "403 Forbidden"
- Check storage policies are enabled
- Verify user is authenticated
- Check bucket permissions

### Error: "Bucket not found"
- Verify bucket name is 'images'
- Check bucket exists in dashboard
- Ensure bucket is public

### Images not displaying
- Verify URL format is correct
- Check bucket is public
- Test URL in browser directly

## 📊 Monitoring

### Check Storage Usage
Dashboard: https://app.supabase.com/project/rniqhvmtezowdbabhogz/storage/usage

### View Uploaded Files
Dashboard: https://app.supabase.com/project/rniqhvmtezowdbabhogz/storage/buckets/images

### Check Logs
Dashboard: https://app.supabase.com/project/rniqhvmtezowdbabhogz/logs/storage-logs

## 💡 Best Practices

### 1. File Naming
```dart
// Use timestamps for uniqueness
final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

// Include user ID for organization
final fileName = 'profile_$userId.jpg';

// Use folders for categorization
folder: 'posts/$userId'
```

### 2. File Size Limits
```dart
// Check before upload
if (fileSize > AppConfig.maxImageSize) {
  throw 'File too large';
}

// Compress images before upload
final compressedImage = await FlutterImageCompress.compressWithFile(
  file.path,
  quality: 85,
  minWidth: 1080,
  minHeight: 1080,
);
```

### 3. Error Handling
```dart
try {
  final url = await supabaseService.uploadImage(file);
  // Success
} catch (e) {
  if (e.toString().contains('not initialized')) {
    // Handle initialization error
  } else if (e.toString().contains('403')) {
    // Handle permission error
  } else {
    // Handle other errors
  }
}
```

### 4. Cleanup Old Files
```dart
// Delete old profile picture when uploading new one
if (oldProfilePictureUrl != null) {
  await supabaseService.deleteImage(oldProfilePictureUrl);
}
```

## 🔗 Useful Links

- **Supabase Dashboard**: https://app.supabase.com/project/rniqhvmtezowdbabhogz
- **Storage Docs**: https://supabase.com/docs/guides/storage
- **Storage Policies**: https://supabase.com/docs/guides/storage/security/access-control
- **Flutter SDK**: https://supabase.com/docs/reference/dart/introduction

## ✅ Testing Checklist

- [ ] Upload profile picture
- [ ] Upload post image
- [ ] Upload story
- [ ] Upload video
- [ ] Delete image
- [ ] View uploaded images
- [ ] Test on different devices
- [ ] Test with poor network
- [ ] Test file size limits
- [ ] Test MIME type restrictions
