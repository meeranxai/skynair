import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/firebase_config.dart';
import '../models/story_model.dart';
import '../../../core/services/media_upload_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stories for home feed
  Future<List<StoryModel>> getStoriesForFeed(String currentUserId) async {
    try {
      // Get following list
      final followingQuery = await _firestore
          .collection(FirebaseConfig.follows)
          .where('followerId', isEqualTo: currentUserId)
          .get();

      final followingIds = followingQuery.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      // Add current user to see own stories
      followingIds.add(currentUserId);

      if (followingIds.isEmpty) return [];

      // Get active stories
      // We remove the expiresAt filter from the query to avoid index requirements
      // and filter in memory since the volume of active stories is manageable.
      final storiesQuery = await _firestore
          .collection(FirebaseConfig.stories)
          .get();

      final now = DateTime.now();
      final allStories = storiesQuery.docs
          .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((story) => 
              followingIds.contains(story.userId) && 
              story.expiresAt.isAfter(now) &&
              story.isArchived != true)
          .toList();

      // Group stories by user and return latest story per user
      return _groupStoriesByUser(allStories);
    } catch (e) {
      debugPrint('Error loading stories: $e');
      throw Exception('Failed to load stories: $e');
    }
  }

  List<StoryModel> _groupStoriesByUser(List<StoryModel> stories) {
    final Map<String, StoryModel> mergedStoriesByUser = {};
    
    for (final story in stories) {
      if (!mergedStoriesByUser.containsKey(story.userId)) {
        mergedStoriesByUser[story.userId] = story;
      } else {
        final existingStory = mergedStoriesByUser[story.userId]!;
        
        // Combine items and remove duplicates by ID
        final allItems = [...existingStory.items, ...story.items];
        final Map<String, StoryItem> uniqueItems = {};
        for (final item in allItems) {
          uniqueItems[item.id] = item;
        }
        
        final mergedItems = uniqueItems.values.toList();
        mergedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Use the most recent metadata but with all items
        if (story.createdAt.isAfter(existingStory.createdAt)) {
          mergedStoriesByUser[story.userId] = story.copyWith(items: mergedItems);
        } else {
          mergedStoriesByUser[story.userId] = existingStory.copyWith(items: mergedItems);
        }
      }
    }
    
    final result = mergedStoriesByUser.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  // Get all stories for a specific user
  Future<List<StoryModel>> getUserStories(String userId) async {
    try {
      final now = DateTime.now();
      final storiesQuery = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: false)
          .get();

      return storiesQuery.docs
          .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user stories: $e');
    }
  }

  // Create a new story
  Future<StoryModel> createStory({
    required String userId,
    required String userName,
    String? userAvatar,
    required List<StoryItem> items,
    bool isHighlight = false,
    String? highlightTitle,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final storyData = {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewers': <String>[],
        'viewCount': 0,
        'replyCount': 0,
        'likes': <String>[],
        'likesCount': 0,
        'isHighlight': isHighlight,
        'highlightTitle': highlightTitle,
        'isArchived': false,
      };

      final docRef = await _firestore.collection('stories').add(storyData);

      return StoryModel.fromJson({
        'id': docRef.id,
        ...storyData,
        'createdAt': now,
        'expiresAt': expiresAt,
      });
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  // Upload story media (image or video) to Supabase
  Future<String> uploadStoryMedia({
    required XFile mediaFile,
    required String userId,
    required StoryType type,
    Function(double)? onProgress,
  }) async {
    try {
      final mediaUploadService = MediaUploadService();

      MediaUploadResult result;
      if (type == StoryType.image) {
        result = await mediaUploadService.uploadXFile(
          mediaFile,
          folder: 'stories/$userId',
          tags: {
            'tags': ['story', 'temporary'],
          },
        );
      } else {
        result = await mediaUploadService.uploadVideoXFile(
          mediaFile,
          folder: 'stories/$userId',
          tags: {
            'tags': ['story', 'temporary', 'video'],
          },
        );
      }

      // Simulate progress for UI feedback
      if (onProgress != null) {
        onProgress(1.0);
      }

      return result.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload story media to Supabase: $e');
    }
  }

  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storyDoc = await transaction.get(storyRef);

        if (!storyDoc.exists) return;

        final data = storyDoc.data()!;
        final viewers = List<String>.from(data['viewers'] ?? []);

        if (!viewers.contains(viewerId)) {
          viewers.add(viewerId);
          transaction.update(storyRef, {
            'viewers': viewers,
            'viewCount': viewers.length,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to mark story as viewed: $e');
    }
  }

  // Toggle story like
  Future<void> toggleStoryLike(String storyId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storyDoc = await transaction.get(storyRef);

        if (!storyDoc.exists) return;

        final data = storyDoc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        transaction.update(storyRef, {
          'likes': likes,
          'likesCount': likes.length,
        });
      });
    } catch (e) {
      throw Exception('Failed to toggle story like: $e');
    }
  }

  // Add reply to story
  Future<void> replyToStory({
    required String storyId,
    required String fromUserId,
    required String fromUserName,
    String? fromUserAvatar,
    required String message,
  }) async {
    try {
      final now = DateTime.now();

      // Add reply to replies collection
      await _firestore.collection('story_replies').add({
        'storyId': storyId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserAvatar': fromUserAvatar,
        'message': message,
        'createdAt': Timestamp.fromDate(now),
        'isRead': false,
      });

      // Update story reply count
      await _firestore.collection('stories').doc(storyId).update({
        'replyCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to reply to story: $e');
    }
  }

  // Get story replies
  Future<List<StoryReply>> getStoryReplies(String storyId) async {
    try {
      final repliesQuery = await _firestore
          .collection('story_replies')
          .where('storyId', isEqualTo: storyId)
          .orderBy('createdAt', descending: true)
          .get();

      return repliesQuery.docs
          .map((doc) => StoryReply.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load story replies: $e');
    }
  }

  // Delete story
  Future<void> deleteStory(String storyId) async {
    try {
      // Get story first to delete media
      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      if (storyDoc.exists) {
        final data = storyDoc.data()!;
        final items = List<dynamic>.from(data['items'] ?? []);
        final mediaService = MediaUploadService();

        for (final item in items) {
          final mediaUrl = item['mediaUrl'] as String?;
          if (mediaUrl != null) {
            final type = item['type'] == 'video' ? MediaType.video : MediaType.image;
            await mediaService.deleteMedia(mediaUrl, type: type);
          }
        }
      }

      // Delete story document
      await _firestore.collection('stories').doc(storyId).delete();

      // Delete associated replies
      final repliesQuery = await _firestore
          .collection('story_replies')
          .where('storyId', isEqualTo: storyId)
          .get();

      final batch = _firestore.batch();
      for (final reply in repliesQuery.docs) {
        batch.delete(reply.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  // Get story highlights for a user
  Future<List<StoryModel>> getStoryHighlights(String userId) async {
    try {
      final highlightsQuery = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('isHighlight', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return highlightsQuery.docs
          .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load story highlights: $e');
    }
  }

  // Add story to highlights
  Future<void> addToHighlights({
    required String storyId,
    required String highlightTitle,
  }) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isHighlight': true,
        'highlightTitle': highlightTitle,
      });
    } catch (e) {
      throw Exception('Failed to add story to highlights: $e');
    }
  }

  // Remove story from highlights
  Future<void> removeFromHighlights(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isHighlight': false,
        'highlightTitle': null,
      });
    } catch (e) {
      throw Exception('Failed to remove story from highlights: $e');
    }
  }

  // Get story analytics
  Future<Map<String, dynamic>> getStoryAnalytics(String storyId) async {
    try {
      final storyDoc = await _firestore
          .collection('stories')
          .doc(storyId)
          .get();

      if (!storyDoc.exists) {
        throw Exception('Story not found');
      }

      final data = storyDoc.data()!;
      final viewers = List<String>.from(data['viewers'] ?? []);

      // Get viewer details
      final viewerDetails = <Map<String, dynamic>>[];
      for (final viewerId in viewers.take(50)) {
        // Limit to 50 for performance
        final userDoc = await _firestore
            .collection('users')
            .doc(viewerId)
            .get();
        if (userDoc.exists) {
          viewerDetails.add({
            'userId': viewerId,
            'userName': userDoc.data()?['displayName'] ?? 'Unknown',
            'userAvatar': userDoc.data()?['photoURL'],
          });
        }
      }

      return {
        'viewCount': data['viewCount'] ?? 0,
        'replyCount': data['replyCount'] ?? 0,
        'viewers': viewerDetails,
        'createdAt': data['createdAt'],
        'expiresAt': data['expiresAt'],
      };
    } catch (e) {
      throw Exception('Failed to get story analytics: $e');
    }
  }

  // Clean up expired stories (should be called periodically)
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now();
      final expiredQuery = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('isHighlight', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup expired stories: $e');
    }
  }

  // Search stories by hashtags or mentions
  Future<List<StoryModel>> searchStories({
    required String query,
    int limit = 20,
  }) async {
    try {
      final now = DateTime.now();

      // This is a simplified search - in production, you'd use a proper search service
      final storiesQuery = await _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final stories = storiesQuery.docs
          .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((story) {
            // Filter by query in story items
            return story.items.any(
              (item) =>
                  item.text?.toLowerCase().contains(query.toLowerCase()) ==
                      true ||
                  item.mentions.any(
                    (mention) =>
                        mention.toLowerCase().contains(query.toLowerCase()),
                  ),
            );
          })
          .take(limit)
          .toList();

      return stories;
    } catch (e) {
      throw Exception('Failed to search stories: $e');
    }
  }

  // Get stories for a specific user
  Stream<List<StoryModel>> getUserStoriesStream(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  // Get stories stream for real-time updates
  Stream<List<StoryModel>> getStoriesStream(String currentUserId) {
    final now = DateTime.now();
    // Listen to active stories collection for real-time updates
    return _firestore
        .collection(FirebaseConfig.stories)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .snapshots()
        .asyncMap((storiesSnapshot) async {
          // Get following list to filter
          final followsSnapshot = await _firestore
              .collection(FirebaseConfig.follows)
              .where('followerId', isEqualTo: currentUserId)
              .get();

          final followingIds = followsSnapshot.docs
              .map((doc) => doc.data()['followingId'] as String)
              .toList();

          followingIds.add(currentUserId);

          final now = DateTime.now();
          final stories = storiesSnapshot.docs
              .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
              .where((story) => 
                  followingIds.contains(story.userId) && 
                  story.expiresAt.isAfter(now) &&
                  story.isArchived != true)
              .toList();

          return _groupStoriesByUser(stories);
        });
  }
  // Toggle story archive status (owner only)
  Future<void> toggleStoryArchive(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);
      final storyDoc = await storyRef.get();

      if (!storyDoc.exists) {
        throw 'Story not found';
      }

      final data = storyDoc.data()!;
      if (data['userId'] != userId) {
        throw 'Unauthorized: Only story owner can archive';
      }

      final currentStatus = data['isArchived'] ?? false;
      await storyRef.update({
        'isArchived': !currentStatus,
      });
    } catch (e) {
      throw Exception('Failed to toggle story archive: $e');
    }
  }

  // Get archived stories for a user
  Stream<List<StoryModel>> getArchivedStoriesStream(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }
}
