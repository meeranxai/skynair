# Firebase Domains & Indexing Setup Guide

## Part 1: Authorized Domains (Authentication)

### What Are Authorized Domains?
Domains that are allowed to use Firebase Authentication. Required for web apps, NOT for mobile apps.

### For Mobile App (Your Current Setup) - NO DOMAINS NEEDED ❌

**You're building a mobile app (APK), so you DON'T need to add any domains!**

Mobile apps use:
- Package name: `com.example.socialMediaApp`
- SHA-1 fingerprint (for Google Sign-In)
- NOT domains

### For Web App (If Deploying) - ADD DOMAINS ✅

If you deploy web version to Railway/Vercel/Netlify, add these domains:

#### Go to Firebase Console:
1. **Authentication** → **Settings** → **Authorized domains**
2. Click **Add domain**
3. Add these domains:

**Default domains (already added):**
- `localhost` ✅ (for local testing)
- `studio-2145172646-5b4a0.firebaseapp.com` ✅ (Firebase hosting)

**Add if deploying to Railway:**
- `your-app-name.railway.app`
- Example: `g-network.railway.app`

**Add if using custom domain:**
- `yourdomain.com`
- `www.yourdomain.com`

#### Example Domains to Add:
```
localhost
studio-2145172646-5b4a0.firebaseapp.com
g-network.railway.app
gnetwork.com
www.gnetwork.com
```

---

## Part 2: Firestore Indexes

### What Are Firestore Indexes?
Indexes make complex queries faster. Required for queries with multiple filters or sorting.

### Your App Already Has Indexes! ✅

File: `firestore.indexes.json` contains all required indexes for:
- Posts (by author, date, saves)
- Comments (by post, parent, author)
- Notifications (by user, type, read status)
- Stories (by user, expiry, highlights)
- Chats (by participants, date)

### How to Deploy Indexes to Firebase

#### Option 1: Firebase Console (Manual)

1. **Go to**: Firebase Console → Firestore Database → **Indexes** tab
2. **Click**: **Add Index** (for each index below)

**Required Indexes:**

**1. Posts by Author and Date:**
- Collection: `posts`
- Fields:
  - `authorId` (Ascending)
  - `createdAt` (Descending)

**2. Saved Posts:**
- Collection: `posts`
- Fields:
  - `saves` (Array-contains)
  - `createdAt` (Descending)

**3. Comments by Post:**
- Collection: `comments`
- Fields:
  - `postId` (Ascending)
  - `createdAt` (Ascending)

**4. Notifications by User:**
- Collection: `notifications`
- Fields:
  - `toUserId` (Ascending)
  - `createdAt` (Descending)

**5. Stories by User:**
- Collection: `stories`
- Fields:
  - `userId` (Ascending)
  - `expiresAt` (Ascending)
  - `createdAt` (Descending)

**6. Chats by Participants:**
- Collection: `chats`
- Fields:
  - `participants` (Array-contains)
  - `updatedAt` (Descending)

#### Option 2: Firebase CLI (Automatic - Recommended)

```bash
# Login to Firebase
firebase login

# Select new project
firebase use studio-2145172646-5b4a0

# Deploy indexes
firebase deploy --only firestore:indexes
```

Or use the batch script:

```bash
deploy_indexes.bat
```

### When Do You Need Indexes?

**Automatic (Single-field):**
- Simple queries work automatically
- Example: Get all posts, Get user by ID

**Manual (Composite):**
- Multiple filters or sorting
- Example: Get posts by author sorted by date
- Example: Get unread notifications for user

**Your app needs composite indexes** because it uses:
- Posts filtered by author + sorted by date
- Notifications filtered by user + sorted by date
- Comments filtered by post + sorted by date
- Stories filtered by user + expiry check

### How to Know If Index Is Missing?

**In App:**
- Query fails with error: "The query requires an index"
- Error message includes a link to create the index

**In Firebase Console:**
- Go to: Firestore Database → Indexes
- Check status: Building, Enabled, Error

### Index Status:

- **Building**: Index is being created (can take minutes)
- **Enabled**: Index is ready to use ✅
- **Error**: Index creation failed ❌

---

## Quick Setup Checklist

### For Mobile App (Your Current Setup):

**Domains:**
- [ ] ❌ NOT needed for mobile app
- [ ] ✅ Skip this step

**Indexes:**
- [ ] Deploy Firestore indexes using Firebase CLI
- [ ] Or manually create in Firebase Console
- [ ] Wait for indexes to build (5-10 minutes)
- [ ] Test app queries

### For Web App (If Deploying):

**Domains:**
- [ ] Add `localhost` (already added)
- [ ] Add Firebase hosting domain (already added)
- [ ] Add Railway domain: `your-app.railway.app`
- [ ] Add custom domain (if you have one)

**Indexes:**
- [ ] Same as mobile app (see above)

---

## Deployment Scripts

I've created these scripts for you:

### Deploy Indexes:
```bash
deploy_indexes.bat
```

### Deploy All (Rules + Indexes):
```bash
firebase deploy --only firestore
```

---

## Summary

### Domains (Authentication):
- **Mobile App**: NOT needed ❌
- **Web App**: Add Railway/custom domains ✅

### Indexes (Firestore):
- **Required for both mobile and web** ✅
- **Already defined** in `firestore.indexes.json` ✅
- **Need to deploy** to Firebase Console ✅

### What You Need To Do Now:

1. **Skip domains** (mobile app doesn't need them)
2. **Deploy Firestore indexes**:
   ```bash
   firebase login
   firebase use studio-2145172646-5b4a0
   firebase deploy --only firestore:indexes
   ```
3. **Wait 5-10 minutes** for indexes to build
4. **Test app** - queries should work without errors

---

**Tumhare mobile app ke liye domains ki zaroorat nahi hai. Sirf Firestore indexes deploy karne hain Firebase Console mein. Yeh queries ko fast banate hain!** 🚀
