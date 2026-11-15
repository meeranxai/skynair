import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/comments_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'posts_provider.dart';

// Comments state
class CommentsState {
  final List<CommentModel> comments;
  final bool isLoading;
  final String? error;

  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentsState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Comments notifier
class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommentsService _commentsService;
  final String postId;
  final Ref ref;

  CommentsNotifier(this._commentsService, this.postId, this.ref)
    : super(const CommentsState()) {
    _loadComments();
  }

  Future<void> _loadComments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final comments = await _commentsService.getComments(postId);
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addComment(String postId, String content) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      final comment = await _commentsService.addComment(
        postId: postId,
        content: content,
        authorId: currentUser.uid,
        author: _getUserDisplayName(currentUser),
        authorUsername: _getUserUsername(currentUser),
        authorAvatar: currentUser.photoURL,
      );

      state = state.copyWith(comments: [...state.comments, comment]);

      // Create comment notification (get post author from posts provider)
      // Create comment notification
      try {
        final postsState = ref.read(postsProvider);
        PostModel? post;
        
        try {
          post = postsState.posts.firstWhere((p) => p.id == postId);
        } catch (_) {
          // Post not in current feed state, try fetching
          post = await ref.read(singlePostProvider(postId).future);
        }

        if (post != null && currentUser.uid != post.authorId) {
          ref.read(notificationProvider.notifier).createCommentNotification(
                postId: postId,
                postAuthorId: post.authorId,
                commentText: content,
                isArticle: post.postType == 'article',
              );
        }
      } catch (e) {
        // Log but don't fail comment creation if notification fails
        print('Failed to create comment notification: $e');
      }

      // Handle mentions
      final mentionRegex = RegExp(r'@(\w+)');
      final matches = mentionRegex.allMatches(content);
      
      for (final match in matches) {
        final username = match.group(1);
        if (username != null) {
          try {
            final mentionedUser = await FirestoreService.getUserByUsername(username);
            if (mentionedUser != null && mentionedUser.uid != currentUser.uid) {
              ref.read(notificationProvider.notifier).createMentionNotification(
                    postId: postId,
                    toUserId: mentionedUser.uid,
                    isComment: true,
                  );
            }
          } catch (e) {
            print('Failed to create mention notification for $username: $e');
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateComment(
    String postId,
    String commentId,
    String newContent,
  ) async {
    try {
      await _commentsService.updateComment(commentId, newContent);

      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return comment.copyWith(
            content: newContent,
            updatedAt: DateTime.now(),
            isEdited: true,
          );
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _commentsService.deleteComment(commentId);

      final updatedComments = state.comments
          .where((comment) => comment.id != commentId)
          .toList();

      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // Optimistic update
      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          final isLiked = comment.isLikedBy(currentUser.uid);
          final newLikes = isLiked
              ? comment.likes.where((id) => id != currentUser.uid).toList()
              : [...comment.likes, currentUser.uid];

          return comment.copyWith(likes: newLikes);
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);

      // Update in Firestore
      await _commentsService.toggleCommentLike(commentId, currentUser.uid);
    } catch (e) {
      // Revert on error
      _loadComments();
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addReply(String parentCommentId, String content) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      final reply = await _commentsService.addComment(
        postId: postId,
        content: content,
        authorId: currentUser.uid,
        author: _getUserDisplayName(currentUser),
        authorUsername: _getUserUsername(currentUser),
        authorAvatar: currentUser.photoURL,
        parentCommentId: parentCommentId,
      );

      state = state.copyWith(comments: [...state.comments, reply]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void refresh() {
    _loadComments();
  }

  String _getUserDisplayName(UserModel user) {
    return user.displayName.isNotEmpty ? user.displayName : (user.email.split('@').first);
  }

  String _getUserUsername(UserModel user) {
    return user.username.isNotEmpty ? user.username : (user.email.split('@').first);
  }
}

// Comments provider
final commentsProvider =
    StateNotifierProvider.family<CommentsNotifier, CommentsState, String>((
      ref,
      postId,
    ) {
      final commentsService = ref.watch(commentsServiceProvider);
      return CommentsNotifier(commentsService, postId, ref);
    });

// Stream provider for real-time comments
final commentsStreamProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
      final commentsService = ref.watch(commentsServiceProvider);
      return commentsService.getCommentsStream(postId);
    });

// Comments service provider
final commentsServiceProvider = Provider<CommentsService>((ref) {
  return CommentsService();
});
