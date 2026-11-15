# Profile Fix Checklist
## Quick Reference for Debugging Profile Issues

---

## 🔍 Quick Diagnosis

### Is it YOUR profile or ANOTHER USER's profile that has issues?

- ✅ **Own profile works fine** → Issue is with `profileUserId` usage
- ❌ **Both profiles have issues** → Issue is with Firestore rules or indexes
- ⚠️ **Intermittent issues** → Network/timeout problems

---

## ✅ Checklist: Profile Tabs Not Loading

### 1. Verify User ID Usage
```dart
// ❌ WRONG
final posts = ref.watch(userPostsProvider(currentUser.uid));

// ✅ CORRECT
final posts = ref.watch(userPostsProvider(profileUser.uid));
```

**Check these files:**
- [ ] `lib/features/profile/widgets/profile_content_tabs.dart` - Line 317
- [ ] `lib/features/profile/widgets/profile_content_tabs.dart` - Line 56
- [ ] `lib/features/profile/pages/profile_page.dart` - Wherever providers are used

### 2. Verify Timeout Implementation
```dart
// ✅ All streams should have timeout
.timeout(
  const Duration(seconds: 15),
  onTimeout: (sink) {
    dev.log('⚠️ Timeout for user $userId');
    sink.addError('Timeout');
    sink.close();
  },
)
```

**Check these files:**
- [ ] `lib/core/services/firestore_service.dart` - `getUserPostsStream()`
- [ ] `lib/core/services/firestore_service.dart` - `getUserSavedPostsStream()`
- [ ] `lib/core/services/firestore_service.dart` - `getUserArticlesStream()`

### 3. Verify Error Handling
```dart
// ✅ All streams should have error handling
.handleError((e) {
  dev.log('❌ Error: $e');
  return <PostModel>[];  // Fallback
})
```

**Check these files:**
- [ ] `lib/core/services/firestore_service.dart` - All stream methods

### 4. Check Firestore Queries
```dart
// ✅ Correct query format
.where('authorId', isEqualTo: userId)  // Use profileUser.uid
.where('postType', isEqualTo: 'media')
.orderBy('createdAt', descending: true)
```

**Verify in:**
- [ ] `lib/core/services/firestore_service.dart` - `getUserPostsStream()`

### 5. Check Console Logs
```
Look for these messages:
✅ "🎯 UI received X posts for user {userId}"
✅ "🔍 userArticlesProvider: Starting stream for user {userId}"
❌ "⚠️ getUserPostsStream timeout for user {userId}"
❌ "❌ Error in getUserPostsStream: {error}"
```

---

## ✅ Checklist: Follow/Unfollow Not Working

### 1. Verify Follow Service Parameters
```dart
// ✅ CORRECT parameter order
await FollowService.followUser(
  currentUserId,   // Who is following
  targetUserId,    // Who to follow
);
```

**Check these files:**
- [ ] `lib/core/services/follow_service.dart` - `followUser()` method
- [ ] `lib/core/services/follow_service.dart` - `unfollowUser()` method

### 2. Verify Follow Button Implementation
```dart
// ✅ CORRECT: Check if currentUser is following targetUser
final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));

// ✅ CORRECT: Follow action
await ref.read(followProvider.notifier).toggleFollow(
  targetUserId,  // Target user, not current user
  isFollowing: isFollowing,
  isRequested: isRequested,
);
```

**Check these files:**
- [ ] `lib/features/profile/widgets/follow_button.dart` - Line 32
- [ ] `lib/features/profile/widgets/follow_button.dart` - Line 89

### 3. Verify Provider Refresh
```dart
// ✅ MUST invalidate after follow/unfollow
ref.invalidate(isFollowingProvider(targetUserId));
ref.invalidate(isFollowRequestedProvider(targetUserId));
```

**Check these files:**
- [ ] `lib/features/profile/widgets/follow_button.dart` - Lines 95-96

### 4. Verify Follow Document Structure
```
Collection: follows
Document ID: {currentUserId}_{targetUserId}
Fields:
  ✅ followerId: {currentUserId}
  ✅ followingId: {targetUserId}
  ✅ createdAt: timestamp
```

