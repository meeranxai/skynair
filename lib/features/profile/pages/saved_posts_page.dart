import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/saved_posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/post_model.dart';
import '../widgets/saved_posts_grid.dart';
import '../../posts/pages/post_detail_page.dart';

class SavedPostsPage extends ConsumerStatefulWidget {
  const SavedPostsPage({super.key});

  @override
  ConsumerState<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends ConsumerState<SavedPostsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final savedPostsState = ref.watch(savedPostsProvider);

    if (authState.user == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('Saved Posts')),
        body: const Center(child: Text('Please log in to view saved posts')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (savedPostsState.savedPosts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(savedPostsProvider.notifier).refresh();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(savedPostsProvider.notifier).refresh();
        },
        child: savedPostsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : savedPostsState.error != null
            ? _buildErrorState(theme, savedPostsState.error!)
            : savedPostsState.savedPosts.isEmpty
            ? _buildEmptyState(theme)
            : _buildSavedPostsGrid(savedPostsState.savedPosts),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading saved posts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(savedPostsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved posts yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you save will appear here. Start exploring and save posts you want to see later!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to home/explore
                context.go('/');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Posts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostsGrid(List<PostModel> savedPosts) {
    return SavedPostsGrid(
      posts: savedPosts,
      onPostTap: (post) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailPage(postId: post.id),
          ),
        );
      },
    );
  }
}
