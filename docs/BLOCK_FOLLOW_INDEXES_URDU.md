# Block/Unblock aur Follow Request Indexes - Urdu Guide

## Kya Indexes Chahiye?

### 1. Block List Indexes
```
Collection: blockList
Fields:
  - blockerId (ASCENDING) + blockedAt (DESCENDING)
  - blockedId (ASCENDING) + blockedAt (DESCENDING)
```

**Kyun Chahiye:**
- Jab kisi ne kitne log block kiye hain (blockerId se query)
- Jab kisi ko kitne logon ne block kiya hai (blockedId se query)
- Time ke sath sorted results

### 2. Follow Request Indexes
```
Collection: followRequests
Fields:
  - toUserId (ASCENDING) + status (ASCENDING) + createdAt (DESCENDING)
  - fromUserId (ASCENDING) + status (ASCENDING) + createdAt (DESCENDING)
```

**Kyun Chahiye:**
- Pending requests dekhne ke liye (toUserId + status='pending')
- Sent requests dekhne ke liye (fromUserId + status='pending')
- Time ke sath sorted results

## Deploy Kaise Karein

### Method 1: Batch Script (Recommended)
```bash
deploy_block_follow_indexes.bat
```

### Method 2: Manual Firebase CLI
```bash
firebase deploy --only firestore:indexes
```

### Method 3: Firebase Console (Manual)
1. Firebase Console kholen: https://console.firebase.google.com
2. Firestore Database > Indexes
3. Composite tab mein jaayen
4. Manually add karein:

**Block List Index 1:**
- Collection: `blockList`
- Field 1: `blockerId` (Ascending)
- Field 2: `blockedAt` (Descending)

**Block List Index 2:**
- Collection: `blockList`
- Field 1: `blockedId` (Ascending)
- Field 2: `blockedAt` (Descending)

**Follow Request Index 1:**
- Collection: `followRequests`
- Field 1: `toUserId` (Ascending)
- Field 2: `status` (Ascending)
- Field 3: `createdAt` (Descending)

**Follow Request Index 2:**
- Collection: `followRequests`
- Field 1: `fromUserId` (Ascending)
- Field 2: `status` (Ascending)
- Field 3: `createdAt` (Descending)

## Verification

### Check Index Status
```bash
firebase firestore:indexes
```

### Test Queries

**Block List Query:**
```dart
// Blocked users by me
await FirebaseFirestore.instance
  .collection('blockList')
  .where('blockerId', isEqualTo: currentUserId)
  .orderBy('blockedAt', descending: true)
  .get();

// Users who blocked me
await FirebaseFirestore.instance
  .collection('blockList')
  .where('blockedId', isEqualTo: currentUserId)
  .orderBy('blockedAt', descending: true)
  .get();
```

**Follow Request Query:**
```dart
// Pending requests received
await FirebaseFirestore.instance
  .collection('followRequests')
  .where('toUserId', isEqualTo: currentUserId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .get();

// Pending requests sent
await FirebaseFirestore.instance
  .collection('followRequests')
  .where('fromUserId', isEqualTo: currentUserId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .get();
```

## Index Build Time

- **Small Database (<1000 docs):** 2-5 minutes
- **Medium Database (1000-10000 docs):** 10-30 minutes
- **Large Database (>10000 docs):** 30+ minutes

## Troubleshooting

### Error: "The query requires an index"
**Solution:** Index abhi build ho raha hai, wait karein ya console mein check karein

### Error: "Index already exists"
**Solution:** Koi problem nahi, index pehle se hai

### Error: "Permission denied"
**Solution:** Firebase login check karein:
```bash
firebase login
```

## Quick Reference

| Feature | Collection | Index Fields |
|---------|-----------|--------------|
| Block List (by blocker) | blockList | blockerId + blockedAt |
| Block List (by blocked) | blockList | blockedId + blockedAt |
| Follow Requests (received) | followRequests | toUserId + status + createdAt |
| Follow Requests (sent) | followRequests | fromUserId + status + createdAt |

## Status Check

✅ Indexes added to `firestore.indexes.json`
⏳ Deploy pending: Run `deploy_block_follow_indexes.bat`
🔍 Verify in Firebase Console after deployment

---

**Note:** Indexes deploy hone ke baad app restart karein for best results.
