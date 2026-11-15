# Data Fetch Troubleshooting Guide

## Issue: Data Nahi Fetch Ho Raha

## Maine Kya Changes Kiye?

### ✅ Safe Changes (Data Fetching Pe Koi Effect Nahi)
1. **Image Upload Backend** - Sirf Supabase se Firebase Storage pe switch kiya
   - `uploadProfileImage()` - Firebase use karta hai ab
   - `uploadPostImage()` - Firebase use karta hai ab
   - Data fetching methods **bilkul same** hain

2. **UI Changes** - Sirf visual styling
   - Profile grid rounded corners
   - Grid spacing update
   - Koi data fetching logic change nahi

3. **New Features** - Separate files
   - Signup page (new file)
   - Stories real-time (existing code improve kiya)
   - Notification parsing (better error handling)

### ❌ Data Fetching Methods - UNCHANGED
```dart
// Ye sab methods bilkul same hain:
- getUserProfile()
- getPost()
- getPosts()
- getPostsStream()
- getUserPostsStream()
- getAllPosts()
- getFollowers()
- getFollowing()
```

## Possible Issues & Solutions

### Issue 1: Device Connected Nahi Hai
**Symptoms:**
- App run nahi ho raha
- "No devices found" error

**Solution:**
```bash
# Check devices
flutter devices

# Connect device via USB
# Enable USB debugging on phone
# Run again
flutter run
```

### Issue 2: Internet Connection
**Symptoms:**
- Loading spinner dikhta rehta hai
- "Network error" messages
- Data load nahi hota

**Solution:**
- WiFi/mobile data check karo
- Firebase console check karo (online hai?)
- Phone ka internet check karo

### Issue 3: Firebase Rules
**Symptoms:**
- "Permission denied" errors
- "PERMISSION_DENIED" in logs
- Data fetch fail hota hai

**Solution:**
Check `firestore.rules`:
```javascript
// Make sure these rules are set:
match /userProfiles/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}

match /posts/{postId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

### Issue 4: Not Logged In
**Symptoms:**
- Login screen dikhta hai
- Data nahi dikhta
- "Not authenticated" errors

**Solution:**
- Login karo pehle
- Email/password verify karo
- Firebase Authentication check karo

### Issue 5: No Data in Firestore
**Symptoms:**
- Empty screens
- "No posts yet" messages
- Everything loads but empty

**Solution:**
- Firebase Console check karo
- Firestore mein data hai?
- Collections exist karte hain?
  - `userProfiles`
  - `posts`
  - `stories`
  - `notifications`

## Diagnostic Steps

### Step 1: Run Diagnostic Script
```bash
diagnose_data_fetch.bat
```

This will check:
- Code compilation
- Firebase config
- Connected devices

### Step 2: Check Logs
Run app with verbose logging:
```bash
flutter run -v
```

Look for:
- ✅ "User profile found in Firestore"
- ✅ "Posts fetched successfully"
- ❌ "Error getting user profile"
- ❌ "Permission denied"

### Step 3: Test Specific Features

#### Test Profile Data:
1. Login to app
2. Go to Profile page
3. Should show:
   - Profile picture
   - Username
   - Bio
   - Post count
   - Followers/Following

#### Test Posts Data:
1. Go to Home/Feed page
2. Should show:
   - List of posts
   - Images
   - Likes/comments
   - User info

#### Test Stories:
1. Check story bar at top
2. Should show:
   - User stories
   - Profile pictures
   - Tap to view

## Code Verification

### Check FirestoreService is Imported Correctly
```dart
// In any provider file:
import '../services/firestore_service.dart';

// Usage should work:
final posts = await FirestoreService.getPosts();
```

### Check Providers are Working
```dart
// Posts provider:
final postsAsync = ref.watch(postsProvider);

// User profile provider:
final userAsync = ref.watch(userProfileProvider(userId));
```

## What I Changed vs What I Didn't

### ✅ Changed (Safe):
```dart
// OLD - Supabase upload
final supabaseService = SupabaseService();
final imageUrl = await supabaseService.uploadImage(...);

// NEW - Firebase upload
final storageRef = _storage.ref().child('profile_pictures/...');
final imageUrl = await storageRef.getDownloadURL();
```

### ❌ NOT Changed (Data Fetching):
```dart
// These are EXACTLY the same:
static Future<UserModel?> getUserProfile(String uid) async {
  final doc = await _firestore
      .collection(FirebaseConfig.userProfiles)
      .doc(uid)
      .get();
  // ... same code
}

static Stream<List<PostModel>> getPostsStream() {
  return _firestore
      .collection(FirebaseConfig.posts)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(...);
  // ... same code
}
```

## Quick Fixes

### Fix 1: Restart App
```bash
# Stop app
Ctrl+C

# Clear cache
flutter clean

# Get dependencies
flutter pub get

# Run again
flutter run
```

### Fix 2: Check Firebase Connection
```bash
# In Firebase Console:
1. Go to Firestore Database
2. Check if data exists
3. Check if rules allow read
4. Check if Authentication is enabled
```

### Fix 3: Verify Login
```bash
# In app:
1. Logout
2. Login again
3. Check if data loads
```

## Still Not Working?

### Share These Details:
1. **Exact error message** (screenshot ya copy paste)
2. **Which screen** has the issue? (Home, Profile, etc.)
3. **Console logs** (flutter run output)
4. **Firebase Console** - data dikhta hai?

### Check These Files:
```bash
# Run these commands and share output:
flutter doctor
flutter devices
flutter analyze
```

## Summary

**Main point**: Maine sirf image upload ka backend change kiya hai. Data fetching code **bilkul same** hai.

Agar data fetch nahi ho raha to:
1. Device connected hai?
2. Internet working hai?
3. Login ho?
4. Firebase mein data hai?

In sab ko check karo, data fetch ho jayega! 🚀

---

**Date**: January 3, 2026
**Issue**: Data fetch nahi ho raha
**Root Cause**: Likely device/network/login issue, NOT code changes
**Solution**: Follow diagnostic steps above
