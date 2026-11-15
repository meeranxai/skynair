# Fix Firestore Permission Denied Error

## Error
```
Error: [cloud_firestore/permission denied] 
the caller does not have permission to execute the specified operation
```

## Root Cause
Firestore rules are not deployed to Firebase Console. Local `firestore.rules` file is correct, but Firebase Console has old/default rules.

## Solution: Deploy Rules to Firebase

### Method 1: Using Firebase CLI (Recommended)

#### Step 1: Install Firebase CLI (if not installed)
```bash
npm install -g firebase-tools
```

#### Step 2: Login to Firebase
```bash
firebase login
```

#### Step 3: Select Your Project
```bash
firebase use g-network-community
```

#### Step 4: Deploy Rules
```bash
firebase deploy --only firestore:rules
```

Or use the script:
```bash
deploy_firestore_rules.bat
```

### Method 2: Manual Update via Firebase Console

If you don't have Firebase CLI, update rules manually:

#### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/
2. Select project: **g-network-community**
3. Go to: **Firestore Database**
4. Click: **Rules** tab

#### Step 2: Copy Rules from Local File
Open `firestore.rules` file and copy ALL content.

#### Step 3: Paste in Firebase Console
1. Delete all existing rules in Firebase Console
2. Paste the rules from `firestore.rules`
3. Click **Publish**

#### Step 4: Wait for Deployment
- Rules take 1-2 minutes to propagate
- You'll see "Rules published successfully"

## Correct Rules (Copy This)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && request.auth.token.email == "meeran01110rafiq@gmail.com";
    }

    // USER PROFILES
    match /userProfiles/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && (
        isOwner(userId) || 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['followersCount', 'followingCount', 'updatedAt']) ||
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['followersCount', 'updatedAt']) ||
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['followingCount', 'updatedAt']) ||
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['online', 'lastSeen', 'updatedAt']) ||
        isAdmin()
      );
      allow delete: if isAdmin();
    }

    // POSTS
    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.authorId) || 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'updatedAt', 'commentsCount']) ||
        isAdmin()
      );
      allow delete: if isAuthenticated() && (isOwner(resource.data.authorId) || isAdmin());
    }

    // COMMENTS
    match /comments/{commentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.authorId) || 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'updatedAt']) ||
        isAdmin()
      );
      allow delete: if isAuthenticated() && (isOwner(resource.data.authorId) || isAdmin());
    }

    // CHATS
    match /chats/{chatId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participants;
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow delete: if isAdmin();
    }

    // MESSAGES
    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && (isOwner(resource.data.senderId) || isAdmin());
    }

    // NOTIFICATIONS
    match /notifications/{notificationId} {
      allow read, update, delete: if isAuthenticated() && 
        (resource.data.toUserId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated();
    }

    // FOLLOWS
    match /follows/{followId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == request.resource.data.followerId;
      allow delete: if isAuthenticated() && (request.auth.uid == resource.data.followerId || isAdmin());
    }

    // STORIES
    match /stories/{storyId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.authorId == request.auth.uid || isAdmin());
    }
  }
}
```

## Verification

After deploying rules:

### Step 1: Check Rules in Console
1. Go to Firebase Console → Firestore → Rules
2. Verify rules match the above
3. Check "Last published" timestamp

### Step 2: Test App
```bash
flutter run
```

### Step 3: Check Logs
Look for:
- ✅ "User profile found in Firestore"
- ✅ "Posts fetched successfully"
- ❌ No more "permission denied" errors

## Why This Happened?

Firebase Console has **default restrictive rules** that block all access:
```javascript
// Default rules (blocks everything)
match /{document=**} {
  allow read, write: if false;
}
```

Your local `firestore.rules` file has correct rules, but they need to be **deployed** to Firebase Console to take effect.

## Quick Fix Summary

**Option A - Firebase CLI:**
```bash
deploy_firestore_rules.bat
```

**Option B - Manual:**
1. Go to Firebase Console
2. Firestore → Rules
3. Copy rules from `firestore.rules`
4. Paste and Publish

**Option C - Test Mode (Temporary):**
If you just want to test quickly, use test mode rules (NOT for production):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## After Fix

Once rules are deployed:
- ✅ Data will fetch properly
- ✅ Posts will load
- ✅ Profile will show
- ✅ All features will work

---

**Status**: Rules need deployment
**Error**: Permission denied
**Solution**: Deploy firestore.rules to Firebase Console
**Time**: 2-5 minutes to fix
