# 🚀 Cloudinary Quick Setup - Exact Configuration

## Upload Preset Settings (Copy These Exactly)

### Basic Settings
```
Upload preset name: social_media_upload
Signing mode: Unsigned ✅
```

### Asset Organization
```
Asset folder: social_media
```
(This will organize uploads in: social_media/posts/, social_media/profiles/, etc.)

### Public ID Settings
```
☐ Disallow public ID
☑️ Generated public ID: Auto-generate an unguessable public ID value
☐ Use the filename of the uploaded file as the public ID
☐ Append a unique suffix
☐ Prepend a path to the public ID
```

### Display Name Settings
```
☑️ Use the filename of the uploaded file as the asset's display name
☐ Use the last segment of the public ID as the display Name
```

## 📋 Step-by-Step Instructions

1. **Upload preset name**: Type `social_media_upload`

2. **Signing mode**: Select `Unsigned` (very important!)

3. **Asset folder**: Type `social_media`

4. **Disallow public ID**: Leave unchecked ☐

5. **Generated public ID**: Select `Auto-generate an unguessable public ID value` ☑️

6. **Generated display name**: Select `Use the filename of the uploaded file as the asset's display name` ☑️

7. Click **Save**

## ✅ Your Configuration Should Look Like This:

```
✅ Upload preset name: social_media_upload
✅ Signing mode: Unsigned
✅ Asset folder: social_media
☐ Disallow public ID
✅ Generated public ID: Auto-generate an unguessable public ID value
✅ Generated display name: Use the filename of the uploaded file as the asset's display name
```

## 🔧 After Saving the Preset

Update your Flutter app configuration in `lib/core/config/app_config.dart`:

```dart
// Cloudinary Configuration
static const String cloudinaryCloudName = 'your-actual-cloud-name'; // From dashboard
static const String cloudinaryApiKey = 'your-actual-api-key'; // From dashboard  
static const String cloudinaryApiSecret = 'your-actual-api-secret'; // From dashboard
static const String cloudinaryUploadPreset = 'social_media_upload'; // Exact preset name
```

## 🧪 Test Your Setup

Run this command to test:
```bash
test_cloudinary_integration.bat
```

Or use the demo page in your app to test uploads.

## ⚠️ Important Notes

- **Signing mode MUST be "Unsigned"** - this allows direct uploads from your Flutter app
- **Upload preset name is case-sensitive** - must be exactly `social_media_upload`
- **Auto-generate public ID** ensures unique identifiers for each upload
- **Asset folder** organizes your media but doesn't affect public ID paths

That's it! Your Cloudinary integration is ready to use. 🎉