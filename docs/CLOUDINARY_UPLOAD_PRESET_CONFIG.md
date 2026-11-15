# Cloudinary Upload Preset Configuration Guide

## 📋 Step-by-Step Upload Preset Setup

### 1. Access Upload Presets
- Go to your Cloudinary Dashboard
- Navigate to **Settings** → **Upload**
- Scroll down to **Upload presets** section
- Click **"Add upload preset"**

### 2. Basic Configuration

#### Upload Preset Name
```
social_media_upload
```

#### Signing Mode ⚠️ CRITICAL
```
☑️ Unsigned
☐ Signed
```
**Important**: Must select **"Unsigned"** for direct browser/app uploads

### 3. Asset Organization

#### Asset Folder
```
social_media
```
This creates organized folder structure:
- `social_media/posts/`
- `social_media/profiles/`
- `social_media/stories/`

#### Overwrite Assets
```
☑️ Overwrite assets with the same public ID
```
Allows updating profile pictures and media

### 4. Public ID Settings

#### Generated Public ID
```
☑️ Auto-generate an unguessable public ID value
☐ Use the filename of the uploaded file as the public ID
☐ Append a unique suffix
☐ Prepend a path to the public ID
```

#### Generated Display Name
```
☑️ Use the filename of the uploaded file as the asset's display name
☐ Use the last segment of the public ID as the display Name
```

### 5. File Restrictions (Recommended)

#### Allowed Formats
```
jpg,png,gif,webp,mp4,mov,jpeg
```

#### File Size Limits
```
Max file size: 10485760 (10MB)
Max image width: 2048
Max image height: 2048
Max video duration: 60 (seconds)
```

### 6. Transformations (Optional but Recommended)

#### Quality Optimization
```
Quality: auto:good
```

#### Format Optimization
```
Format: auto
```

#### Responsive Breakpoints (Optional)
```
☑️ Generate responsive breakpoints
Breakpoints: 200,400,600,800,1200
```

### 7. Advanced Settings (Optional)

#### Auto Tagging
```
☑️ Enable auto-tagging
Tags: social_media,user_content
```

#### Moderation
```
☑️ Enable moderation (if needed)
```

## 🔧 Configuration Summary

Your final upload preset should look like this:

```yaml
Upload Preset Name: social_media_upload
Signing Mode: Unsigned
Asset Folder: social_media
Overwrite: Enabled
Public ID: Auto-generate unguessable
Display Name: Use filename
Allowed Formats: jpg,png,gif,webp,mp4,mov,jpeg
Max File Size: 10MB
Quality: auto:good
Format: auto
```

## ✅ Verification Checklist

Before saving, verify:

- [ ] **Signing mode is "Unsigned"** (most important!)
- [ ] Upload preset name is `social_media_upload`
- [ ] Asset folder is set to `social_media`
- [ ] Allowed formats include common image/video types
- [ ] File size limits are appropriate for your app
- [ ] Quality and format are set to "auto" for optimization

## 🚨 Common Mistakes to Avoid

1. **❌ Setting Signing Mode to "Signed"**
   - This will cause uploads to fail from your app
   - Always use "Unsigned" for client-side uploads

2. **❌ Wrong Upload Preset Name**
   - Must match exactly: `social_media_upload`
   - Case-sensitive!

3. **❌ Restrictive File Formats**
   - Include all formats your app might use
   - Don't forget video formats if you support videos

4. **❌ Too Small File Size Limits**
   - 10MB is recommended for good quality images
   - Adjust based on your app's needs

## 🔄 After Configuration

Once you've saved the upload preset:

1. **Copy the preset name**: `social_media_upload`
2. **Update your app config** in `lib/core/config/app_config.dart`:
   ```dart
   static const String cloudinaryUploadPreset = 'social_media_upload';
   ```
3. **Test the integration** using the demo page or create post feature

## 📞 Need Help?

If uploads are failing, check:
1. Upload preset name matches exactly
2. Signing mode is "Unsigned"
3. Your Cloudinary credentials are correct
4. Internet connection is stable

## 🎯 Next Steps

After configuring the upload preset:
1. Update your app configuration with Cloudinary credentials
2. Test uploads using the Cloudinary demo page
3. Verify images appear in your Cloudinary media library
4. Check that optimized URLs are generated correctly

Your upload preset is now ready for production use! 🚀