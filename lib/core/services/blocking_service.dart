import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../config/firebase_config.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class BlockingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Block a user
  static Future<void> blockUser(
    String currentUserId,
    String blockedUserId,
  ) async {
    try {
      final batch = _firestore.batch();

      // 1. Create the block document (this will auto-create 'blocks' collection)
      final blockRef = _firestore
          .collection(FirebaseConfig.blocks)
          .doc('${currentUserId}_$blockedUserId');

      batch.set(blockRef, {
        'blockerId': currentUserId,
        'blockedId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Automatically unfollow if following
      // Follower to following
      final followRef1 = _firestore
          .collection(FirebaseConfig.follows)
          .doc('${currentUserId}_$blockedUserId');
      batch.delete(followRef1);

      // Following to follower
      final followRef2 = _firestore
          .collection(FirebaseConfig.follows)
          .doc('${blockedUserId}_$currentUserId');
      batch.delete(followRef2);

      // 3. Remove any pending follow requests (this will auto-create 'followRequests' collection if needed)
      final requestRef1 = _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${currentUserId}_$blockedUserId');
      batch.delete(requestRef1);
      final requestRef2 = _firestore
          .collection(FirebaseConfig.followRequests)
          .doc('${blockedUserId}_$currentUserId');
      batch.delete(requestRef2);

      await batch.commit();

      // Sync stats for both users (since follows might have been removed)
      await FirestoreService.syncUserStats(currentUserId);
      await FirestoreService.syncUserStats(blockedUserId);

      dev.log(
        '✅ User blocked and follows removed: $blockedUserId by $currentUserId',
      );
    } catch (e) {
      dev.log('❌ Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  static Future<void> unblockUser(
    String currentUserId,
    String blockedUserId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseConfig.blocks)
          .doc('${currentUserId}_$blockedUserId')
          .delete();

      dev.log('✅ User unblocked: $blockedUserId by $currentUserId');
    } catch (e) {
      dev.log('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  // Get stream of blocked user IDs for the current user
  static Stream<List<String>> getBlockedUserIdsStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.blocks)
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['blockedId'] as String)
              .toList(),
        );
  }

  // Get stream of blocked users (full profiles)
  static Stream<List<UserModel>> getBlockedUsersStream(String userId) {
    return _firestore
        .collection(FirebaseConfig.blocks)
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final blockedIds = snapshot.docs
              .map((doc) => doc.data()['blockedId'] as String)
              .toList();
          if (blockedIds.isEmpty) return [];

          final List<UserModel> blockedUsers = [];
          for (final id in blockedIds) {
            final user = await FirestoreService.getUserProfile(id);
            if (user != null) {
              blockedUsers.add(user);
            }
          }
          return blockedUsers;
        });
  }

  // Check if a user is blocked by current user
  static Future<bool> isUserBlocked(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.blocks)
          .doc('${currentUserId}_$targetUserId')
          .get();
      return doc.exists;
    } catch (e) {
      dev.log('❌ Error checking block status: $e');
      return false;
    }
  }

  // Get stream for real-time block status
  static Stream<bool> isUserBlockedStream(
    String currentUserId,
    String targetUserId,
  ) {
    try {
      return _firestore
          .collection(FirebaseConfig.blocks)
          .doc('${currentUserId}_$targetUserId')
          .snapshots()
          .timeout(
            const Duration(seconds: 12),
            onTimeout: (sink) {
              dev.log('⚠️ isUserBlockedStream timeout for $currentUserId -> $targetUserId');
              sink.addError('Block status check timeout');
              sink.close();
            },
          )
          .map((doc) => doc.exists)
          .handleError((error) {
            dev.log('❌ Block status stream error: $error');
            // Return false on error to not break UI
            return false;
          });
    } catch (e) {
      dev.log('❌ Error creating block status stream: $e');
      return Stream.value(false);
    }
  }

  // Get stream for real-time check of either user blocking the other
  static Stream<bool> isEitherBlockedStream(String userId1, String userId2) {
    try {
      // Use whereIn on document IDs to listen to both directions in one stream
      return _firestore
          .collection(FirebaseConfig.blocks)
          .where(FieldPath.documentId, whereIn: [
            '${userId1}_$userId2',
            '${userId2}_$userId1',
          ])
          .snapshots()
          .timeout(
            const Duration(seconds: 12),
            onTimeout: (sink) {
              dev.log('⚠️ isEitherBlockedStream timeout for $userId1 <-> $userId2');
              sink.addError('Timeout checking block status');
              sink.close();
            },
          )
          .map((snapshot) => snapshot.docs.isNotEmpty)
          .handleError((error) {
            dev.log('❌ Either block status stream error: $error');
            return false;
          });
    } catch (e) {
      dev.log('❌ Error creating either block status stream: $e');
      return Stream.value(false);
    }
  }
}
