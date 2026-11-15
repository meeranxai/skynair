import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'dart:async';

import '../config/firebase_config.dart';
import 'firestore_service.dart';

class FollowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Follow a user
  static Future<void> followUser(String followerId, String followingId) async {
    if (followerId == followingId) {
      throw 'Cannot follow yourself';
    }

    log('🔄 Starting follow: $followerId -> $followingId');

    try {
      await _firestore.runTransaction((transaction) async {
        final followRef = _firestore
            .collection(FirebaseConfig.follows)
            .doc('${followerId}_$followingId');

        final followerRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followerId);

        final followingRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followingId);

        // Check if already following to avoid double counting
        final followDoc = await transaction.get(followRef);
        if (followDoc.exists) {
          log('⚠️ Already following');
          return;
        }

        // Create follow relationship
        transaction.set(followRef, {
          'followerId': followerId,
          'followingId': followingId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Safe update for follower (create if missing)
        transaction.set(
          followerRef,
          {
            'followingCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Safe update for following user (create if missing)
        transaction.set(
          followingRef,
          {
            'followersCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      
      // Sync stats for both users with a slight delay to allow Firestore indexing to catch up
      Future.delayed(const Duration(seconds: 3), () {
        FirestoreService.syncUserStats(followerId);
        FirestoreService.syncUserStats(followingId);
      });

      log('✅ User followed successfully: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error following user: $e');
      if (e.toString().contains('permission-denied')) {
        throw 'Permission denied: Please check your connection.';
      }
      rethrow;
    }
  }

  // Unfollow a user safely using transaction to prevent negative counts
  static Future<void> unfollowUser(
    String followerId,
    String followingId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final followRef = _firestore
            .collection(FirebaseConfig.follows)
            .doc('${followerId}_$followingId');

        final followerRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followerId);

        final followingRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followingId);

        final followDoc = await transaction.get(followRef);
        if (!followDoc.exists) {
          log('⚠️ Follow relationship already removed');
          return;
        }

        // Delete the relationship
        transaction.delete(followRef);

        // Safe decrement for follower
        // using FieldValue.increment(-1) is simpler and atomic
        // but we want to avoid negative numbers if possible.
        // However, standard practice with set/merge is tricky for decrement without reading first.
        // Since we are inside a transaction, we can read.
        
        final followerDoc = await transaction.get(followerRef);
        if (followerDoc.exists) {
           final currentFollowing = (followerDoc.data()?['followingCount'] as int?) ?? 0;
           if (currentFollowing > 0) {
             transaction.set(followerRef, {
               'followingCount': FieldValue.increment(-1),
               'updatedAt': FieldValue.serverTimestamp(),
             }, SetOptions(merge: true));
           }
        }

        final followingDoc = await transaction.get(followingRef);
         if (followingDoc.exists) {
           final currentFollowers = (followingDoc.data()?['followersCount'] as int?) ?? 0;
           if (currentFollowers > 0) {
             transaction.set(followingRef, {
               'followersCount': FieldValue.increment(-1),
               'updatedAt': FieldValue.serverTimestamp(),
             }, SetOptions(merge: true));
           }
        }
      });

      // Sync stats for both users with a slight delay to allow Firestore indexing to catch up
      Future.delayed(const Duration(seconds: 3), () {
        FirestoreService.syncUserStats(followerId);
        FirestoreService.syncUserStats(followingId);
      });

      log('✅ User unfollowed successfully: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error unfollowing user: $e');
      if (e.toString().contains('permission-denied')) {
        throw 'Permission denied: Please check if you are logged in.';
      }
      rethrow;
    }
  }

  // Check if user is following another user
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
      return false; // Safe default: assume not following
    }
  }

  // Check if user has requested to follow another user
  static Future<bool> isFollowRequested(String followerId, String followingId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('⚠️ isFollowRequested timeout for $followerId -> $followingId');
              throw TimeoutException('Follow request check timed out');
            },
          );

      return doc.exists;
    } catch (e) {
      log('❌ Error checking follow request status: $e');
      return false; // Safe default: assume no request
    }
  }

  // Get followers list
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

  // Get following list
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

  // Get followers stream for real-time updates
  static Stream<List<String>> getFollowersStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.follows)
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['followerId'] as String)
              .toList(),
        );
  }

  // Get following stream for real-time updates
  static Stream<List<String>> getFollowingStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.follows)
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['followingId'] as String)
              .toList(),
        );
  }

  // Get follow status stream for real-time updates
  static Stream<bool> getFollowStatusStream(
    String followerId,
    String followingId,
  ) {
    try {
      return _firestore
          .collection(FirebaseConfig.follows)
          .doc('${followerId}_$followingId')
          .snapshots()
          .map((doc) => doc.exists)
          .handleError((error) {
            log('❌ Follow status stream error: $error');
            // Return false on error to not break UI
            return false;
          });
    } catch (e) {
      log('❌ Error creating follow status stream: $e');
      return Stream.value(false);
    }
  }

  // Follow Request Methods for Private Accounts

  static Future<bool> isUserPrivate(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('⚠️ isUserPrivate timeout for $userId');
              throw TimeoutException('User privacy check timed out');
            },
          );
      return doc.data()?['isPrivate'] as bool? ?? false;
    } catch (e) {
      log('❌ Error checking if user is private: $e');
      return false; // Safe default: assume public
    }
  }

  static Future<void> sendFollowRequest(
    String followerId,
    String followingId,
  ) async {
    if (followerId == followingId) throw 'Cannot follow yourself';

    try {
      // This will auto-create 'followRequests' collection if it doesn't exist
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

  static Future<void> acceptFollowRequest(
    String followerId,
    String followingId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Verify the request still exists
        final requestRef = _firestore
            .collection(FirebaseConfig.followRequests)
            .doc('${followerId}_$followingId');
        
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) {
           log('⚠️ Request does not exist, possible double-click');
           return; // Already handled
        }

        // 2. Create follow relationship
        final followRef = _firestore
            .collection(FirebaseConfig.follows)
            .doc('${followerId}_$followingId');
            
        transaction.set(followRef, {
          'followerId': followerId,
          'followingId': followingId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Delete the request
        transaction.delete(requestRef);

        // 4. Update stats (optimistic updates within transaction are safer)
        final followerProfileRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followerId);
            
        final followingProfileRef = _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(followingId);

        // Increment counts ensuring we don't need to read them first for increment
        // FieldValue.increment works safely inside transactions too
        transaction.set(followerProfileRef, {
          'followingCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(followingProfileRef, {
          'followersCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      
      // Sync stats for both users with a slight delay to allow Firestore indexing to catch up
      Future.delayed(const Duration(seconds: 3), () {
        FirestoreService.syncUserStats(followerId);
        FirestoreService.syncUserStats(followingId);
      });
      
      log('✅ Follow request accepted: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error accepting follow request: $e');
      if (e.toString().contains('permission-denied')) {
        throw 'Permission denied. Please check your connection.';
      }
      rethrow;
    }
  }

  static Future<void> declineFollowRequest(
    String followerId,
    String followingId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .delete();
      log('✅ Follow request declined: $followerId -> $followingId');
    } catch (e) {
      log('❌ Error declining follow request: $e');
      rethrow;
    }
  }

  static Stream<bool> getFollowRequestStatusStream(
    String followerId,
    String followingId,
  ) {
    try {
      return _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${followerId}_$followingId')
          .snapshots()
          .map((doc) => doc.exists)
          .handleError((error) {
            log('❌ Follow request status stream error: $error');
            return false;
          });
    } catch (e) {
      log('❌ Error creating follow request status stream: $e');
      return Stream.value(false);
    }
  }

  static Stream<List<Map<String, dynamic>>> getIncomingFollowRequestsStream(
    String userId,
  ) {
    return _firestore
        .collection(FirebaseConfig.followRequests)
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
