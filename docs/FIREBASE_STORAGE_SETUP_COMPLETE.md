# Firebase Storage Setup Guide - G-Network

## ✅ Recommended Settings (From Your Screenshot)

You're on the right track! Here are the **perfect settings** for G-Network:

### Bucket Options:
- **Storage class**: Regional ✅
- **Location**: US-CENTRAL1 ✅
- **Access frequency**: Standard ✅

### Why These Settings?
- **Regional**: Lower cost, good performance for your users
- **US-CENTRAL1**: Fast, reliable, same location as Firestore
- **Standard**: Best for frequently accessed files (profile pictures, posts, stories)

## Step-by-Step Setup

### Step 1: Create Storage Bucket
1. ✅ Keep the default settings shown in your screenshot
2. ✅ Click **"Continue"** button
3. ✅ On next screen, select **"Start in production mode"**
4. ✅ Click **"Done"**

### Step 2: Deploy Storage Rules

After bucket is created, you need to add security rules.

#### Option A: Using Firebase Console (Easiest)
1. Go to: **Storage** → **Rules** tab
2. Replace the default rules with these:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }

    // Profile pictures - any authenticated user can read, only owner can write
    match /profile_pictures/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Post images - any authenticated user can read, only owner can write
    match /post_images/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Story images - any authenticated user can read, only owner can write  
    match /story_images/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Message attachments - participants can read, sender can write
    match /message_attachments/{chatId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Catch-all for any other files (more restrictive)
    match /{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

3. Click **"Publish"**

#### Option B: Using Firebase CLI
```bash
# Run the deployment script
deploy_storage_rules.bat
```

### Step 3: Test Image Upload

After rules are deployed, test the app:

```bash
# Run app
flutter run

# Test these features:
# 1. Upload profile picture
# 2. Create post with image
# 3. Create story with image
```

## Storage Structure

Your images will be organized like this:

```
studio-2145172646-5b4a0.firebasestorage.app/
├── profile_pictures/
│   └── {userId}/
│       └── profile_{timestamp}.jpg
├── post_images/
│   └── {userId}/
│       └── post_{timestamp}.jpg
└── story_images/
    └── {userId}/
        └── story_{timestamp}.jpg
```

## Security Rules Explained

### Profile Pictures
- **Read**: Any logged-in user can view
- **Write**: Only the owner can upload/update their own picture

### Post Images
- **Read**: Any logged-in user can view
- **Write**: Only the post author can upload

### Story Images
- **Read**: Any logged-in user can view
- **Write**: Only the story creator can upload

## Verification Checklist

After setup, verify:

- [ ] Storage bucket created with Regional/US-CENTRAL1/Standard
- [ ] Storage rules deployed
- [ ] Can upload profile picture
- [ ] Can upload post image
- [ ] Can upload story image
- [ ] Images load correctly in app

## Troubleshooting

### Error: "Permission Denied" when uploading
**Solution**: Make sure Storage rules are deployed (see Step 2)

### Error: "Storage bucket not configured"
**Solution**: 
1. Check `lib/firebase_options.dart` has correct `storageBucket`
2. Should be: `studio-2145172646-5b4a0.firebasestorage.app`
3. Rebuild app: `flutter clean && flutter pub get && flutter run`

### Images upload but don't display
**Solution**: Check read permissions in Storage rules

### Upload is very slow
**Solution**: 
- Check internet connection
- Consider image compression before upload
- Regional storage should be fast for most users

## Cost Optimization Tips

Firebase Storage pricing:
- **Storage**: $0.026 per GB/month
- **Download**: $0.12 per GB
- **Upload**: Free

To keep costs low:
- ✅ Compress images before upload (already implemented)
- ✅ Use Regional storage (cheaper than Multi-region)
- ✅ Delete old stories after 24 hours (already implemented)
- ✅ Limit image size (max 5MB per image)

## Next Steps

1. ✅ Click "Continue" on Firebase Console
2. ✅ Complete Storage setup
3. ✅ Deploy Storage rules (Option A or B above)
4. ✅ Test image upload in app
5. ✅ Verify images display correctly

## Summary

✅ **Perfect settings selected**: Regional, US-CENTRAL1, Standard
✅ **Storage bucket**: studio-2145172646-5b4a0.firebasestorage.app
✅ **Rules ready**: Copy from this guide
✅ **App ready**: Already configured to use Firebase Storage

---

**Current Status**: Waiting for you to click "Continue" in Firebase Console
**Next**: Deploy Storage rules and test!
