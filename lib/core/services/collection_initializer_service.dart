import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../config/firebase_config.dart';

class CollectionInitializerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize required collections by checking if they exist
  /// If not, create a temporary document to establish the collection
  static Future<void> initializeCollections() async {
    try {
      dev.log('🔄 Initializing Firestore collections...');

      // Check and initialize blocks collection
      await _initializeCollection(FirebaseConfig.blocks, 'temp_block_init', {
        'blockerId': 'temp_user',
        'blockedId': 'temp_user_2',
        'createdAt': FieldValue.serverTimestamp(),
        'isTemp': true,
      });

      // Check and initialize followRequests collection
      await _initializeCollection(
        FirebaseConfig.followRequests,
        'temp_request_init',
        {
          'followerId': 'temp_user',
          'followingId': 'temp_user_2',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'isTemp': true,
        },
      );

      dev.log('✅ Collections initialized successfully');
    } catch (e) {
      dev.log('❌ Error initializing collections: $e');
      // Don't throw error - app should continue even if initialization fails
    }
  }

  /// Initialize a specific collection if it doesn't exist
  static Future<void> _initializeCollection(
    String collectionName,
    String tempDocId,
    Map<String, dynamic> tempData,
  ) async {
    try {
      // Check if collection exists by trying to get a document
      final snapshot = await _firestore
          .collection(collectionName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Collection doesn't exist or is empty, create temp document
        dev.log('📝 Creating collection: $collectionName');
        await _firestore
            .collection(collectionName)
            .doc(tempDocId)
            .set(tempData);

        // Optionally delete the temp document after a delay
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            await _firestore.collection(collectionName).doc(tempDocId).delete();
            dev.log('🗑️ Cleaned up temp document in $collectionName');
          } catch (e) {
            dev.log('⚠️ Could not clean up temp document: $e');
          }
        });
      } else {
        dev.log('✅ Collection $collectionName already exists');
      }
    } catch (e) {
      dev.log('❌ Error checking collection $collectionName: $e');
      // Continue without throwing - collection will be created when first real document is added
    }
  }

  /// Clean up any temporary initialization documents
  static Future<void> cleanupTempDocuments() async {
    try {
      final collections = [
        FirebaseConfig.blocks,
        FirebaseConfig.followRequests,
      ];

      for (final collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('isTemp', isEqualTo: true)
            .get();

        for (final doc in snapshot.docs) {
          await doc.reference.delete();
          dev.log('🗑️ Cleaned up temp document: ${doc.id}');
        }
      }
    } catch (e) {
      dev.log('❌ Error cleaning up temp documents: $e');
    }
  }
}