**Check in Firestore Console:**
- [ ] Document ID format is correct
- [ ] Field names match exactly
- [ ] Both user IDs are correct

### 5. Check Console Logs
```
Look for these messages:
✅ "🔄 Starting follow: {currentUserId} -> {targetUserId}"
✅ "✅ User followed successfully: {currentUserId} -> {targetUserId}"
❌ "❌ Error following user: {error}"
❌ "⚠️ Already following"
```

---

## ✅ Checklist: Firestore Rules

### 1. User Profiles
```javascript
match /userProfiles/{userId} {
  allow read: if request.auth != null;  // ✅ All authenticated users can read
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Verify in Firebase Console:**
- [ ] Rules → Firestore Database → Rules
- [ ] Test with "Rules Playground"

### 2. Posts
```javascript
match /posts/{postId} {
  allow read: if request.auth != null;  // ✅ All authenticated users can read
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null 
                        && resource.data.authorId == request.auth.uid;
}
```

**Verify in Firebase Console:**
- [ ] Rules → Firestore Database → Rules
- [ ] Test with "Rules Playground"

### 3. Follows
```javascript
match /follows/{followId} {
  allow read: if request.auth != null;  // ✅ All authenticated users can read
  allow create: if request.auth != null 
                && request.resource.data.followerId == request.auth.uid;
  allow delete: if request.auth != null 
                && resource.data.followerId == request.auth.uid;
}
```

**Verify in Firebase Console:**
- [ ] Rules → Firestore Database → Rules
- [ ] Test with "Rules Playground"

---

## ✅ Checklist: Firestore Indexes

### 1. Posts Collection
```
Collection: posts
Fields indexed:
  ✅ authorId (Ascending) + createdAt (Descending)
  ✅ authorId (Ascending) + postType (Ascending) + createdAt (Descending)
  ✅ saves (Array) + createdAt (Descending)
```

**Verify in Firebase Console:**
- [ ] Firestore Database → Indexes
- [ ] Check for "Collection: posts"
- [ ] Verify all required indexes exist

### 2. Check for Missing Indexes
```
Look for error messages like:
❌ "The query requires an index"
❌ "FAILED_PRECONDITION: The query requires an index"
```

**If missing:**
- [ ] Click the link in the error message
- [ ] Or manually create in Firebase Console → Indexes

---

## ✅ Checklist: Network & Performance

### 1. Timeout Settings
```dart
// ✅ Recommended timeouts
Follow/Privacy Checks: 10 seconds
Blocking Streams: 12 seconds
Profile/Posts Streams: 15 seconds
```

**Verify in:**
- [ ] `lib/core/services/follow_service.dart`
- [ ] `lib/core/services/blocking_service.dart`
- [ ] `lib/core/services/firestore_service.dart`

### 2. Loading States
```dart
// ✅ Should show loading for max timeout duration
userPostsAsync.when(
  data: (posts) => /* Show posts */,
  loading: () => /* Show loading (max 15s) */,
  error: (error, stack) => /* Show error with retry */,
)
```

**Verify in:**
- [ ] `lib/features/profile/widgets/profile_content_tabs.dart`

---

## 🧪 Testing Checklist

### Test Scenario 1: View Other User's Profile
- [ ] Login as User A
- [ ] Navigate to User B's profile
- [ ] Posts tab shows User B's posts (not User A's)
- [ ] Media tab shows User B's media (not User A's)
- [ ] Tagged tab shows appropriate message
- [ ] Loading completes within 15 seconds
- [ ] No infinite loading spinners

### Test Scenario 2: Follow Other User
- [ ] Login as User A
- [ ] Navigate to User B's profile
- [ ] Click "Follow" button
- [ ] Button changes to "Unfollow" immediately
- [ ] User B's follower count increases
- [ ] User A's following count increases
- [ ] Refresh page - still shows "Unfollow"

### Test Scenario 3: Unfollow Other User
- [ ] Login as User A (already following User B)
- [ ] Navigate to User B's profile
- [ ] Click "Unfollow" button
- [ ] Button changes to "Follow" immediately
- [ ] User B's follower count decreases
- [ ] User A's following count decreases
- [ ] Refresh page - still shows "Follow"

### Test Scenario 4: Slow Network
- [ ] Enable network throttling (slow 3G)
- [ ] Navigate to other user's profile
- [ ] Loading state shows
- [ ] After 15 seconds, timeout message appears
- [ ] "Try Again" button works
- [ ] No app crash or freeze

### Test Scenario 5: Private Account
- [ ] Login as User A
- [ ] Navigate to User B's profile (private)
- [ ] Click "Follow" button
- [ ] Button changes to "Requested"
- [ ] Follow request created (not follow relationship)
- [ ] Counts don't change until accepted

---

## 🐛 Common Mistakes

### Mistake #1: Using Current User ID Everywhere
```dart
// ❌ WRONG - Shows YOUR posts on everyone's profile
final posts = ref.watch(userPostsProvider(currentUser.uid));

