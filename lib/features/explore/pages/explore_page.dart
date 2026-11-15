import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/blocking_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/smart_search_service.dart';
import '../../profile/pages/profile_page.dart';
import '../widgets/explore_post_card.dart';
import '../../../core/widgets/keep_alive_wrapper.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          // Messages disabled in Phase 1
          // IconButton(
          //   icon: const Icon(Icons.message_outlined),
          //   onPressed: () => Navigator.pushNamed(context, '/messages'),
          // ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search posts, people, or categories...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'People'),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          KeepAliveWrapper(child: _buildPostsSearch()),
          KeepAliveWrapper(child: _buildPeopleSearch()),
        ],
      ),
    );
  }

  Widget _buildPostsSearch() {
    final postsState = ref.watch(postsProvider);
    final blockedIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
    
    // Filter and exclude blocked users
    final allContent = postsState.posts;
    final isLoading = postsState.isLoading;

    if (isLoading && allContent.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postsState.error != null && allContent.isEmpty) {
      return _buildErrorState(postsState.error!);
    }

    // Filter and exclude blocked users
    final filteredContent = allContent
        .where((post) => !blockedIds.contains(post.authorId) && post.postType == 'media' && post.isArchived != true)
        .toList();

    // Sort by date (descending)
    filteredContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply search filtering
    final searchResults = _searchQuery.isEmpty
        ? filteredContent
        : SmartSearchService.searchPosts(_searchQuery, filteredContent);

    if (searchResults.isEmpty) {
      return _buildEmptyState(
        icon: _searchQuery.isEmpty
            ? Icons.photo_library_outlined
            : Icons.search_off,
        message: _searchQuery.isEmpty
            ? 'No content yet'
            : 'No results found for "$_searchQuery"',
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final post = searchResults[index];
        return ExplorePostCard(key: ValueKey(post.id), post: post);
      },
    );
  }

  Widget _buildPeopleSearch() {
    if (_searchQuery.trim().isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: 'Search for people by name or username',
      );
    }

    final usersState = ref.watch(userSearchProvider(_searchQuery));
    final blockedIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];

    return usersState.when(
      data: (users) {
        // Filter out blocked users
        final filteredUsers = users
            .where((user) => !blockedIds.contains(user.uid))
            .toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search,
            message: 'No people found for "$_searchQuery"',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filteredUsers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.displayName ?? user.username),
              subtitle: Text('@${user.username}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(uid: user.uid),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorState(err),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_searchQuery.isNotEmpty && icon == Icons.search_off) ...[
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            err.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Simple Grid View since staggered might not be imported correctly
class MasonryGridView extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const MasonryGridView.count({
    super.key,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: 0.8, // Better aspect ratio for explore cards
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
