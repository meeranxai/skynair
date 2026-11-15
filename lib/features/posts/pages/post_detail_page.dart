import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/post_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../comments/pages/comments_page_enhanced.dart';
import '../../home/widgets/feed_card.dart';

import '../../../core/providers/auth_provider.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;
  final List<PostModel>? allPosts;
  final int? initialIndex;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.allPosts,
    this.initialIndex,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);

    if (widget.allPosts != null) {
      _posts = widget.allPosts!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If no posts provided, get single post
    if (widget.allPosts == null) {
      final postAsync = ref.watch(singlePostProvider(widget.postId));

      return postAsync.when(
        data: (post) {
          if (post == null) {
            return _buildErrorScaffold(theme, 'Post not found');
          }
          return _buildSinglePostView(post, theme);
        },
        loading: () => _buildLoadingScaffold(theme),
        error: (error, stack) => _buildErrorScaffold(theme, error.toString()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
        ),
        title: _posts.length > 1 ? Text('${_currentIndex + 1} of ${_posts.length}') : const Text('Post'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _posts.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Consumer(
              builder: (context, ref, child) {
                final postAsync = ref.watch(singlePostStreamProvider(post.id));
                final livePost = postAsync.when(
                  data: (data) => data ?? post,
                  loading: () => post,
                  error: (_, __) => post,
                );

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SkynaireFeedCard(
                      post: livePost,
                      currentUserId: ref.read(authProvider).user?.uid,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSinglePostView(PostModel post, ThemeData theme) {
    // Only use SkynaireFeedCard now
    Widget contentCard = SkynaireFeedCard(
      post: post,
      currentUserId: ref.read(authProvider).user?.uid,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
        ),
        actions: [
          // Share button removed as per user request
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: contentCard,
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(ThemeData theme) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildErrorScaffold(ThemeData theme, String error) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPageEnhanced(post: post, postId: post.id),
      ),
    );
  }

  void _sharePost(PostModel post) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${post.title}"'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Provider for single post

