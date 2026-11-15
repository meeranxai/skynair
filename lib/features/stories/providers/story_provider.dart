import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../../../core/providers/auth_provider.dart';

// Story state
class StoryState {
  final List<StoryModel> stories;
  final bool isLoading;
  final String? error;
  final bool isUploading;
  final double uploadProgress;

  const StoryState({
    this.stories = const [],
    this.isLoading = false,
    this.error,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  StoryState copyWith({
    List<StoryModel>? stories,
    bool? isLoading,
    String? error,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return StoryState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Story notifier
class StoryNotifier extends StateNotifier<StoryState> {
  final StoryService _storyService;
  final Ref ref;

  StoryNotifier(this._storyService, this.ref) : super(const StoryState()) {
    _loadStories();

    // Listen to stories stream for real-time updates
    ref.listen(storiesStreamProvider, (previous, next) {
      next.when(
        data: (stories) {
          state = state.copyWith(stories: stories, isLoading: false);
        },
        loading: () {
          // Keep current stories but show loading if empty
          if (state.stories.isEmpty) {
            state = state.copyWith(isLoading: true);
          }
        },
        error: (error, stack) {
          debugPrint('❌ StoryProvider Stream Error: $error');
          state = state.copyWith(isLoading: false, error: error.toString());
        },
      );
    }, fireImmediately: true);
  }

  Future<void> _loadStories() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stories = await _storyService.getStoriesForFeed(currentUser.uid);
      state = state.copyWith(stories: stories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createStory({
    required List<StoryItem> items,
    bool isHighlight = false,
    String? highlightTitle,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(isUploading: true, uploadProgress: 0.0);

    try {
      final story = await _storyService.createStory(
        userId: currentUser.uid,
        userName: _getUserDisplayName(currentUser),
        userAvatar: currentUser.photoURL,
        items: items,
        isHighlight: isHighlight,
        highlightTitle: highlightTitle,
      );

      // Add to current stories list immediately for better UX
      final currentStories = [...state.stories];
      final index = currentStories.indexWhere((s) => s.userId == currentUser.uid);
      
      List<StoryModel> updatedStories;
      if (index != -1) {
        // Merge with existing user story in state
        final existingStory = currentStories[index];
        final mergedItems = [...existingStory.items, ...story.items];
        // Remove duplicates by ID
        final Map<String, StoryItem> uniqueItems = {};
        for (final item in mergedItems) {
          uniqueItems[item.id] = item;
        }
        final finalItems = uniqueItems.values.toList();
        finalItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        updatedStories = List<StoryModel>.from(currentStories);
        updatedStories[index] = story.copyWith(items: finalItems);
      } else {
        updatedStories = [story, ...currentStories];
      }

      state = state.copyWith(
        stories: updatedStories,
        isUploading: false,
        uploadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<String> uploadStoryMedia({
    required XFile mediaFile,
    required StoryType type,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      return await _storyService.uploadStoryMedia(
        mediaFile: mediaFile,
        userId: currentUser.uid,
        type: type,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _storyService.markStoryAsViewed(storyId, currentUser.uid);

      // Update local state
      final updatedStories = state.stories.map((story) {
        if (story.id == storyId) {
          final updatedViewers = [...story.viewers];
          if (!updatedViewers.contains(currentUser.uid)) {
            updatedViewers.add(currentUser.uid);
          }
          return story.copyWith(
            viewers: updatedViewers,
            viewCount: updatedViewers.length,
          );
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> replyToStory({
    required String storyId,
    required String message,
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _storyService.replyToStory(
        storyId: storyId,
        fromUserId: currentUser.uid,
        fromUserName: _getUserDisplayName(currentUser),
        fromUserAvatar: currentUser.photoURL,
        message: message,
      );

      // Update local reply count
      final updatedStories = state.stories.map((story) {
        if (story.id == storyId) {
          return story.copyWith(replyCount: story.replyCount + 1);
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _storyService.deleteStory(storyId);

      // Remove from local state
      final updatedStories = state.stories
          .where((story) => story.id != storyId)
          .toList();

      state = state.copyWith(stories: updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addToHighlights({
    required String storyId,
    required String highlightTitle,
  }) async {
    try {
      await _storyService.addToHighlights(
        storyId: storyId,
        highlightTitle: highlightTitle,
      );

      // Update local state
      final updatedStories = state.stories.map((story) {
        if (story.id == storyId) {
          return story.copyWith(
            isHighlight: true,
            highlightTitle: highlightTitle,
          );
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeFromHighlights(String storyId) async {
    try {
      await _storyService.removeFromHighlights(storyId);

      // Update local state
      final updatedStories = state.stories.map((story) {
        if (story.id == storyId) {
          return story.copyWith(isHighlight: false, highlightTitle: null);
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleArchive(String storyId) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // Optimistic update: Remove from stories list since it's now archived
      final updatedStories = state.stories
          .where((story) => story.id != storyId)
          .toList();

      state = state.copyWith(stories: updatedStories);

      // Backend update
      await _storyService.toggleStoryArchive(storyId, currentUser.uid);
    } catch (e) {
      state = state.copyWith(error: 'Failed to archive story: $e');
      _loadStories();
    }
  }

  void refresh() {
    _loadStories();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> toggleLike(String storyId) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // Optimistic update
      final updatedStories = state.stories.map((story) {
        if (story.id == storyId) {
          final updatedLikes = [...story.likes];
          if (updatedLikes.contains(currentUser.uid)) {
            updatedLikes.remove(currentUser.uid);
          } else {
            updatedLikes.add(currentUser.uid);
          }
          return story.copyWith(
            likes: updatedLikes,
            likesCount: updatedLikes.length,
          );
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);

      // Backend update
      await _storyService.toggleStoryLike(storyId, currentUser.uid);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Rollback on error might be complex here since we rely on streams
      // but the next stream update will correct it anyway.
    }
  }

  String _getUserDisplayName(dynamic user) {
    return user.displayName ?? (user.email?.split('@').first) ?? 'Unknown';
  }
}

// Story providers
final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService();
});

final storyProvider = StateNotifierProvider<StoryNotifier, StoryState>((ref) {
  final storyService = ref.watch(storyServiceProvider);
  return StoryNotifier(storyService, ref);
});

// Stream provider for real-time stories
final storiesStreamProvider = StreamProvider<List<StoryModel>>((ref) {
  final currentUser = ref.watch(authProvider).user;
  if (currentUser == null) {
    return Stream.value(<StoryModel>[]);
  }

  final storyService = ref.watch(storyServiceProvider);
  return storyService.getStoriesStream(currentUser.uid);
});

// User stories provider
final userStoriesProvider = StreamProvider.family<List<StoryModel>, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider); // Use ref.watch for consistency
  return storyService.getUserStoriesStream(userId); // Assuming a stream method exists or needs to be created
});

final archivedStoriesProvider =
    StreamProvider.family<List<StoryModel>, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider); // Use ref.watch for consistency
  return storyService.getArchivedStoriesStream(userId);
});

// Story highlights provider
final storyHighlightsProvider = FutureProvider.family<List<StoryModel>, String>(
  (ref, userId) async {
    final storyService = ref.watch(storyServiceProvider);
    return storyService.getStoryHighlights(userId);
  },
);

// Story replies provider
final storyRepliesProvider = FutureProvider.family<List<StoryReply>, String>((
  ref,
  storyId,
) async {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getStoryReplies(storyId);
});

// Story analytics provider
final storyAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, storyId) async {
      final storyService = ref.watch(storyServiceProvider);
      return storyService.getStoryAnalytics(storyId);
    });

// Story search provider
final storySearchProvider = FutureProvider.family<List<StoryModel>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return <StoryModel>[];

  final storyService = ref.watch(storyServiceProvider);
  return storyService.searchStories(query: query);
});
