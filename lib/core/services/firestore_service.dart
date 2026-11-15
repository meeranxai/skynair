import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as dev;
import 'dart:math';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';
import '../config/firebase_config.dart';
import 'supabase_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Management
  static Future<void> saveFcmToken(String uid, String token) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection(FirebaseConfig.userProfiles).doc(uid).set({
        'uid': uid, // Ensure UID is present
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      dev.log('✅ FCM token saved to Firestore for user: $uid');
    } catch (e) {
      dev.log('❌ Error saving FCM token: $e');
    }
  }

  // User Management
  static Future<void> createUserProfile(UserModel user) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        dev.log(
          '🔄 Creating user profile in Firestore: ${user.uid} (attempt ${retryCount + 1})',
        );
        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(user.uid)
            .set(user.toMap());
        dev.log('✅ User profile created: ${user.uid}');
        return;
      } catch (e) {
        dev.log(
          '❌ Error creating user profile (attempt ${retryCount + 1}): $e',
        );

        // Check if it's a permission error
        if (e.toString().contains('permission') ||
            e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('Missing or insufficient permissions')) {
          dev.log(
            '⚠️ Firestore permission denied - app will work with local profile only',
          );
          throw FirestorePermissionException(
            'Firestore permissions not configured. App will work with local profile.',
          );
        }

        // Check if it's a network error and retry
        if ((e.toString().contains('network') ||
                e.toString().contains('timeout') ||
                e.toString().contains('unavailable')) &&
            retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(
            Duration(seconds: retryCount * 2),
          ); // Exponential backoff
          continue;
        }

        rethrow;
      }
    }
  }

  static Future<UserModel?> getUserProfile(String uid) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        dev.log(
          '🔄 Getting user profile from Firestore: $uid (attempt ${retryCount + 1})',
        );
        final doc = await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(uid)
            .get();

        if (doc.exists && doc.data() != null) {
          dev.log('✅ User profile found in Firestore: $uid');
          return UserModel.fromMap(doc.data()!);
        }

        dev.log(
          'ℹ️ User profile not found in Firestore: $uid, creating one...',
        );
        // Create a default profile if it doesn't exist
        // This handles cases where a user auth exists but profile data is missing
        final newUser = UserModel(
          uid: uid,
          email:
              '', // We don't have email here, but that's okay for basic display
          username: 'user_${uid.substring(0, 5)}', // Temporary username
          displayName: 'User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          // Attempt to create it. If it fails due to permissions (e.g. not the owner),
          // we just return the temporary model so the UI can at least show something.
          // However, we can't write to another user's profile usually.
          // So providing a dummy return is safer than crashing or hanging.
          return newUser;
        } catch (e) {
          return newUser;
        }
      } catch (e) {
        dev.log('❌ Error getting user profile (attempt ${retryCount + 1}): $e');

        // Check if it's a permission error
        if (e.toString().contains('permission') ||
            e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('Missing or insufficient permissions')) {
          dev.log(
            '⚠️ Firestore permission denied - returning temporary profile',
          );
          // Return a temporary profile instead of null to prevent loading hangs
          return UserModel(
            uid: uid,
            email: '',
            username: 'User',
            displayName: 'User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        // Check if it's a network error and retry
        if ((e.toString().contains('network') ||
                e.toString().contains('timeout') ||
                e.toString().contains('unavailable')) &&
            retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(
            Duration(seconds: retryCount * 2),
          ); // Exponential backoff
          continue;
        }

        dev.log('⚠️ Firestore error, returning temporary profile: $e');
        return UserModel(
          uid: uid,
          email: '',
          username: 'User',
          displayName: 'User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  static Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection(FirebaseConfig.userProfiles)
        .doc(uid)
        .snapshots()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            dev.log(
              '⚠️ getUserProfileStream timed out for $uid - providing fallback',
            );
            // Trigger error which will be handled by handleError
            sink.addError('Profile loading timeout');
            sink.close();
          },
        )
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            try {
              return UserModel.fromMap(doc.data()!);
            } catch (e) {
              dev.log('❌ Error parsing user profile for $uid: $e');
              // Return fallback profile on parse error
              return _createFallbackProfile(uid);
            }
          }
          dev.log(
            'ℹ️ Stream: User profile not found for $uid - creating fallback',
          );
          // Return fallback profile instead of null
          return _createFallbackProfile(uid);
        })
        .handleError((e) {
          dev.log('❌ Stream Error for $uid: $e');
          // Return fallback profile on error
          return _createFallbackProfile(uid);
        });
  }

  // Helper method to create a fallback profile
  static UserModel _createFallbackProfile(String uid) {
    return UserModel(
      uid: uid,
      email: '',
      username: 'user_${uid.substring(0, min(5, uid.length))}',
      displayName: 'User',
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection(FirebaseConfig.userProfiles)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (uid.isEmpty) {
      dev.log('⚠️ Attempted to update profile with empty UID');
      return;
    }
    try {
      await _firestore.collection(FirebaseConfig.userProfiles).doc(uid).set({
        ...data,
        'uid': uid, // Ensure UID is always present
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      dev.log('✅ User profile updated: $uid');
    } catch (e) {
      dev.log('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<void> deleteUserData(String uid) async {
    try {
      dev.log('🔄 Deleting user data for: $uid');

      // 1. Delete user profile document
      await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(uid)
          .delete();

      // 2. Optional: You could also delete posts, comments, etc.
      // For now, deleting the profile is enough to make the user appear "deleted" in real-time
      // because LiveUser widgets listen to this document.

      dev.log('✅ User data deleted from Firestore');
    } catch (e) {
      dev.log('❌ Error deleting user data: $e');
      // Non-critical if it fails, but should be logged
    }
  }

  static Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection(FirebaseConfig.userProfiles).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('❌ Error updating online status: $e');
    }
  }

  static Future<void> updateUserFcmToken(String uid, String token) async {
    try {
      await _firestore.collection(FirebaseConfig.userProfiles).doc(uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      dev.log('❌ Error updating FCM token in Firestore: $e');
    }
  }

  // Posts Management
  static Future<String> createPost(PostModel post) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConfig.posts)
          .add(post.toMap());

      // Increment counts in user profile (ONLY if not a draft)
      if (post.isDraft != true) {
        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(post.authorId)
            .set({
          'postsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((e) => dev.log('⚠️ Failed to update counts: $e'));
      }

      dev.log('✅ Post created and count updated: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      dev.log('❌ Error creating post: $e');
      rethrow;
    }
  }

  static Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.posts)
          .doc(postId)
          .get();

      if (doc.exists && doc.data() != null) {
        return PostModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      dev.log('❌ Error getting post: $e');
      return null;
    }
  }

  static Stream<List<PostModel>> getPostsStream({
    int limit = 50,
    String? postType,
    DocumentSnapshot? lastDocument,
  }) {
    // 1. Basic Query Construction
    Query query = _firestore.collection(FirebaseConfig.posts);

    // 2. Apply Filters
    // Note: 'postType' equality filter + 'createdAt' sort *usually* works with auto-indexes,
    // but a composite index "postType ASC, createdAt DESC" is recommended for performance.
    if (postType != null) {
      query = query.where('postType', isEqualTo: postType);
    }

    // 3. Apply Sort & Limit
    query = query.orderBy('createdAt', descending: true).limit(limit);

    // 4. Pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // 5. Execute Stream with Safety
    return query
        .snapshots()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            dev.log('⚠️ getPostsStream timed out');
            sink.addError('Timeout fetching feed');
          },
        )
        .map((snapshot) {
          try {
            return snapshot.docs
                .map(
                  (doc) => PostModel.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }),
                )
                .where((post) => post.isArchived != true)
                .toList();
          } catch (e) {
            dev.log('❌ Error parsing feed posts: $e');
            return <PostModel>[];
          }
        })
        .handleError((e) {
          dev.log('❌ getPostsStream failed: $e');
          // Check for missing index error specifically
          if (e.toString().contains('failed-precondition')) {
            dev.log(
              '💡 TIP: You might need to create a composite index for this query.',
            );
            dev.log(
              '   Index: Collection: posts, Fields: postType ASC, createdAt DESC',
            );
          }
          // safely return empty list to UI instead of crashing
          return <PostModel>[];
        });
  }

  // Single Post Stream (for Detail Views)
  static Stream<PostModel?> getPostStream(String postId) {
    return _firestore
        .collection(FirebaseConfig.posts)
        .doc(postId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return PostModel.fromMap({...doc.data()!, 'id': doc.id});
          }
          return null;
        });
  }

  static Future<List<PostModel>> getPosts({
    int limit = 50,
    String? postType,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConfig.posts);
      if (postType != null) {
        query = query.where('postType', isEqualTo: postType);
      }
      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => PostModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      dev.log(
        '⚠️ Optimized getPosts failed (likely missing index), trying simple filter: $e',
      );
      try {
        Query fallbackQuery = _firestore.collection(FirebaseConfig.posts);
        if (postType != null) {
          fallbackQuery = fallbackQuery.where('postType', isEqualTo: postType);
        }

        final snapshot = await fallbackQuery.limit(limit).get();
        final posts = snapshot.docs
            .map(
              (doc) => PostModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      } catch (e2) {
        dev.log('❌ Fallback getPosts also failed: $e2');
        return [];
      }
    }
  }

  static Stream<List<PostModel>> getUserPostsStream(String userId) {
    dev.log('🔍 Starting getUserPostsStream for user: $userId');

    // Simplified: Query by authorId only to avoid strict composite index requirements.
    // Client-side filtering for 'media' and sorting by 'createdAt'.
    return _firestore
        .collection(FirebaseConfig.posts)
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            dev.log('⚠️ getUserPostsStream timeout for user $userId');
            sink.addError('Posts loading timeout - check indexes and network');
            sink.close();
          },
        )
        .map((snapshot) {
          try {
            dev.log(
              '📊 Processing ${snapshot.docs.length} documents for user $userId',
            );

            // Debug: Log all documents found
            for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
              final doc = snapshot.docs[i];
              final data = doc.data();
              dev.log(
                '📄 Doc $i: ${doc.id} - ${data['title']} (type: ${data['postType']}, draft: ${data['isDraft']}, archived: ${data['isArchived']})',
              );
            }

            final posts = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    final post = PostModel.fromMap({...data, 'id': doc.id});

                    return post;
                  } catch (e) {
                    dev.log('❌ Error parsing post ${doc.id}: $e');
                    return null;
                  }
                })
                .where(
                  (p) =>
                      p != null &&
                      p.postType == 'media' &&
                      p.isArchived != true,
                )
                .cast<PostModel>()
                .toList();

            // Sort client-side
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            dev.log(
              '✅ Returning ${posts.length} media posts for user $userId (filtered from ${snapshot.docs.length} total)',
            );
            return posts;
          } catch (e) {
            dev.log('❌ Error processing posts snapshot: $e');
            return <PostModel>[];
          }
        })
        .handleError((e) {
          dev.log('❌ getUserPostsStream error: $e');
          return <PostModel>[];
        });
  }



  static Future<void> updatePost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(FirebaseConfig.posts).doc(postId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      dev.log('✅ Post updated: $postId');
    } catch (e) {
      dev.log('❌ Error updating post: $e');
      rethrow;
    }
  }

  static Future<void> deletePost(String postId) async {
    try {
      final postRef = _firestore.collection(FirebaseConfig.posts).doc(postId);
      final postDoc = await postRef.get();
      
      if (postDoc.exists) {
        final postData = postDoc.data()!;
        final authorId = postData['authorId'] as String?;
        final postType = postData['postType'] as String?;
        final isDraft = postData['isDraft'] as bool? ?? false;

        await postRef.delete();

        if (authorId != null && !isDraft) {
          // Decrement counts
          await _firestore
              .collection(FirebaseConfig.userProfiles)
              .doc(authorId)
              .update({
            'postsCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          }).catchError((e) => dev.log('⚠️ Failed to decrement counts: $e'));
        }
      }
      dev.log('✅ Post deleted and counts updated: $postId');
    } catch (e) {
      dev.log('❌ Error deleting post: $e');
      rethrow;
    }
  }

  static Future<void> submitReport({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    try {
      await _firestore.collection(FirebaseConfig.reports).add({
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      dev.log('✅ Report submitted for $targetType: $targetId');
    } catch (e) {
      dev.log('❌ Error submitting report: $e');
      rethrow;
    }
  }

  static Stream<List<PostModel>> getArchivedPostsStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.posts)
        .where('authorId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .where('postType', isEqualTo: 'media')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }



  static Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection(FirebaseConfig.posts).doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('❌ Error liking post: $e');
      rethrow;
    }
  }

  static Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection(FirebaseConfig.posts).doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('❌ Error unliking post: $e');
      rethrow;
    }
  }

  static Future<void> savePost(String postId, String userId) async {
    try {
      await _firestore.collection(FirebaseConfig.posts).doc(postId).update({
        'saves': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('❌ Error saving post: $e');
      rethrow;
    }
  }

  static Future<void> unsavePost(String postId, String userId) async {
    try {
      await _firestore.collection(FirebaseConfig.posts).doc(postId).update({
        'saves': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('❌ Error unsaving post: $e');
      rethrow;
    }
  }

  // Search functionality
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: '${query.toLowerCase()}z')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      dev.log('❌ Error searching users: $e');
      return [];
    }
  }

  static Future<List<PostModel>> searchPosts(String query) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.posts)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      dev.log('❌ Error searching posts: $e');
      return [];
    }
  }

  static Future<bool> isEmailRegistered(String email) async {
    try {
      dev.log('🔄 Checking if email is registered: $email');
      final snapshot = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      final exists = snapshot.docs.isNotEmpty;
      dev.log('✅ Email $email registration status: $exists');
      return exists;
    } catch (e) {
      dev.log('❌ Error checking email registration: $e');
      return false;
    }
  }

  // Username Management
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      dev.log('🔄 Checking username availability: $username');
      final snapshot = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      final isAvailable = snapshot.docs.isEmpty;
      dev.log('✅ Username $username availability: $isAvailable');
      return isAvailable;
    } catch (e) {
      dev.log('❌ Error checking username availability: $e');
      // If there's an error, assume username is not available for safety
      return false;
    }
  }

  static Future<String> generateUniqueUsername(String baseUsername) async {
    try {
      dev.log('🔄 Generating unique username from: $baseUsername');

      // Clean the base username
      String cleanUsername = baseUsername
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      // Ensure minimum length
      if (cleanUsername.length < 3) {
        cleanUsername = '${cleanUsername}user';
      }

      // Ensure maximum length
      if (cleanUsername.length > 20) {
        cleanUsername = cleanUsername.substring(0, 20);
      }

      // Check if base username is available
      if (await isUsernameAvailable(cleanUsername)) {
        dev.log('✅ Base username available: $cleanUsername');
        return cleanUsername;
      }

      // Try with numbers
      for (int i = 1; i <= 999; i++) {
        String candidate = '$cleanUsername$i';
        if (candidate.length > 25) {
          // If too long, truncate base and try again
          cleanUsername = cleanUsername.substring(0, 20);
          candidate = '$cleanUsername$i';
        }

        if (await isUsernameAvailable(candidate)) {
          dev.log('✅ Generated unique username: $candidate');
          return candidate;
        }
      }

      // If all numbers fail, add random suffix
      final random = Random();
      for (int i = 0; i < 10; i++) {
        String randomSuffix = random.nextInt(9999).toString();
        String candidate = '$cleanUsername$randomSuffix';
        if (candidate.length > 25) {
          cleanUsername = cleanUsername.substring(0, 20);
          candidate = '$cleanUsername$randomSuffix';
        }

        if (await isUsernameAvailable(candidate)) {
          dev.log('✅ Generated random unique username: $candidate');
          return candidate;
        }
      }

      // Last resort - use timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fallback = 'user$timestamp';
      dev.log('⚠️ Using fallback username: $fallback');
      return fallback;
    } catch (e) {
      dev.log('❌ Error generating unique username: $e');
      // Fallback to timestamp-based username
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'user$timestamp';
    }
  }

  static Future<UserModel?> getUserByUsername(String username) async {
    try {
      dev.log('🔄 Getting user by username: $username');
      final snapshot = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        dev.log('✅ User found by username: $username');
        return UserModel.fromMap(snapshot.docs.first.data());
      }

      dev.log('ℹ️ User not found by username: $username');
      return null;
    } catch (e) {
      dev.log('❌ Error getting user by username: $e');
      return null;
    }
  }

  // Image Upload Methods using Supabase
  static Future<String> uploadPostImage(XFile imageFile, String userId) async {
    try {
      dev.log('🔄 Uploading post image to Supabase for user: $userId');

      final supabaseService = SupabaseService();

      if (!supabaseService.isInitialized) {
        throw 'Supabase not initialized. Please check your configuration.';
      }

      final imageUrl = await supabaseService.uploadImage(
        imageFile,
        folder: 'post_images',
      );

      dev.log('✅ Post image uploaded successfully to Supabase: $imageUrl');
      return imageUrl;
    } catch (e) {
      dev.log('❌ Error uploading post image to Supabase: $e');
      dev.log('❌ Error type: ${e.runtimeType}');
      dev.log('❌ Full error details: ${e.toString()}');

      if (e.toString().contains('not initialized')) {
        dev.log('🔍 Possible causes:');
        dev.log('   1. Supabase URL or anon key not configured');
        dev.log('   2. Storage bucket "images" does not exist');
        dev.log('   3. Storage policies not configured correctly');
        dev.log('💡 Solution: Check .env.supabase file and Supabase dashboard');
      }

      throw 'Failed to upload image: $e';
    }
  }

  static Future<String> uploadProfileImage(
    XFile imageFile,
    String userId,
  ) async {
    try {
      dev.log('🔄 Uploading profile image to Supabase for user: $userId');

      final supabaseService = SupabaseService();

      if (!supabaseService.isInitialized) {
        throw 'Supabase not initialized. Please check your configuration.';
      }

      // ✅ CRITICAL: Verify user is authenticated before upload
      // Since the app uses Firebase Auth, we check for firebase user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        dev.log('❌ User not authenticated in Firebase - cannot upload');
        throw 'User not logged in. Please login and try again.';
      }

      if (currentUser.uid != userId) {
        dev.log('⚠️ User ID mismatch: ${currentUser.uid} != $userId');
      }

      dev.log(
        '✅ User authenticated in Firebase: ${currentUser.email} (${currentUser.uid})',
      );

      final imageUrl = await supabaseService.uploadImage(
        imageFile,
        folder: 'profile_pictures',
        customFileName: 'profile_$userId',
        upsert: true,
      );

      dev.log('✅ Profile image uploaded successfully to Supabase: $imageUrl');
      return imageUrl;
    } catch (e) {
      dev.log('❌ Error uploading profile image to Supabase: $e');
      throw 'Failed to upload profile image: $e';
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      dev.log('🔄 Deleting image from Supabase: $imageUrl');

      final supabaseService = SupabaseService();

      if (!supabaseService.isInitialized) {
        dev.log('⚠️ Supabase not initialized, skipping image deletion');
        return;
      }

      await supabaseService.deleteImage(imageUrl);

      dev.log('✅ Image deleted successfully from Supabase');
    } catch (e) {
      dev.log('❌ Error processing image deletion: $e');
      // Don't throw error for image deletion failures
    }
  }

  // Notification Management
  static Future<String> createNotification(
    NotificationModel notification,
  ) async {
    try {
      dev.log(
        '🔄 Creating notification: ${notification.type} from ${notification.fromUsername}',
      );
      final docRef = await _firestore
          .collection(FirebaseConfig.notifications)
          .add(notification.toMap());

      dev.log('✅ Notification created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      dev.log('❌ Error creating notification: $e');
      rethrow;
    }
  }

  static Future<NotificationModel?> getNotification(
    String notificationId,
  ) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.notifications)
          .doc(notificationId)
          .get();

      if (doc.exists && doc.data() != null) {
        return NotificationModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      dev.log('❌ Error getting notification: $e');
      return null;
    }
  }

  static Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    try {
      return _firestore
          .collection(FirebaseConfig.notifications)
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      NotificationModel.fromMap({...doc.data(), 'id': doc.id}),
                )
                .toList(),
          );
    } catch (e) {
      dev.log('❌ Error in getNotificationsStream (likely missing index): $e');

      // Fallback: Get notifications without ordering
      return _firestore
          .collection(FirebaseConfig.notifications)
          .where('toUserId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final notifications = snapshot.docs
                .map(
                  (doc) =>
                      NotificationModel.fromMap({...doc.data(), 'id': doc.id}),
                )
                .toList();

            // Sort locally by createdAt
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return notifications;
          });
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConfig.notifications)
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      dev.log('✅ Notification marked as read: $notificationId');
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(FirebaseConfig.notifications)
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      dev.log('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      dev.log('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConfig.notifications)
          .doc(notificationId)
          .delete();
      dev.log('✅ Notification deleted: $notificationId');
    } catch (e) {
      dev.log('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  static Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(FirebaseConfig.notifications)
          .where('toUserId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      dev.log('✅ All notifications cleared for user: $userId');
    } catch (e) {
      dev.log('❌ Error clearing all notifications: $e');
      rethrow;
    }
  }

  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.notifications)
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      dev.log('❌ Error getting unread notification count: $e');
      return 0;
    }
  }

  // Helper method to check for duplicate notifications
  static Future<bool> notificationExists({
    required String type,
    required String fromUserId,
    required String toUserId,
    String? postId,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConfig.notifications)
          .where('type', isEqualTo: type)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId);

      if (postId != null) {
        query = query.where('postId', isEqualTo: postId);
      }

      final snapshot = await query.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      dev.log('❌ Error checking notification existence: $e');
      return false;
    }
  }

  // Get all posts (for saved posts functionality)
  static Future<List<PostModel>> getAllPosts() async {
    try {
      final snapshot = await _firestore.collection(FirebaseConfig.posts).get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by creation date (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return posts;
    } catch (e) {
      dev.log('❌ Error getting all posts: $e');
      return [];
    }
  }

  // Get saved posts stream for a user
  static Stream<List<PostModel>> getUserSavedPostsStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.posts)
        .where('saves', arrayContains: userId)
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        )
        .handleError((e) {
          dev.log(
            '⚠️ Optimized getUserSavedPostsStream failed, using fallback: $e',
          );
          return _firestore
              .collection(FirebaseConfig.posts)
              .where('saves', arrayContains: userId)
              .snapshots()
              .timeout(
                const Duration(seconds: 15),
                onTimeout: (sink) {
                  dev.log(
                    '⚠️ Fallback getUserSavedPostsStream timeout for user $userId',
                  );
                  sink.addError('Timeout loading saved posts');
                  sink.close();
                },
              )
              .map((snapshot) {
                final posts = snapshot.docs
                    .map(
                      (doc) => PostModel.fromMap({...doc.data(), 'id': doc.id}),
                    )
                    .toList();
                posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return posts;
              });
        });
  }

  // Get user followers (returns full UserModel objects)
  static Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      dev.log('🔄 Getting followers for user: $userId');

      // Get follower IDs from follows collection
      final followsSnapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followingId', isEqualTo: userId)
          .get();

      final followerIds = followsSnapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) {
        dev.log('ℹ️ No followers found for user: $userId');
        return [];
      }

      // Get user profiles for all follower IDs
      final List<UserModel> followers = [];
      for (final followerId in followerIds) {
        final user = await getUserProfile(followerId);
        if (user != null) {
          followers.add(user);
        }
      }

      dev.log('✅ Found ${followers.length} followers for user: $userId');
      return followers;
    } catch (e) {
      dev.log('❌ Error getting user followers: $e');
      return [];
    }
  }

  // Get user following (returns full UserModel objects)
  static Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      dev.log('🔄 Getting following for user: $userId');

      // Get following IDs from follows collection
      final followsSnapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followerId', isEqualTo: userId)
          .get();

      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) {
        dev.log('ℹ️ No following found for user: $userId');
        return [];
      }

      // Get user profiles for all following IDs
      final List<UserModel> following = [];
      for (final followingId in followingIds) {
        final user = await getUserProfile(followingId);
        if (user != null) {
          following.add(user);
        }
      }

      dev.log('✅ Found ${following.length} following for user: $userId');
      return following;
    } catch (e) {
      dev.log('❌ Error getting user following: $e');
      return [];
    }
  }

  static Future<void> syncUserStats(String userId) async {
    try {
      dev.log('🔄 Syncing stats for user: $userId');

      // 1. Get total post count (Media + Articles, Exclude drafts)
      final allPostsQuery = await _firestore
          .collection(FirebaseConfig.posts)
          .where('authorId', isEqualTo: userId)
          .where('isDraft', whereIn: [false, null]) // Count both false and missing isDraft
          .count()
          .get();
      int postsCount = allPostsQuery.count ?? 0;

      // 2. Keep article count separate for specific needs if required
      final articlesQuery = await _firestore
          .collection(FirebaseConfig.posts)
          .where('authorId', isEqualTo: userId)
          .where('postType', isEqualTo: 'article')
          .where('isDraft', whereIn: [false, null])
          .count()
          .get();
      int articlesCount = articlesQuery.count ?? 0;

      // 3. Get followers count efficiently
      final followersQuery = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followingId', isEqualTo: userId)
          .count()
          .get();
      final followersCount = followersQuery.count ?? 0;

      // 4. Get following count efficiently
      final followingQuery = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followerId', isEqualTo: userId)
          .count()
          .get();
      final followingCount = followingQuery.count ?? 0;

      // Update user profile with all corrected counts
      await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId)
          .set({
        'uid': userId, // Ensure UID is present
        'postsCount': postsCount,
        'articlesCount': articlesCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      dev.log(
        '✅ User stats synced for $userId. Posts: $postsCount, Articles: $articlesCount, Followers: $followersCount, Following: $followingCount',
      );
    } catch (e) {
      dev.log('❌ Error syncing user stats: $e');
    }
  }

  // Notification Preferences
  static Stream<NotificationPreferences> getNotificationPreferencesStream(
    String userId,
  ) {
    return _firestore
        .collection(FirebaseConfig.userProfiles)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return const NotificationPreferences();
          }

          final data = snapshot.data()!;
          final prefsData =
              data['notificationPreferences'] as Map<String, dynamic>?;

          if (prefsData == null) {
            return const NotificationPreferences();
          }

          return NotificationPreferences.fromMap(prefsData);
        });
  }

  static Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final userDoc = _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId);

      // Create the nested update map
      final Map<String, dynamic> nestedUpdates = {};
      updates.forEach((key, value) {
        nestedUpdates['notificationPreferences.$key'] = value;
      });

      await userDoc.update(nestedUpdates);
      dev.log('✅ Notification preferences updated for user: $userId');
    } catch (e) {
      dev.log('❌ Error updating notification preferences: $e');
      // If the field doesn't exist, create it
      try {
        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(userId)
            .set({'notificationPreferences': updates}, SetOptions(merge: true));
        dev.log('✅ Notification preferences created for user: $userId');
      } catch (e2) {
        dev.log('❌ Error creating notification preferences: $e2');
        rethrow;
      }
    }
  }
}

// Custom exception for Firestore permission errors
class FirestorePermissionException implements Exception {
  final String message;
  FirestorePermissionException(this.message);

  @override
  String toString() => 'FirestorePermissionException: $message';
}
