import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../config/firebase_config.dart';

class UserMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix missing follow count fields for existing users
  static Future<void> fixMissingFollowCounts(String userId) async {
    try {
      log('🔄 Checking and fixing follow counts for user: $userId');

      // Get user document
      final userDoc = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        log('⚠️ User document not found: $userId');
        return;
      }

      final userData = userDoc.data()!;
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // Check if followersCount is missing or null
      if (!userData.containsKey('followersCount') ||
          userData['followersCount'] == null) {
        log('📝 Adding missing followersCount field');
        updates['followersCount'] = 0;
        needsUpdate = true;
      }

      // Check if followingCount is missing or null
      if (!userData.containsKey('followingCount') ||
          userData['followingCount'] == null) {
        log('📝 Adding missing followingCount field');
        updates['followingCount'] = 0;
        needsUpdate = true;
      }

      // Check if postsCount is missing or null
      if (!userData.containsKey('postsCount') ||
          userData['postsCount'] == null) {
        log('📝 Adding missing postsCount field');
        updates['postsCount'] = 0;
        needsUpdate = true;
      }

      // If any fields are missing, update the document
      if (needsUpdate) {
        updates['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection(FirebaseConfig.userProfiles)
            .doc(userId)
            .update(updates);

        log('✅ Successfully fixed missing fields for user: $userId');
      } else {
        log('✅ User already has all required fields: $userId');
      }

      // Now calculate actual counts from follows collection
      await recalculateFollowCounts(userId);
    } catch (e) {
      log('❌ Error fixing follow counts: $e');
      rethrow;
    }
  }

  /// Recalculate follow counts from actual follow relationships
  static Future<void> recalculateFollowCounts(String userId) async {
    try {
      log('🔄 Recalculating follow counts for user: $userId');

      // Count followers (where followingId == userId)
      final followersSnapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followingId', isEqualTo: userId)
          .get();

      final followersCount = followersSnapshot.docs.length;
      log('📊 Actual followers count: $followersCount');

      // Count following (where followerId == userId)
      final followingSnapshot = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followerId', isEqualTo: userId)
          .get();

      final followingCount = followingSnapshot.docs.length;
      log('📊 Actual following count: $followingCount');

      // Update user profile with actual counts
      await _firestore
          .collection(FirebaseConfig.userProfiles)
          .doc(userId)
          .update({
            'followersCount': followersCount,
            'followingCount': followingCount,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      log(
        '✅ Successfully updated follow counts - Followers: $followersCount, Following: $followingCount',
      );
    } catch (e) {
      log('❌ Error recalculating follow counts: $e');
      rethrow;
    }
  }

  /// Fix all users in the database (admin function)
  static Future<void> fixAllUsers() async {
    try {
      log('🔄 Starting migration for all users...');

      final usersSnapshot = await _firestore
          .collection(FirebaseConfig.userProfiles)
          .get();

      log('📊 Found ${usersSnapshot.docs.length} users to check');

      int fixed = 0;
      int errors = 0;

      for (final doc in usersSnapshot.docs) {
        try {
          await fixMissingFollowCounts(doc.id);
          fixed++;
        } catch (e) {
          log('❌ Error fixing user ${doc.id}: $e');
          errors++;
        }
      }

      log(
        '✅ Migration complete - Fixed: $fixed, Errors: $errors, Total: ${usersSnapshot.docs.length}',
      );
    } catch (e) {
      log('❌ Error in migration: $e');
      rethrow;
    }
  }
}
