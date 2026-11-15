import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/posts_provider.dart';
import '../../stories/providers/story_provider.dart';
import '../../posts/pages/post_detail_page.dart';
import '../../../core/models/post_model.dart';
import '../../stories/models/story_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Stories'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view archive'))
          : TabBarView(
              controller: _tabController,
              children: [
                _ArchivedPostsTab(userId: user.uid),
                _ArchivedStoriesTab(userId: user.uid),
              ],
            ),
    );
  }
}

class _ArchivedPostsTab extends ConsumerWidget {
  final String userId;
  const _ArchivedPostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedPosts = ref.watch(archivedPostsProvider(userId));

    return archivedPosts.when(
      data: (posts) => posts.isEmpty
          ? _buildEmptyState('No archived posts')
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _ArchiveGridItem(
                  imageUrl: post.imageUrls?.first ?? post.image,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(
                        postId: post.id,
                        allPosts: posts,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  onLongPress: () => _showUnarchiveDialog(context, ref, post.id, false),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}



class _ArchivedStoriesTab extends ConsumerWidget {
  final String userId;
  const _ArchivedStoriesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedStories = ref.watch(archivedStoriesProvider(userId));

    return archivedStories.when(
      data: (stories) => stories.isEmpty
          ? _buildEmptyState('No archived stories')
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 9 / 16,
              ),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return _ArchiveGridItem(
                  imageUrl: story.items.first.mediaUrl,
                  onTap: () => _showUnarchiveDialog(context, ref, story.id, true),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ArchiveGridItem extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ArchiveGridItem({this.imageUrl, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
              )
            : const Icon(Icons.image_outlined),
      ),
    );
  }
}

Widget _buildEmptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.archive_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      ],
    ),
  );
}

void _showUnarchiveDialog(BuildContext context, WidgetRef ref, String id, bool isStory) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unarchive Item?'),
      content: const Text('This will move the item back to your profile.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            if (isStory) {
              ref.read(storyProvider.notifier).toggleArchive(id);
            } else {
              ref.read(postsProvider.notifier).archivePost(id); // archivedPost toggles
            }
          },
          child: const Text('Unarchive'),
        ),
      ],
    ),
  );
}
