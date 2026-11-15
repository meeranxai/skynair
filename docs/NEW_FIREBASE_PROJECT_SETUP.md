# New Firebase Project Setup Complete!

## ✅ Firebase Configuration Updated

Your app is now connected to the new Firebase project:

**Project ID**: `studio-2145172646-5b4a0`
**Project Name**: Studio 2145172646

## What Was Changed?

Updated `lib/firebase_options.dart` with new project credentials:
- API Key: `AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI`
- Project ID: `studio-2145172646-5b4a0`
- Storage Bucket: `studio-2145172646-5b4a0.firebasestorage.app`

## Next Steps: Setup New Firebase Project

### Step 1: Enable Authentication
1. Go to: https://console.firebase.google.com/
2. Select project: **studio-2145172646-5b4a0**
3. Go to: **Authentication** → **Get Started**
4. Enable **Email/Password** sign-in method
5. (Optional) Enable **Google** sign-in

### Step 2: Create Firestore Database
1. Go to: **Firestore Database** → **Create Database**
2. Select: **Start in production mode** (we'll add rules next)
3. Choose location: **us-central** (or closest to you)
4. Click: **Enable**

### Step 3: Deploy Firestore Rules
You need to add security rules to allow data access.

#### Option A: Using Firebase Console (Manual)
1. Go to: **Firestore Database** → **Rules** tab
2. Copy and paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /userProfiles/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false;
    }

    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.authorId) || 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'updatedAt', 'commentsCount'])
      );
      allow delete: if isAuthenticated() && isOwner(resource.data.authorId);
    }

    match /comments/{commentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.authorId) || 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'updatedAt'])
      );
      allow delete: if isAuthenticated() && isOwner(resource.data.authorId);
    }

    match /notifications/{notificationId} {
      allow read, update, delete: if isAuthenticated() && resource.data.toUserId == request.auth.uid;
      allow create: if isAuthenticated();
    }

    match /follows/{followId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == request.resource.data.followerId;
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.followerId;
    }

    match /stories/{storyId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && resource.data.authorId == request.auth.uid;
    }

    match /chats/{chatId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participants;
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participants;
    }

    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && isOwner(resource.data.senderId);
    }
  }
}
```

3. Click: **Publish**

#### Option B: Using Firebase CLI
```bash
# Login to Firebase
firebase login

# Select new project
firebase use studio-2145172646-5b4a0

# Deploy rules
firebase deploy --only firestore:rules
```

### Step 4: Setup Firebase Storage
1. Go to: **Storage** → **Get Started**
2. Select: **Start in production mode**
3. Choose location: Same as Firestore
4. Click: **Done**

#### Add Storage Rules:
1. Go to: **Storage** → **Rules** tab
2. Copy and paste these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() {
      return request.auth != null;
    }

    match /profile_pictures/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    match /post_images/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    match /story_images/{userId}/{filename} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

3. Click: **Publish**

### Step 5: Test the App
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run app
flutter run
```

## Important Notes

### Fresh Start
This is a **brand new Firebase project** with:
- ✅ No existing data
- ✅ No existing users
- ✅ Clean slate
- ✅ No permission issues

### You Need To:
1. **Create new account** - Signup with email/password
2. **Create test data** - Add some posts, profiles, etc.
3. **Test all features** - Make sure everything works

### Migration (If Needed)
If you want to migrate data from old project:
1. Export data from old Firestore
2. Import to new Firestore
3. Or manually recreate test data

## Verification Checklist

After setup, verify:

- [ ] Authentication enabled (Email/Password)
- [ ] Firestore Database created
- [ ] Firestore Rules deployed
- [ ] Firebase Storage enabled
- [ ] Storage Rules deployed
- [ ] App runs without errors
- [ ] Can signup new user
- [ ] Can login
- [ ] Can create posts
- [ ] Can upload images

## Troubleshooting

### If App Doesn't Connect:
```bash
# Rebuild app
flutter clean
flutter pub get
flutter run
```

### If Permission Denied:
- Check Firestore rules are deployed
- Check Storage rules are deployed
- Make sure you're logged in

### If Images Don't Upload:
- Check Storage is enabled
- Check Storage rules are correct
- Check internet connection

## Summary

✅ **Firebase config updated** in `lib/firebase_options.dart`
✅ **New project**: studio-2145172646-5b4a0
✅ **Ready to setup**: Follow steps above
✅ **Fresh start**: No old data or permission issues

---

**Next**: Setup Firebase Console (Authentication, Firestore, Storage)
**Then**: Run app and test!
