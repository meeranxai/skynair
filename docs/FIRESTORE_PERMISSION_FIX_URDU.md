# Firestore Permission Error Fix (Roman Urdu)

## Error Kya Hai?
```
Error: [cloud_firestore/permission denied]
```

Yeh error aa raha hai kyunki **Firestore rules Firebase Console mein update nahi hue**.

## Problem Kya Hai?

Aapki local file `firestore.rules` mein sahi rules hain, **LEKIN** Firebase Console pe purane/default rules hain jo sab kuch block kar rahe hain.

## Solution: Rules Deploy Karo

### Tarika 1: Firebase CLI Use Karo (Best)

#### Step 1: Firebase CLI Install Karo (agar nahi hai)
```bash
npm install -g firebase-tools
```

#### Step 2: Login Karo
```bash
firebase login
```

#### Step 3: Project Select Karo
```bash
firebase use g-network-community
```

#### Step 4: Rules Deploy Karo
```bash
firebase deploy --only firestore:rules
```

Ya script run karo:
```bash
deploy_firestore_rules.bat
```

### Tarika 2: Manual Update (Agar CLI Nahi Hai)

Agar Firebase CLI install nahi hai, to manually update karo:

#### Step 1: Firebase Console Kholo
1. Yeh link kholo: https://console.firebase.google.com/
2. Project select karo: **g-network-community**
3. **Firestore Database** pe jao
4. **Rules** tab pe click karo

#### Step 2: Local File Se Rules Copy Karo
1. Apni project mein `firestore.rules` file kholo
2. **Sab kuch** copy karo (Ctrl+A, Ctrl+C)

#### Step 3: Firebase Console Mein Paste Karo
1. Firebase Console mein jo bhi rules hain, **sab delete** karo
2. Apne copy kiye hue rules **paste** karo
3. **Publish** button pe click karo

#### Step 4: Wait Karo
- Rules deploy hone mein 1-2 minute lagte hain
- "Rules published successfully" dikhega

## Sahi Rules (Ye Copy Karo)

Agar manually update kar rahe ho, to ye rules copy karke Firebase Console mein paste karo:

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
    
    function isAdmin() {
      return isAuthenticated() && request.auth.token.email == "meeran01110rafiq@gmail.com";
    }

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

    match /chats/{chatId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participants;
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow delete: if isAdmin();
    }

    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && (isOwner(resource.data.senderId) || isAdmin());
    }

    match /notifications/{notificationId} {
      allow read, update, delete: if isAuthenticated() && 
        (resource.data.toUserId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated();
    }

    match /follows/{followId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == request.resource.data.followerId;
      allow delete: if isAuthenticated() && (request.auth.uid == resource.data.followerId || isAdmin());
    }

    match /stories/{storyId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (resource.data.authorId == request.auth.uid || isAdmin());
    }
  }
}
```

## Verification (Check Karo)

Rules deploy karne ke baad:

### Step 1: Firebase Console Check Karo
1. Firebase Console → Firestore → Rules
2. Dekho ke rules match kar rahe hain
3. "Last published" time check karo

### Step 2: App Test Karo
```bash
flutter run
```

### Step 3: Logs Check Karo
Ye dikhna chahiye:
- ✅ "User profile found in Firestore"
- ✅ "Posts fetched successfully"
- ❌ "permission denied" nahi aana chahiye

## Ye Kyun Hua?

Firebase Console mein **default rules** hote hain jo sab kuch block karte hain:
```javascript
// Default rules (sab block karta hai)
match /{document=**} {
  allow read, write: if false;  // Sab block!
}
```

Aapki local `firestore.rules` file mein sahi rules hain, lekin unko **deploy** karna padta hai Firebase Console pe.

## Quick Fix Summary

**Option A - Firebase CLI (Best):**
```bash
deploy_firestore_rules.bat
```

**Option B - Manual (Agar CLI nahi hai):**
1. Firebase Console kholo
2. Firestore → Rules
3. `firestore.rules` se copy karo
4. Paste karke Publish karo

**Option C - Test Mode (Sirf testing ke liye):**
Agar jaldi test karna hai (production ke liye NAHI):
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

## Fix Ke Baad

Rules deploy hone ke baad:
- ✅ Data fetch hoga
- ✅ Posts load honge
- ✅ Profile dikhega
- ✅ Sab features kaam karenge

## Step-by-Step (Sabse Easy Tarika)

### Agar Firebase CLI Hai:
```bash
# 1. Login karo
firebase login

# 2. Project select karo
firebase use g-network-community

# 3. Rules deploy karo
firebase deploy --only firestore:rules

# 4. App run karo
flutter run
```

### Agar Firebase CLI Nahi Hai:
1. https://console.firebase.google.com/ kholo
2. g-network-community project select karo
3. Firestore → Rules pe jao
4. Upar diye gaye rules copy karo
5. Firebase Console mein paste karo
6. Publish button dabao
7. 2 minute wait karo
8. App run karo: `flutter run`

---

**Status**: Rules deploy karne hain
**Error**: Permission denied
**Solution**: Firestore rules Firebase Console pe deploy karo
**Time**: 2-5 minutes mein fix ho jayega
**Difficulty**: Easy! 🚀
