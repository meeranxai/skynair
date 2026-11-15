# Code Examples: Profile & Follow Fix
## Ready-to-Use Flutter/Dart Code Snippets

---

## 📋 Table of Contents
1. [Profile Page Implementation](#profile-page-implementation)
2. [Profile Tabs Implementation](#profile-tabs-implementation)
3. [Follow Button Implementation](#follow-button-implementation)
4. [Follow Service Implementation](#follow-service-implementation)
5. [Firestore Service Implementation](#firestore-service-implementation)
6. [Provider Setup](#provider-setup)

---

## 1. Profile Page Implementation

### Complete Profile Page Example

```dart
// lib/features/profile/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_content_tabs.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // Profile user ID from navigation

  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current logged-in user
    final currentUser = ref.watch(authProvider).user;
    
    // Determine which profile to show
    final profileUserId = widget.userId ?? currentUser?.uid;
    final isOwnProfile = profileUserId == currentUser?.uid;

    if (profileUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view profiles')),
      );
    }

    // ✅ CORRECT: Fetch profile user's data (not current user's data)
    final profileUserAsync = ref.watch(userProfileByIdProvider(profileUserId));

    return profileUserAsync.when(
      data: (profileUser) => _buildProfilePage(
        context,
        profileUser,
        isOwnProfile,
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userProfileByIdProvider(profileUserId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage(
    BuildContext context,
    UserModel profileUser,
    bool isOwnProfile,
  ) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(profileUser.username),
              pinned: true,
              floating: true,
            ),
          ];
        },
        body: Column(
          children: [
            // Profile Header
            ProfileHeader(
              user: profileUser,
              isOwnProfile: isOwnProfile,
            ),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                Tab(icon: Icon(Icons.photo_library), text: 'Media'),
                Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
              ],
            ),
            
            // Tab Content
            Expanded(
              child: ProfileContentTabs(
                tabController: _tabController,
                user: profileUser,  // ✅ Pass profile user, not current user
                isOwnProfile: isOwnProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 2. Profile Tabs Implementation

### Complete Profile Content Tabs

```dart
// lib/features/profile/widgets/profile_content_tabs.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/models/user_model.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/saved_posts_provider.dart';

class ProfileContentTabs extends ConsumerWidget {
  final TabController tabController;
  final UserModel user;  // ✅ This is the PROFILE USER
  final bool isOwnProfile;

  const ProfileContentTabs({
    super.key,
    required this.tabController,
    required this.user,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      controller: tabController,
      children: [
        // Posts Tab - ✅ Uses profile user's ID
        _PostsTab(user: user, isOwnProfile: isOwnProfile),
        
        // Media Tab - ✅ Uses profile user's ID
        _PostsTab(user: user, isOwnProfile: isOwnProfile),
        
        // Saved/Tagged Tab
        isOwnProfile
            ? _SavedTab(user: user)
            : _TaggedTab(user: user),
      ],
    );
  }
}

// Posts Tab Widget
class _PostsTab extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _PostsTab({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Fetch posts for PROFILE USER (not current user)
    final postsAsync = ref.watch(userPostsProvider(user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPostsProvider(user.uid));
      },
      child: postsAsync.when(
        data: (posts) {
          // Filter for media posts only
          final mediaPosts = posts
              .where((p) => p.postType == 'media')
              .where((p) => isOwnProfile || !p.isDraft)
              .toList();

          if (mediaPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    isOwnProfile
                        ? 'No posts yet. Share your first post!'
                        : 'This user hasn\'t posted anything yet.',
                  ),
                ],
              ),
            );
          }

          // Display posts in grid
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: mediaPosts.length,
            itemBuilder: (context, index) {
              final post = mediaPosts[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to post detail
                },
                child: Image.network(
                  post.image ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userPostsProvider(user.uid));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Saved Tab Widget
class _SavedTab extends ConsumerWidget {
  final UserModel user;

  const _SavedTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Fetch saved posts for PROFILE USER
    final savedPostsAsync = ref.watch(userSavedPostsProvider(user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userSavedPostsProvider(user.uid));
      },
      child: savedPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64),
                  SizedBox(height: 16),
                  Text('No saved posts yet'),
                ],
              ),
            );
          }

          // Display saved posts
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Image.network(
                post.image ?? '',
                fit: BoxFit.cover,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

// Tagged Tab Widget
class _TaggedTab extends ConsumerWidget {
  final UserModel user;

  const _TaggedTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64),
          SizedBox(height: 16),
          Text('No tagged posts'),
          SizedBox(height: 8),
          Text(
            'Posts where this user is tagged will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Follow Button Implementation

### Complete Follow Button Widget

```dart
// lib/features/profile/widgets/follow_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/follow_provider.dart';

class FollowButton extends ConsumerWidget {
  final String targetUserId;  // ✅ The user to follow (profile user)
  final bool isCompact;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Get current logged-in user
    final currentUser = ref.watch(authProvider).user;
    final currentUserId = currentUser?.uid;

    // Don't show button for own profile or when not logged in
    if (currentUserId == null || currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }

    // ✅ CORRECT: Check if CURRENT USER is following TARGET USER
    final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));
    final isRequestedAsync = ref.watch(isFollowRequestedProvider(targetUserId));
    final followState = ref.watch(followProvider);

    return isFollowingAsync.when(
      data: (isFollowing) => isRequestedAsync.when(
        data: (isRequested) => _buildButton(
          context,
          ref,
          theme,
          isFollowing,
          isRequested,
          followState.isLoading,
        ),
        loading: () => _buildLoadingButton(theme),
        error: (_, __) => _buildErrorButton(theme),
      ),
      loading: () => _buildLoadingButton(theme),
      error: (_, __) => _buildErrorButton(theme),
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isFollowing,
    bool isRequested,
    bool isLoading,
  ) {
    String label;
    IconData icon;
    Color bgColor;
    Color fgColor;

    if (isFollowing) {
      label = 'Unfollow';
      icon = Icons.person_remove;
      bgColor = theme.colorScheme.surfaceVariant;
      fgColor = theme.colorScheme.onSurfaceVariant;
    } else if (isRequested) {
      label = 'Requested';
      icon = Icons.hourglass_empty;
      bgColor = theme.colorScheme.surfaceVariant;
      fgColor = theme.colorScheme.onSurfaceVariant;
    } else {
      label = 'Follow';
      icon = Icons.person_add;
      bgColor = theme.colorScheme.primary;
      fgColor = theme.colorScheme.onPrimary;
    }

    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () async {
              try {
                // ✅ CORRECT: Toggle follow for TARGET USER
                await ref.read(followProvider.notifier).toggleFollow(
                      targetUserId,
                      isFollowing: isFollowing,
                      isRequested: isRequested,
                    );

                // ✅ MUST: Refresh providers to update UI
                ref.invalidate(isFollowingProvider(targetUserId));
                ref.invalidate(isFollowRequestedProvider(targetUserId));

                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFollowing
                            ? 'Unfollowed successfully'
                            : isRequested
                                ? 'Request cancelled'
                                : 'Followed successfully',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      icon: Icon(icon, size: isCompact ? 16 : 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 20,
          vertical: isCompact ? 8 : 12,
        ),
      ),
    );
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceVariant,
      ),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(
            theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.error_outline, size: 16),
      label: const Text('Error'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
    );
  }
}
```

---

## 4. Follow Service Implementation

### Complete Follow Service

```dart
// lib/core/services/follow_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'dart:async';

import '../config/firebase_config.dart';

class FollowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a user
  /// [followerId] - Current user (who is following)
  /// [followingId] - Target user (who to follow)
  static Future<void> followUser(String followerId, String followingId) async {
    // ✅ Validation: Can't follow yourself
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    log('🔄 Starting follow: $followerId -> $followingId');

    try {
      await _firestore.runTransaction((transaction) async {
        // ✅ CORRECT: Document ID format is {followerId}_{followingId}
        final followRef = _firestore
            .collection(FirebaseConfig.follows)
            .doc('${followerId}_$followingId');

        // Check if already following
        final followDoc = await transaction.get(followRef);
        if (followDoc.exists) {
          log('⚠️ Already following');
          return;
        }

        // Create follow relationship
        transaction.set(followRef, {
          'followerId': followerId,    // ✅ Current user
          'followingId': followingId,  // ✅ Target user
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update follower's following count
        final followerRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followerId);

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
            .doc(followingId);

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
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your connection.');
      }
      rethrow;
    }
  }

  /// Unfollow a user
  /// [followerId] - Current user (who is unfollowing)
  /// [followingId] - Target user (who to unfollow)
  static Future<void> unfollowUser(String followerId, String followingId) async {
    log('🔄 Starting unfollow: $followerId -> $followingId');

    try {
      await _firestore.runTransaction((transaction) async {
        final followRef = _firestore
            .collection(FirebaseConfig.follows)
            .doc('${followerId}_$followingId');

        final followDoc = await transaction.get(followRef);
        if (!followDoc.exists) {
          log('⚠️ Follow relationship does not exist');
          return;
        }

        // Delete follow relationship
        transaction.delete(followRef);

        // Safely decrement follower's following count
        final followerRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followerId);

        final followerDoc = await transaction.get(followerRef);
        if (followerDoc.exists) {
          final currentFollowing =
              (followerDoc.data()?['followingCount'] as int?) ?? 0;
          if (currentFollowing > 0) {
            transaction.update(followerRef, {
              'followingCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Safely decrement following user's followers count
        final followingRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followingId);

        final followingDoc = await transaction.get(followingRef);
        if (followingDoc.exists) {
          final currentFollowers =
              (followingDoc.data()?['followersCount'] as int?) ?? 0;
          if (currentFollowers > 0) {
            transaction.update(followingRef, {
              'followersCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      log('✅ User unfollowed successfully: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if current user is following target user
  /// [followerId] - Current user
  /// [followingId] - Target user
  static Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.follows)
          .doc('${followerId}_$followingId')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('⚠️ isFollowing timeout for $followerId -> $followingId');
              throw TimeoutException('Follow status check timed out');
            },
          );

      return doc.exists;
    } catch (e) {
      log('❌ Error checking follow status: $e');
      return false; // Safe default
    }
  }

  /// Check if current user has requested to follow target user
  static Future<bool> isFollowRequested(
    String followerId,
    String followingId,
  ) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('⚠️ isFollowRequested timeout');
              throw TimeoutException('Follow request check timed out');
            },
          );

      return doc.exists;
    } catch (e) {
      log('❌ Error checking follow request: $e');
      return false; // Safe default
    }
  }

  /// Check if user is private
  static Future<bool> isUserPrivate(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('⚠️ isUserPrivate timeout');
              throw TimeoutException('Privacy check timed out');
            },
          );

      return doc.data()?['isPrivate'] as bool? ?? false;
    } catch (e) {
      log('❌ Error checking privacy: $e');
      return false; // Safe default: assume public
    }
  }

  /// Send follow request to private account
  static Future<void> sendFollowRequest(
    String followerId,
    String followingId,
  ) async {
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      await _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .set({
        'followerId': followerId,
        'followingId': followingId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      log('✅ Follow request sent: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error sending follow request: $e');
      rethrow;
    }
  }

  /// Cancel follow request
  static Future<void> cancelFollowRequest(
    String followerId,
    String followingId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .delete();

      log('✅ Follow request cancelled: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error cancelling follow request: $e');
      rethrow;
    }
  }

  /// Get followers list
  static Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followingId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();
    } catch (e) {
      log('❌ Error getting followers: $e');
      return [];
    }
  }

  /// Get following list
  static Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();
    } catch (e) {
      log('❌ Error getting following: $e');
      return [];
    }
  }
}
```

---

## 5. Firestore Service Implementation

### User Posts Stream

```dart
// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../models/post_model.dart';
import '../config/firebase_config.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's posts stream
  /// [userId] - The user whose posts to fetch (profile user, not current user)
  static Stream<List<PostModel>> getUserPostsStream(String userId) {
    dev.log('🔍 Starting getUserPostsStream for user: $userId');

    return _firestore
        .collection(FirebaseConfig.posts)
        .where('authorId', isEqualTo: userId)  // ✅ Filter by profile user
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
          dev.log('📦 Received ${snapshot.docs.length} posts for user $userId');
          return snapshot.docs
              .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        })
        .handleError((e) {
          dev.log('❌ Error in getUserPostsStream: $e');
          return <PostModel>[];
        });
  }

  /// Get user's saved posts stream
  /// [userId] - The user whose saved posts to fetch
  static Stream<List<PostModel>> getUserSavedPostsStream(String userId) {
    dev.log('🔍 Starting getUserSavedPostsStream for user: $userId');

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
          dev.log('📦 Received ${snapshot.docs.length} saved posts');
          return snapshot.docs
              .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        })
        .handleError((e) {
          dev.log('❌ Error in getUserSavedPostsStream: $e');
          
          // Fallback: Try without orderBy (in case index is missing)
          return _firestore
              .collection(FirebaseConfig.posts)
              .where('saves', arrayContains: userId)
              .snapshots()
              .timeout(const Duration(seconds: 15))
              .map((snapshot) {
            final posts = snapshot.docs
                .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
                .toList();
            
            // Sort client-side
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return posts;
          });
        });
  }

  /// Get user's articles stream
  static Stream<List<PostModel>> getUserArticlesStream(String userId) {
    dev.log('🔍 Starting getUserArticlesStream for user: $userId');

    return _firestore
        .collection(FirebaseConfig.posts)
        .where('authorId', isEqualTo: userId)  // ✅ Filter by profile user
        .where('postType', isEqualTo: 'article')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            dev.log('⚠️ getUserArticlesStream timeout for user $userId');
            sink.addError('Timeout loading articles');
            sink.close();
          },
        )
        .map((snapshot) {
          dev.log('📦 Received ${snapshot.docs.length} articles');
          return snapshot.docs
              .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        })
        .handleError((e) {
          dev.log('❌ Error in getUserArticlesStream: $e');
          return <PostModel>[];
        });
  }
}
```

---

## 6. Provider Setup

### Follow Providers

```dart
// lib/core/providers/follow_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/follow_service.dart';
import 'auth_provider.dart';

/// Check if current user is following target user
/// [targetUserId] - The user to check (profile user)
final isFollowingProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) async {
    final currentUserId = ref.watch(authProvider).user?.uid;
    
    if (currentUserId == null || currentUserId == targetUserId) {
      return false;
    }

    // ✅ CORRECT: Check if currentUser is following targetUser
    return await FollowService.isFollowing(currentUserId, targetUserId);
  },
);

/// Check if current user has requested to follow target user
final isFollowRequestedProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) async {
    final currentUserId = ref.watch(authProvider).user?.uid;
    
    if (currentUserId == null || currentUserId == targetUserId) {
      return false;
    }

    // ✅ CORRECT: Check if currentUser has requested targetUser
    return await FollowService.isFollowRequested(currentUserId, targetUserId);
  },
);

/// Follow state
class FollowState {
  final bool isLoading;
  final String? error;

  FollowState({this.isLoading = false, this.error});

  FollowState copyWith({bool? isLoading, String? error}) {
    return FollowState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Follow state provider
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>(
  (ref) => FollowNotifier(ref),
);

/// Follow notifier
class FollowNotifier extends StateNotifier<FollowState> {
  final Ref ref;

  FollowNotifier(this.ref) : super(FollowState());

  /// Toggle follow status
  /// [targetUserId] - The user to follow/unfollow
  Future<void> toggleFollow(
    String targetUserId, {
    required bool isFollowing,
    required bool isRequested,
  }) async {
    final currentUserId = ref.read(authProvider).user?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      if (isFollowing) {
        // ✅ Unfollow: currentUser unfollows targetUser
        await FollowService.unfollowUser(currentUserId, targetUserId);
      } else if (isRequested) {
        // ✅ Cancel request
        await FollowService.cancelFollowRequest(currentUserId, targetUserId);
      } else {
        // Check if target is private
        final isPrivate = await FollowService.isUserPrivate(targetUserId);

        if (isPrivate) {
          // ✅ Send follow request
          await FollowService.sendFollowRequest(currentUserId, targetUserId);
        } else {
          // ✅ Follow directly
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

### Posts Providers

```dart
// lib/core/providers/posts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import '../services/firestore_service.dart';

/// User posts provider
/// [userId] - The user whose posts to fetch (profile user)
final userPostsProvider = StreamProvider.family<List<PostModel>, String>(
  (ref, userId) {
    // ✅ CORRECT: Fetch posts for the specified user (profile user)
    return FirestoreService.getUserPostsStream(userId);
  },
);

/// User saved posts provider
final userSavedPostsProvider = StreamProvider.family<List<PostModel>, String>(
  (ref, userId) {
    // ✅ CORRECT: Fetch saved posts for the specified user
    return FirestoreService.getUserSavedPostsStream(userId);
  },
);

/// User articles provider
final userArticlesProvider = StreamProvider.family<List<PostModel>, String>(
  (ref, userId) {
    // ✅ CORRECT: Fetch articles for the specified user
    return FirestoreService.getUserArticlesStream(userId);
  },
);
```

---

## 🎯 Usage Examples

### Example 1: Navigate to Profile
```dart
// Navigate to another user's profile
context.push('/profile/${otherUser.uid}');

// Navigate to own profile
context.push('/profile');  // Will use current user's ID
```

### Example 2: Display Follow Button
```dart
// In profile header
FollowButton(
  targetUserId: profileUser.uid,  // ✅ Profile user's ID
  isCompact: false,
)
```

### Example 3: Check Follow Status
```dart
// Check if current user is following profile user
final isFollowing = await FollowService.isFollowing(
  currentUser.uid,   // Current user
  profileUser.uid,   // Profile user
);
```

---

**Last Updated:** 2026-01-20  
**Version:** 1.0  
**Status:** Ready to Use ✅
