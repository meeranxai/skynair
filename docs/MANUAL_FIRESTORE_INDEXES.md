# Manual Firestore Indexes - Step by Step

## Missing Indexes (7 Total)

Ye indexes aapko Firebase Console mein manually create karne hain.

---

## Index 1: Notifications - Unread Filter

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields:**
1. Field: `toUserId`  
   Order: Ascending

2. Field: `isRead`  
   Order: Ascending

**Purpose:** Unread notifications filter karne ke liye

---

## Index 2: Notifications - Type Filter (3 fields)

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields:**
1. Field: `type`  
   Order: Ascending

2. Field: `fromUserId`  
   Order: Ascending

3. Field: `toUserId`  
   Order: Ascending

**Purpose:** Notification type ke mutabiq filter karne ke liye

---

## Index 3: Notifications - Type Filter with Post (4 fields)

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields:**
1. Field: `type`  
   Order: Ascending

2. Field: `fromUserId`  
   Order: Ascending

3. Field: `toUserId`  
   Order: Ascending

4. Field: `postId`  
   Order: Ascending

**Purpose:** Specific post ki notifications filter karne ke liye

---

## Index 4: Comments - Parent Comment (Replies)

**Collection ID:** `comments`  
**Query Scope:** Collection

**Fields:**
1. Field: `parentCommentId`  
   Order: Ascending

2. Field: `createdAt`  
   Order: Ascending

**Purpose:** Comment replies (nested comments) ke liye

---

## Index 5: Comments - User History

**Collection ID:** `comments`  
**Query Scope:** Collection

**Fields:**
1. Field: `authorId`  
   Order: Ascending

2. Field: `createdAt`  
   Order: Descending

**Purpose:** User ki comment history dekhne ke liye

---

## Index 6: Stories - Highlights

**Collection ID:** `stories`  
**Query Scope:** Collection

**Fields:**
1. Field: `userId`  
   Order: Ascending

2. Field: `isHighlight`  
   Order: Ascending

3. Field: `createdAt`  
   Order: Descending

**Purpose:** Story highlights feature ke liye

---

## Index 7: Stories - Expiry Cleanup

**Collection ID:** `stories`  
**Query Scope:** Collection

**Fields:**
1. Field: `expiresAt`  
   Order: Ascending

2. Field: `createdAt`  
   Order: Descending

**Purpose:** Expired stories cleanup ke liye

---

## How to Create (Firebase Console)

### Step-by-Step:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Indexes**
   - Click "Firestore Database" (left sidebar)
   - Click "Indexes" tab (top)

3. **Create Composite Index**
   - Click "Create Index" button
   - Fill in the details for each index above

4. **For Each Index:**
   - Enter Collection ID
   - Select Query Scope: "Collection"
   - Add fields one by one:
     - Click "Add field"
     - Select field name
     - Select order (Ascending/Descending)
   - Click "Create"

5. **Wait for Build**
   - Each index takes 5-10 minutes to build
   - Status will show "Building" → "Enabled"

---

## Quick Copy-Paste Format

### Index 1
```
Collection: notifications
Fields: toUserId (Ascending), isRead (Ascending)
```

### Index 2
```
Collection: notifications
Fields: type (Ascending), fromUserId (Ascending), toUserId (Ascending)
```

### Index 3
```
Collection: notifications
Fields: type (Ascending), fromUserId (Ascending), toUserId (Ascending), postId (Ascending)
```

### Index 4
```
Collection: comments
Fields: parentCommentId (Ascending), createdAt (Ascending)
```

### Index 5
```
Collection: comments
Fields: authorId (Ascending), createdAt (Descending)
```

### Index 6
```
Collection: stories
Fields: userId (Ascending), isHighlight (Ascending), createdAt (Descending)
```

### Index 7
```
Collection: stories
Fields: expiresAt (Ascending), createdAt (Descending)
```

---

## Priority Order

### High Priority (Create First):
1. ✅ Index 1 - Notifications unread filter
2. ✅ Index 4 - Comment replies

### Medium Priority:
3. ✅ Index 2 - Notification type filter
4. ✅ Index 6 - Story highlights

### Low Priority (Optional):
5. ⚠️ Index 3 - Notification with post
6. ⚠️ Index 5 - User comment history
7. ⚠️ Index 7 - Story expiry cleanup

---

## Verification

After creating each index:

1. Check status in Firebase Console
2. Wait for "Enabled" status
3. Test the feature in your app

---

## Alternative: Auto Deploy

Instead of manual creation, you can deploy all at once:

```bash
firebase deploy --only firestore:indexes
```

This will automatically create all 7 indexes from your `firestore.indexes.json` file.

---

## Summary

**Total Indexes to Create:** 7  
**Estimated Time:** 5-10 minutes per index  
**Total Time:** ~1 hour (if creating manually)

**Recommendation:** Use `firebase deploy --only firestore:indexes` for faster deployment! 🚀