// ✅ CORRECT - Shows PROFILE USER's posts
final posts = ref.watch(userPostsProvider(profileUser.uid));
```

### Mistake #2: Not Refreshing Providers
```dart
// ❌ WRONG - UI doesn't update
await FollowService.followUser(currentUserId, targetUserId);

// ✅ CORRECT - UI updates immediately
await FollowService.followUser(currentUserId, targetUserId);
ref.invalidate(isFollowingProvider(targetUserId));
```

### Mistake #3: Wrong Follow Document ID
```dart
// ❌ WRONG - Reversed IDs
doc('${targetUserId}_${currentUserId}')

// ✅ CORRECT - Follower first, then following
doc('${currentUserId}_${targetUserId}')
```

### Mistake #4: No Timeout on Queries
```dart
// ❌ WRONG - Can hang forever
.snapshots()
.map((snapshot) => /* ... */)

// ✅ CORRECT - Times out after 15s
.snapshots()
.timeout(const Duration(seconds: 15), onTimeout: /* ... */)
.map((snapshot) => /* ... */)
```

### Mistake #5: No Error Handling
```dart
// ❌ WRONG - Silent failures
.snapshots()
.map((snapshot) => /* ... */)

// ✅ CORRECT - Shows error to user
.snapshots()
.timeout(/* ... */)
.map((snapshot) => /* ... */)
.handleError((e) => /* fallback */)
```

---

## 📊 Quick Reference Table

| Component | Correct User ID | Example |
|-----------|----------------|---------|
| **Posts Tab** | Profile User | `userPostsProvider(profileUser.uid)` |
| **Saved Tab** | Profile User | `userSavedPostsProvider(profileUser.uid)` |
| **Follow Check** | Target User | `isFollowingProvider(targetUser.uid)` |
| **Follow Action** | Both | `followUser(currentUser.uid, targetUser.uid)` |
| **Profile Header** | Profile User | `userProfileByIdProvider(profileUser.uid)` |

---

## 🔧 Debug Commands

### View Firestore Data
```bash
# Check if follow relationship exists
# In Firestore Console, navigate to:
follows/{currentUserId}_{targetUserId}
```

### Check Logs
```bash
# Run app with verbose logging
flutter run --verbose

# Look for these patterns:
# ✅ Success: "✅ User followed successfully"
# ❌ Error: "❌ Error following user"
# ⚠️ Warning: "⚠️ isFollowing timeout"
```

### Test Firestore Rules
```bash
# In Firebase Console:
# 1. Go to Firestore Database → Rules
# 2. Click "Rules Playground"
# 3. Test read/write operations
```

---

## 📞 When to Ask for Help

If you've checked all the above and still have issues:

1. **Provide these details:**
   - [ ] Which user ID is being used (current or profile)?
   - [ ] Console logs showing the error
   - [ ] Firestore rules screenshot
   - [ ] Network tab showing failed requests

2. **Include this information:**
   - [ ] Does it work for your own profile?
   - [ ] Does it work for some users but not others?
   - [ ] What's the exact error message?
   - [ ] When did it start happening?

---

**Last Updated:** 2026-01-20  
**Version:** 1.0  
**Status:** Active ✅
