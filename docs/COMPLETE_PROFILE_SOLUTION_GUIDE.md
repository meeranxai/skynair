# Complete Profile Solution Guide
## Fixing Profile Tabs & Follow/Unfollow for Other Users

---

## 📋 Table of Contents
1. [Problem Overview](#problem-overview)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Solution Architecture](#solution-architecture)
4. [Implementation Details](#implementation-details)
5. [Testing Guide](#testing-guide)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Problem Overview

### Issue 1: Profile Tabs Not Loading for Other Users
**Symptoms:**
- Posts, Media, and Tagged tabs show infinite loading spinner
- Data exists in Firestore but doesn't display
- Own profile loads fine, but other users' profiles get stuck

**Root Causes:**
1. **Incorrect User ID in Queries** - Using `currentUserId` instead of `profileUserId`
2. **Missing Timeouts** - Firestore queries hang indefinitely
3. **No Error Handling** - Silent failures prevent debugging
4. **Stream Not Updating** - UI doesn't reflect data changes

### Issue 2: Follow/Unfollow Button Not Working
**Symptoms:**
- Button doesn't respond to clicks
- Follow status doesn't update after action
- Works on own profile but not on other users

**Root Causes:**
1. **Wrong User ID in Follow Logic** - Following yourself instead of target user
2. **Provider Not Refreshing** - UI doesn't update after follow/unfollow
3. **Missing Error Feedback** - No indication when operation fails
4. **State Management Issues** - Follow status not syncing with Firestore

---

## 🔍 Root Cause Analysis

### Why It Works for Own Profile but Not Others

#### Own Profile Flow:
```dart
// Simple, single query
final userProfileAsync = ref.watch(userProfileByIdProvider(currentUserId));
// ✅ Just loads profile data
```

#### Other User's Profile Flow:
```dart
// Multiple nested queries that can fail:
1. isBlockedByMeAsync     // ❌ Can timeout
2. isBlockedByThemAsync   // ❌ Can timeout  
3. isFollowingAsync       // ❌ Can timeout
4. userPostsProvider      // ❌ Can timeout
5. userSavedPostsProvider // ❌ Can timeout

// If ANY of these hang, entire profile gets stuck!
```

### The Critical Difference

**Your Profile:**
- Uses `currentUserId` from auth state
- Minimal queries needed
- Direct data access

**Other User's Profile:**
- Uses `profileUserId` from navigation params
- Multiple relationship checks (following, blocking, etc.)
- Each check is a potential failure point

---

## 🏗️ Solution Architecture

### 1. Correct User ID Usage Pattern

```dart
// ❌ WRONG - This fetches YOUR data, not the profile user's data
final userPostsAsync = ref.watch(userPostsProvider(currentUserId));

// ✅ CORRECT - This fetches the PROFILE USER's data
final userPostsAsync = ref.watch(userPostsProvider(profileUserId));
```

### 2. Provider Structure

```dart
// Profile Tabs should ALWAYS use the profileUserId
class ProfileContentTabs extends ConsumerWidget {
  final UserModel user;  // This is the PROFILE USER, not current user
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Use user.uid (profile user's ID)
    final postsAsync = ref.watch(userPostsProvider(user.uid));
    final savedAsync = ref.watch(userSavedPostsProvider(user.uid));
    
    // NOT currentUser.uid!
  }
}
```

### 3. Follow Button Logic

```dart
// Follow button needs BOTH IDs
class FollowButton extends ConsumerWidget {
  final String targetUserId;  // The user to follow
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).user?.uid;
    
    // ✅ CORRECT: Check if currentUser is following targetUser
    final isFollowingAsync = ref.watch(
      isFollowingProvider(targetUserId)  // Checks currentUser -> targetUser
    );
    
    onPressed: () {
      // ✅ CORRECT: Follow the target user
      await FollowService.followUser(
        currentUserId,   // Who is following
        targetUserId,    // Who to follow
      );
    }
  }
}
```

---

## 💻 Implementation Details

### Fix 1: Profile Tabs Data Loading

#### File: `lib/features/profile/widgets/profile_content_tabs.dart`

**Current Implementation (Already Fixed in Your Code):**
```dart
class ProfileContentTabs extends ConsumerWidget {
  final UserModel user;  // ✅ Profile user
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      children: [
        // Posts Tab - ✅ Uses user.uid (profile user)
        _PostsTabWithTimeout(user: user, isOwnProfile: isOwnProfile),
        
        // Media Tab - ✅ Uses user.uid (profile user)
        _PostsTabWithTimeout(user: user, isOwnProfile: isOwnProfile),
        
        // Saved/Tagged Tab
        isOwnProfile
          ? _buildSavedTab(theme, ref, context)  // ✅ Own saved posts
          : _buildTaggedTab(theme),              // ✅ Tagged posts
      ],
    );
  }
  
  Widget _buildSavedTab(ThemeData theme, WidgetRef ref, BuildContext context) {
    // ✅ CORRECT: Uses user.uid (profile user's saved posts)
    final savedPostsAsync = ref.watch(userSavedPostsProvider(user.uid));
    // ...
  }
}
```

**Posts Tab Implementation:**
```dart
class _PostsTabWithTimeoutState extends ConsumerState<_PostsTabWithTimeout> {
  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: Uses widget.user.uid (profile user)
    final userPostsAsync = ref.watch(userPostsProvider(widget.user.uid));
    
    return userPostsAsync.when(
      data: (posts) {
        // Filter posts based on ownership
        final visiblePosts = posts.where((p) {
          final isMedia = p.postType == 'media';
          final isVisible = widget.isOwnProfile || p.isDraft != true;
          return isMedia && isVisible;
        }).toList();
        
        // Display posts...
      },
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, error.toString()),
    );
  }
}
```

### Fix 2: Firestore Service with Timeouts

#### File: `lib/core/services/firestore_service.dart`

**User Posts Stream (Already Implemented):**
```dart
static Stream<List<PostModel>> getUserPostsStream(String userId) {
  return _firestore
      .collection(FirebaseConfig.posts)
      .where('authorId', isEqualTo: userId)  // ✅ Filters by profile user
      .where('postType', isEqualTo: 'media')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .timeout(
        const Duration(seconds: 15),  // ✅ 15 second timeout
        onTimeout: (sink) {
          dev.log('⚠️ getUserPostsStream timeout for user $userId');
          sink.addError('Timeout loading posts');
          sink.close();
        },
      )
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
      })
      .handleError((e) {
        dev.log('❌ Error in getUserPostsStream: $e');
        return <PostModel>[];
      });
}
```

**Saved Posts Stream (Already Implemented):**
```dart
static Stream<List<PostModel>> getUserSavedPostsStream(String userId) {
  return _firestore
      .collection(FirebaseConfig.posts)
      .where('saves', arrayContains: userId)  // ✅ Posts saved by user
      .orderBy('createdAt', descending: true)
      .snapshots()
      .timeout(
        const Duration(seconds: 15),
        onTimeout: (sink) {
          dev.log('⚠️ getUserSavedPostsStream timeout for user $userId');
          sink.addError('Timeout loading saved posts');
          sink.close();
        },
      )
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
      })
      .handleError((e) {
        // Fallback without orderBy if index missing
        return _firestore
            .collection(FirebaseConfig.posts)
            .where('saves', arrayContains: userId)
            .snapshots()
            .timeout(const Duration(seconds: 15))
            .map((snapshot) {
              final posts = snapshot.docs
                  .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
                  .toList();
              posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return posts;
            });
      });
}
```

### Fix 3: Follow Service with Proper User IDs

#### File: `lib/core/services/follow_service.dart`

**Follow User (Already Implemented):**
```dart
static Future<void> followUser(String followerId, String followingId) async {
  // ✅ Validation: Can't follow yourself
  if (followerId == followingId) {
    throw 'Cannot follow yourself';
  }

  log('🔄 Starting follow: $followerId -> $followingId');

  try {
    await _firestore.runTransaction((transaction) async {
      // Create follow relationship document
      final followRef = _firestore
          .collection(FirebaseConfig.follows)
          .doc('${followerId}_$followingId');  // ✅ Correct ID format

      // Check if already following
      final followDoc = await transaction.get(followRef);
      if (followDoc.exists) {
        log('⚠️ Already following');
        return;
      }

      // Create follow relationship
      transaction.set(followRef, {
        'followerId': followerId,      // ✅ Current user
        'followingId': followingId,    // ✅ Target user
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update follower's following count
      final followerRef = _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(followerId);  // ✅ Current user's profile
      
      transaction.set(
        followerRef,
        {
          'followingCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Update following user's followers count
      final followingRef = _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(followingId);  // ✅ Target user's profile
      
      transaction.set(
        followingRef,
        {
          'followersCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    log('✅ User followed successfully: $followerId -> $followingId');
  } catch (e) {
    log('❌ Error following user: $e');
    rethrow;
  }
}
```

**Unfollow User (Already Implemented):**
```dart
static Future<void> unfollowUser(String followerId, String followingId) async {
  try {
    await _firestore.runTransaction((transaction) async {
      final followRef = _firestore
          .collection(FirebaseConfig.follows)
          .doc('${followerId}_$followingId');  // ✅ Correct ID format

      final followDoc = await transaction.get(followRef);
      if (!followDoc.exists) {
        log('⚠️ Follow relationship already removed');
        return;
      }

      // Delete the relationship
      transaction.delete(followRef);

      // Safe decrement for follower
      final followerDoc = await transaction.get(
        _firestore.collection(FirebaseConfig.userProfiles).doc(followerId)
      );
      if (followerDoc.exists) {
        final currentFollowing = (followerDoc.data()?['followingCount'] as int?) ?? 0;
        if (currentFollowing > 0) {
          transaction.update(
            _firestore.collection(FirebaseConfig.userProfiles).doc(followerId),
            {
              'followingCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      // Safe decrement for following user
      final followingDoc = await transaction.get(
        _firestore.collection(FirebaseConfig.userProfiles).doc(followingId)
      );
      if (followingDoc.exists) {
        final currentFollowers = (followingDoc.data()?['followersCount'] as int?) ?? 0;
        if (currentFollowers > 0) {
          transaction.update(
            _firestore.collection(FirebaseConfig.userProfiles).doc(followingId),
            {
              'followersCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
    });

    log('✅ User unfollowed successfully: $followerId -> $followingId');
  } catch (e) {
    log('❌ Error unfollowing user: $e');
    rethrow;
  }
}
```

**Check Follow Status (Already Implemented):**
```dart
static Future<bool> isFollowing(String followerId, String followingId) async {
  try {
    final doc = await _firestore
        .collection(FirebaseConfig.follows)
        .doc('${followerId}_$followingId')  // ✅ Correct ID format
        .get()
        .timeout(
          const Duration(seconds: 10),  // ✅ 10 second timeout
          onTimeout: () {
            log('⚠️ isFollowing timeout for $followerId -> $followingId');
            throw TimeoutException('Follow status check timed out');
          },
        );

    return doc.exists;
  } catch (e) {
    log('❌ Error checking follow status: $e');
    return false; // ✅ Safe default: assume not following
  }
}
```

### Fix 4: Follow Button with Provider Refresh

#### File: `lib/features/profile/widgets/follow_button.dart`

**Current Implementation (Already Fixed):**
```dart
class FollowButton extends ConsumerWidget {
  final String targetUserId;  // ✅ Target user to follow
  final String? targetUsername;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.uid;

    // Don't show for own profile or when not logged in
    if (currentUserId == null || currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }

    // ✅ Check if current user is following target user
    final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));
    final isRequestedAsync = ref.watch(isFollowRequestedProvider(targetUserId));
    
    return isFollowingAsync.when(
      data: (isFollowing) => isRequestedAsync.when(
        data: (isRequested) => _buildFollowButton(
          context,
          ref,
          theme,
          isFollowing,
          isRequested,
          followState.isLoading,
          currentUserId,
        ),
        loading: () => _buildLoadingButton(theme),
        error: (error, stack) => _buildErrorButton(theme),
      ),
      loading: () => _buildLoadingButton(theme),
      error: (error, stack) => _buildErrorButton(theme),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isFollowing,
    bool isRequested,
    bool isLoading,
    String currentUserId,
  ) {
    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              // ✅ Toggle follow with correct user IDs
              await ref.read(followProvider.notifier).toggleFollow(
                    targetUserId,      // ✅ Target user
                    isFollowing: isFollowing,
                    isRequested: isRequested,
                  );
              
              // ✅ Refresh providers to update UI
              ref.invalidate(isFollowingProvider(targetUserId));
              ref.invalidate(isFollowRequestedProvider(targetUserId));
            },
      child: Text(isFollowing ? 'Unfollow' : 'Follow'),
    );
  }
}
```

### Fix 5: Follow Provider Implementation

#### File: `lib/core/providers/follow_provider.dart`

**Provider Setup:**
```dart
// Check if current user is following target user
final isFollowingProvider = FutureProvider.family<bool, String>((ref, targetUserId) async {
  final currentUserId = ref.watch(authProvider).user?.uid;
  if (currentUserId == null || currentUserId == targetUserId) {
    return false;
  }
  
  // ✅ Check if currentUser is following targetUser
  return await FollowService.isFollowing(currentUserId, targetUserId);
});

// Check if current user has requested to follow target user
final isFollowRequestedProvider = FutureProvider.family<bool, String>((ref, targetUserId) async {
  final currentUserId = ref.watch(authProvider).user?.uid;
  if (currentUserId == null || currentUserId == targetUserId) {
    return false;
  }
  
  // ✅ Check if currentUser has requested to follow targetUser
  return await FollowService.isFollowRequested(currentUserId, targetUserId);
});

// Follow state notifier
class FollowNotifier extends StateNotifier<FollowState> {
  final Ref ref;
  
  FollowNotifier(this.ref) : super(FollowState());

  Future<void> toggleFollow(
    String targetUserId, {
    required bool isFollowing,
    required bool isRequested,
  }) async {
    final currentUserId = ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      if (isFollowing) {
        // ✅ Unfollow: currentUser unfollows targetUser
        await FollowService.unfollowUser(currentUserId, targetUserId);
      } else if (isRequested) {
        // ✅ Cancel request: currentUser cancels request to targetUser
        await FollowService.cancelFollowRequest(currentUserId, targetUserId);
      } else {
        // Check if target user is private
        final isPrivate = await FollowService.isUserPrivate(targetUserId);
        
        if (isPrivate) {
          // ✅ Send follow request: currentUser requests to follow targetUser
          await FollowService.sendFollowRequest(currentUserId, targetUserId);
        } else {
          // ✅ Follow directly: currentUser follows targetUser
          await FollowService.followUser(currentUserId, targetUserId);
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
```

---

## 🧪 Testing Guide

### Test Case 1: View Other User's Profile
```
1. Login as User A
2. Navigate to User B's profile
3. Verify:
   ✅ Posts tab loads User B's posts (not User A's)
   ✅ Media tab loads User B's media (not User A's)
   ✅ Tagged tab shows "No tagged posts" message
   ✅ Loading completes within 15 seconds
   ✅ No infinite loading spinners
```

### Test Case 2: Follow Other User
```
1. Login as User A
2. Navigate to User B's profile
3. Click "Follow" button
4. Verify:
   ✅ Button changes to "Unfollow"
   ✅ User B's follower count increases by 1
   ✅ User A's following count increases by 1
   ✅ Follow relationship created in Firestore
```

### Test Case 3: Unfollow Other User
```
1. Login as User A (already following User B)
2. Navigate to User B's profile
3. Click "Unfollow" button
4. Verify:
   ✅ Button changes to "Follow"
   ✅ User B's follower count decreases by 1
   ✅ User A's following count decreases by 1
   ✅ Follow relationship deleted from Firestore
```

### Test Case 4: Private Account Follow Request
```
1. Login as User A
2. Navigate to User B's profile (private account)
3. Click "Follow" button
4. Verify:
   ✅ Button changes to "Requested"
   ✅ Follow request created in Firestore
   ✅ User B receives notification
   ✅ Counts don't change until request accepted
```

### Test Case 5: Slow Network Handling
```
1. Enable network throttling (slow 3G)
2. Navigate to other user's profile
3. Verify:
   ✅ Loading state shows for up to 15 seconds
   ✅ After timeout, error state appears
   ✅ "Try Again" button works
   ✅ No infinite loading
```

---

## 🔧 Troubleshooting

### Issue: Tabs Still Show Infinite Loading

**Diagnosis:**
```dart
// Check console logs for:
print('🎯 UI received ${posts.length} posts for user ${widget.user.uid}');
print('🔍 userArticlesProvider: Starting stream for user $userId');
```

**Solutions:**
1. **Verify User ID:**
   ```dart
   // Make sure you're using profile user's ID, not current user's ID
   final postsAsync = ref.watch(userPostsProvider(profileUser.uid));
   // NOT: ref.watch(userPostsProvider(currentUser.uid));
   ```

2. **Check Firestore Rules:**
   ```javascript
   // Ensure users can read other users' posts
   match /posts/{postId} {
     allow read: if request.auth != null;
   }
   ```

3. **Verify Firestore Indexes:**
   ```
   Collection: posts
   Fields: authorId (Ascending), createdAt (Descending)
   ```

### Issue: Follow Button Doesn't Update

**Diagnosis:**
```dart
// Check console logs for:
log('🔄 Starting follow: $followerId -> $followingId');
log('✅ User followed successfully');
```

**Solutions:**
1. **Invalidate Providers After Action:**
   ```dart
   await ref.read(followProvider.notifier).toggleFollow(targetUserId);
   
   // ✅ Force refresh
   ref.invalidate(isFollowingProvider(targetUserId));
   ref.invalidate(isFollowRequestedProvider(targetUserId));
   ```

2. **Check Follow Document Format:**
   ```
   Collection: follows
   Document ID: {currentUserId}_{targetUserId}
   Fields:
     - followerId: {currentUserId}
     - followingId: {targetUserId}
     - createdAt: timestamp
   ```

3. **Verify Firestore Rules:**
   ```javascript
   match /follows/{followId} {
     allow read: if request.auth != null;
     allow create: if request.auth != null 
                   && request.resource.data.followerId == request.auth.uid;
     allow delete: if request.auth != null 
                   && resource.data.followerId == request.auth.uid;
   }
   ```

### Issue: Wrong User's Data Showing

**This is the MOST COMMON mistake!**

**Diagnosis:**
```dart
// Add debug prints
print('Current User ID: $currentUserId');
print('Profile User ID: $profileUserId');
print('Fetching posts for: ${widget.user.uid}');
```

**Solution:**
```dart
// ❌ WRONG - Shows current user's data everywhere
class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final posts = ref.watch(userPostsProvider(currentUser.uid));  // ❌ WRONG!
  }
}

// ✅ CORRECT - Shows profile user's data
class ProfilePage extends ConsumerWidget {
  final String profileUserId;  // From navigation params
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final profileUser = ref.watch(userProfileByIdProvider(profileUserId));
    
    // Use profileUser.uid for data queries
    final posts = ref.watch(userPostsProvider(profileUser.uid));  // ✅ CORRECT!
  }
}
```

### Issue: Firestore Permission Denied

**Error Message:**
```
[cloud_firestore/permission-denied] The caller does not have permission
```

**Solution:**
```javascript
// Update Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - readable by all authenticated users
    match /userProfiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts - readable by all authenticated users
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
                            && resource.data.authorId == request.auth.uid;
    }
    
    // Follows - readable and writable by authenticated users
    match /follows/{followId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
                    && request.resource.data.followerId == request.auth.uid;
      allow delete: if request.auth != null 
                    && resource.data.followerId == request.auth.uid;
    }
    
    // Follow requests
    match /followRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
                    && request.resource.data.followerId == request.auth.uid;
      allow delete: if request.auth != null 
                    && (resource.data.followerId == request.auth.uid 
                        || resource.data.followingId == request.auth.uid);
    }
  }
}
```

---

## 📊 Summary of Fixes

| Issue | Root Cause | Solution | Status |
|-------|-----------|----------|--------|
| **Tabs not loading** | Using `currentUserId` instead of `profileUserId` | Use `user.uid` (profile user) in all queries | ✅ Fixed |
| **Infinite loading** | No timeout on Firestore queries | Added 15s timeout to all streams | ✅ Fixed |
| **Follow button not working** | Wrong user IDs in follow logic | Use `currentUserId` → `targetUserId` | ✅ Fixed |
| **UI not updating** | Providers not refreshing | Invalidate providers after actions | ✅ Fixed |
| **Silent failures** | No error handling | Added try-catch and error states | ✅ Fixed |

---

## 🎯 Key Takeaways

### Always Remember:
1. **Profile User ≠ Current User** - Use the correct ID for each context
2. **Add Timeouts** - All Firestore queries should have timeouts
3. **Refresh Providers** - Invalidate after mutations
4. **Handle Errors** - Show user-friendly error messages
5. **Test Both Scenarios** - Own profile AND other users' profiles

### The Golden Rule:
```dart
// When viewing a profile:
// - Use profileUser.uid for DATA queries (posts, followers, etc.)
// - Use currentUser.uid for RELATIONSHIP queries (isFollowing, isBlocked, etc.)
// - Use BOTH for ACTIONS (currentUser follows profileUser)
```

---

## 📝 Next Steps

1. **Verify All Implementations** - Check that your code matches the patterns above
2. **Test Thoroughly** - Follow the testing guide for all scenarios
3. **Monitor Logs** - Watch for timeout and error messages
4. **Update Firestore Rules** - Ensure proper permissions
5. **Create Indexes** - Add required composite indexes

---

**Date Created:** 2026-01-20  
**Issue Type:** Profile Data Loading & Follow Functionality  
**Severity:** High (User-facing)  
**Status:** DOCUMENTED ✅  

**Key Insight:** The fundamental issue is confusing `currentUserId` (who is viewing) with `profileUserId` (whose profile is being viewed). Always use the profile user's ID for data queries, and both IDs for relationship operations.
