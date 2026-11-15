# Media Post Fetch Issue - Debug Guide

## Problem (مسئلہ)
Media/image posts create ho rahe hain lekin feed mein sirf text show ho raha hai, images nahi aa rahi.

## Possible Causes (ممکنہ وجوہات)

### 1. Firebase Storage Rules Issue
**Check:** Firebase Console → Storage → Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /post_images/{userId}/{imageId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /profile_pictures/{userId}/{imageId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 2. Image URL Not Saved in Firestore
**Check:** Firebase Console → Firestore → posts collection

Har post document mein ye fields hone chahiye:
- `title`: "Post title"
- `description`: "Post description"
- `image`: "https://firebasestorage.googleapis.com/..." ← **YE FIELD CHECK KAREIN**
- `authorId`: "user_id"
- `createdAt`: timestamp

**If `image` field is null or missing:**
- Image upload fail ho rahi hai
- Check console logs for upload errors

### 3. Network/CORS Issue
Images load nahi ho rahi due to network restrictions.

**Check:**
- Internet connection
- Firewall settings
- Antivirus blocking Firebase Storage

### 4. Image URL Format Issue
**Check:** Firestore mein image URL ka format:

✅ **Correct:**
```
https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/post_images%2Fuser123%2F1234567890.jpg?alt=media&token=abc123
```

❌ **Incorrect:**
```
null
""
"local/path/to/image.jpg"
```

## Debug Steps (ڈیبگ کرنے کے قدم)

### Step 1: Check Console Logs
```bash
test_media_post_fetch.bat
```

Look for these messages:
```
🔄 Uploading post image to Firebase Storage for user: xxx
✅ Post image uploaded successfully to Firebase Storage: https://...
✅ Post created: post_id_here
```

### Step 2: Check Firebase Console

#### A. Storage Tab
1. Go to Firebase Console → Storage
2. Check if `post_images` folder exists
3. Check if your uploaded images are there
4. Click on an image → Copy URL
5. Paste URL in browser to verify it loads

#### B. Firestore Tab
1. Go to Firebase Console → Firestore
2. Open `posts` collection
3. Find your latest post
4. Check if `image` field has a URL
5. Copy the URL and test in browser

### Step 3: Test Image Display

Run this command to check if feed_card is displaying images:
```dart
// In feed_card.dart, the image section should show:
if (widget.post.image != null)
  Container(
    child: CachedNetworkImage(
      imageUrl: widget.post.image!,  // ← This should have a valid URL
      ...
    ),
  ),
```

### Step 4: Check Storage Rules

1. Firebase Console → Storage → Rules
2. Make sure read access is public:
```
allow read: if true;
```

3. Deploy rules:
```bash
firebase deploy --only storage
```

## Quick Fix Commands

### Fix 1: Redeploy Storage Rules
```bash
firebase deploy --only storage
```

### Fix 2: Clear App Cache
```bash
flutter clean
flutter pub get
flutter run
```

### Fix 3: Check Firestore Data
Open Firebase Console and manually check:
1. Go to Firestore Database
2. Click on `posts` collection
3. Find a post with image
4. Verify `image` field has URL

## Testing Checklist

- [ ] Create new post with image
- [ ] Check console for upload success message
- [ ] Check Firebase Storage for uploaded image
- [ ] Check Firestore for image URL in post document
- [ ] Check if image displays in feed
- [ ] Test on different network
- [ ] Test with different image file

## Common Solutions

### Solution 1: Storage Rules Not Deployed
```bash
cd your-project
firebase deploy --only storage
```

### Solution 2: Image Upload Failing Silently
Check `lib/core/providers/posts_provider.dart` line 175-180:
```dart
if (imageFile != null) {
  try {
    uploadedImageUrl = await FirestoreService.uploadPostImage(
      imageFile,
      currentUser.uid,
    );
  } catch (e) {
    // Check this error in console
    print('Image upload error: $e');
  }
}
```

### Solution 3: CachedNetworkImage Not Loading
Check internet connection and Firebase Storage URL accessibility.

## Expected Behavior

1. **Upload:** Image uploads to Firebase Storage
2. **Save:** Image URL saves to Firestore `posts` collection
3. **Fetch:** Posts fetch with image URLs
4. **Display:** `feed_card.dart` displays images using `CachedNetworkImage`

## Contact Points

If issue persists, check:
1. Firebase Console → Storage → Files
2. Firebase Console → Firestore → posts collection
3. App console logs during post creation
4. Network tab in browser DevTools (if web)

## Status Check Command

```bash
# Run this to see detailed logs
flutter run -d windows --verbose | findstr "image"
```

This will show all image-related logs.
