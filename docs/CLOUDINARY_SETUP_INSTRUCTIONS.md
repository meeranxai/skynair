# 🔧 CLOUDINARY SETUP INSTRUCTIONS

## ✅ CREDENTIALS CONFIGURED
Your Cloudinary credentials have been updated in the app:

- **Cloud Name**: `RootAPI`
- **API Key**: `542941586524339`
- **API Secret**: `1UBRhZkcCF6Ol2D2s032D6QwcaU`

## 🚀 REQUIRED: CREATE UPLOAD PRESET

You need to create an **upload preset** in your Cloudinary dashboard for the app to work:

### Steps to Create Upload Preset:

1. **Go to Cloudinary Dashboard**: https://cloudinary.com/console
2. **Login** with your RootAPI account
3. **Navigate to Settings** → **Upload** tab
4. **Click "Add upload preset"**
5. **Configure the preset**:
   - **Preset name**: `social_media_upload`
   - **Signing Mode**: `Unsigned` (important!)
   - **Folder**: Leave empty or set to `g-network`
   - **Allowed formats**: `jpg,jpeg,png,webp`
   - **Max file size**: `10MB`
   - **Image transformations**: 
     - **Quality**: `auto`
     - **Format**: `auto`
     - **Max dimensions**: `1920x1920`

6. **Save the preset**

### Alternative: Use Signed Uploads (More Secure)

If you prefer signed uploads (recommended for production):

1. Set **Signing Mode** to `Server-side signed`
2. Update the app to use signed uploads (requires backend implementation)

## 🔍 VERIFY SETUP

After creating the upload preset, test the image upload:

1. **Profile Image Upload**: Go to Profile → Edit → Change profile picture
2. **Post Image Upload**: Go to Create Post → Add Photo

## 🐛 TROUBLESHOOTING

### If you get "Upload preset not found" error:
- Double-check the preset name is exactly `social_media_upload`
- Ensure it's set to "Unsigned" mode
- Wait a few minutes for changes to propagate

### If you get "Invalid API credentials" error:
- Verify your cloud name is `RootAPI` (case-sensitive)
- Check API key and secret are correct
- Ensure your Cloudinary account is active

### If uploads are slow:
- Consider enabling auto-optimization in the upload preset
- Set appropriate image quality and format settings

## 📱 CURRENT APP CONFIGURATION

The app is now configured to:
- ✅ Upload profile images to `g-network/profiles/` folder
- ✅ Upload post images to `g-network/posts/` folder  
- ✅ Use optimized image delivery with auto quality/format
- ✅ Handle upload errors gracefully

Once you create the upload preset, image uploads should work perfectly!