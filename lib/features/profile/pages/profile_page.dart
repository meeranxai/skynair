import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/services/realtime_messaging_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/blocking_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_content_tabs.dart';
import '../widgets/enhanced_edit_profile_dialog.dart';
import 'follow_requests_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? uid;
  final String? username;

  const ProfilePage({super.key, this.uid, this.username});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).user?.uid;

    // Resolve target UID
    final AsyncValue<String?> targetUidAsync;
    if (widget.uid != null) {
      targetUidAsync = AsyncValue.data(widget.uid);
    } else if (widget.username != null) {
      final userByUsername = ref.watch(
        userByUsernameProvider(widget.username!),
      );
      targetUidAsync = userByUsername.when(
        data: (user) => AsyncValue.data(user?.uid),
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    } else {
      targetUidAsync = AsyncValue.data(currentUserId);
    }

    return targetUidAsync.when(
      data: (targetUid) {
        if (targetUid == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('User not found')),
          );
        }

        final userProfileAsync = ref.watch(userProfileByIdProvider(targetUid));

        return userProfileAsync.when(
          data: (user) {
            if (user == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Profile')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'User profile not found',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This user may not exist or may have been deleted.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(userProfileByIdProvider(targetUid)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Auto-sync stats if count is 0 to fix migration/indexing issues
            if (user.postsCount == 0) {
              Future.microtask(() {
                FirestoreService.syncUserStats(targetUid);
              });
            }

            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: RefreshIndicator(
                edgeOffset: MediaQuery.of(context).padding.top,
                displacement: 40.0,
                onRefresh: () async {
                  // Sync stats to ensure accurate post/follower counts
                  await FirestoreService.syncUserStats(targetUid);

                  ref.invalidate(userProfileByIdProvider(targetUid));
                  ref.invalidate(userFollowersCountProvider(targetUid));
                  ref.invalidate(userFollowingCountProvider(targetUid));
                  ref.invalidate(userPostsCountProvider(targetUid));

                  final currentTabIndex = _tabController.index;
                  switch (currentTabIndex) {
                    case 0:
                    case 1:
                      ref.invalidate(userPostsProvider(targetUid));
                      break;
                    case 3: // For Saved/Tagged tab, if it has its own provider
                      // ref.invalidate(userSavedPostsProvider(targetUid)); // Example
                      break;
                  }

                  if (targetUid == currentUserId) {
                    await ref
                        .read(userProfileProvider.notifier)
                        .refreshProfile();
                  }
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: NestedScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        title: const Text('Profile'),
                        pinned: true,
                        floating: true,
                        snap: true,
                        actions: [
                          if (user.isPrivate)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          if (targetUid == currentUserId) ...[
                            // Follow Requests Badge
                            ref
                                .watch(incomingFollowRequestsProvider)
                                .maybeWhen(
                                  data: (requests) {
                                    if (requests.isEmpty)
                                      return const SizedBox.shrink();
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.person_add_outlined),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FollowRequestsPage(),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              '${requests.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                ),
                            IconButton(
                              icon: const Icon(Icons.archive_outlined),
                              onPressed: () => context.push('/archive'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => context.push('/settings'),
                            ),
                          ] else ...[
                            // More options for other users
                            Consumer(
                              builder: (context, ref, child) {
                                final isBlockedAsync = ref.watch(
                                  isUserBlockedProvider(targetUid),
                                );
                                final isBlocked = isBlockedAsync.valueOrNull ?? false;

                                return PopupMenuButton<String>(
                                  onSelected: (value) => _handleProfileMenuAction(
                                    context,
                                    ref,
                                    user,
                                    value,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          Icon(Icons.report_outlined, size: 20),
                                          SizedBox(width: 12),
                                          Text('Report User'),
                                        ],
                                      ),
                                    ),
                                    // Block/Unblock option based on current status
                                    PopupMenuItem(
                                      value: isBlocked ? 'unblock' : 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block_rounded,
                                            size: 20,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isBlocked ? 'Unblock User' : 'Block User',
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: ProfileHeader(
                          user: user,
                          isOwnProfile: targetUid == currentUserId,
                          onEditProfile: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  EnhancedEditProfileDialog(user: user),
                            );
                          },
                          onMessage: () async {
                            final authUser = ref.read(authProvider).user;
                            if (authUser == null) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Starting conversation...'),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            try {
                              final chatId =
                                  await RealtimeMessagingService.getOrCreateConversation(
                                    authUser.uid,
                                    user.uid,
                                  );

                              if (mounted) {
                                context.push(
                                  Uri(
                                    path: '/chat/$chatId',
                                    queryParameters: {
                                      'otherUserId': user.uid,
                                      'otherUserName':
                                          user.displayName.isNotEmpty
                                          ? user.displayName
                                          : user.username,
                                      'otherUserAvatar': user.photoURL ?? '',
                                    },
                                  ).toString(),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to start chat: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          onSettings: () {
                            context.push('/settings');
                          },
                        ),
                      ),
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                        sliver: SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverAppBarDelegate(
                            TabBar(
                              controller: _tabController,
                              tabs: [
                                const Tab(text: 'Posts'),
                                const Tab(text: 'Media'),
                                // const Tab(text: 'Articles'), // Disabled for Phase 2 unification
                                Tab(
                                  text: targetUid == currentUserId
                                      ? 'Saved'
                                      : 'Tagged',
                                ),
                              ],
                              labelColor: theme.colorScheme.primary,
                              unselectedLabelColor:
                                  theme.colorScheme.onSurfaceVariant,
                              indicatorColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Builder(
                    builder: (context) {
                      final isOwnProfile = targetUid == currentUserId;
                      final isFollowingAsync = ref.watch(
                        isFollowingProvider(targetUid),
                      );
                      final isBlockedByMeAsync = ref.watch(
                        isUserBlockedProvider(targetUid),
                      );
                      final isBlockedByThemAsync = ref.watch(
                        isEitherBlockedProvider(targetUid),
                      );

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverOverlapInjector(
                            handle:
                                NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context,
                                ),
                          ),
                          SliverFillRemaining(
                            child: isBlockedByMeAsync.when(
                              data: (isBlockedByMe) {
                                if (isBlockedByMe) {
                                  return _buildBlockedByMeState(theme, user);
                                }

                                return isBlockedByThemAsync.when(
                                  data: (isEitherBlocked) {
                                    // If either is blocked but not by me, it's by them
                                    if (isEitherBlocked) {
                                      return _buildBlockedByThemState(theme);
                                    }

                                    return isFollowingAsync.when(
                                      data: (isFollowing) {
                                        final canSeeContent =
                                            isOwnProfile ||
                                            !user.isPrivate ||
                                            isFollowing;

                                        if (!canSeeContent) {
                                          return _buildPrivateAccountState(
                                            theme,
                                          );
                                        }

                                        return ProfileContentTabs(
                                          tabController: _tabController,
                                          user: user,
                                          isOwnProfile: isOwnProfile,
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (error, stack) =>
                                          Center(child: Text('Error: $error')),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (error, stack) =>
                                      Center(child: Text('Error: $error')),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) =>
                                  Center(child: Text('Error: $error')),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(userProfileByIdProvider(targetUid)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading user...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPrivateAccountState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This Account is Private',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Follow this account to see their posts and updates.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedByMeState(ThemeData theme, UserModel user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'You Blocked This User',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unblock them to see their posts and interact with them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showUnblockConfirmation(context, ref, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Unblock User'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedByThemState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'User Not Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This account may have been deleted or you may be blocked.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

extension ProfileActionsExtension on _ProfilePageState {
  void _handleProfileMenuAction(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    String action,
  ) {
    switch (action) {
      case 'report':
        _showReportDialog(context, ref, user);
        break;
      case 'block':
        _showBlockConfirmation(context, ref, user);
        break;
      case 'unblock':
        _showUnblockConfirmation(context, ref, user);
        break;
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final theme = Theme.of(context);
    String selectedReason = 'Spam';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report @${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this user?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Reason',
              ),
              items: [
                'Spam',
                'Harassment',
                'Inappropriate profile',
                'Impersonation',
                'Other',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => selectedReason = v ?? selectedReason,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final reporterId = ref.read(authProvider).user?.uid;
                if (reporterId == null) return;

                await FirestoreService.submitReport(
                  reporterId: reporterId,
                  targetId: user.uid,
                  targetType: 'user',
                  reason: selectedReason,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Thank you for making Skynaire safer.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit report: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block @${user.username}?'),
        content: const Text(
          'They will no longer be able to find your profile or posts on Skynaire. '
          'We won\'t let them know you blocked them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(blockingNotifierProvider.notifier)
                    .blockUser(user.uid);

                // Invalidate providers to refresh UI instantly and show "Blocked" state
                ref.invalidate(isUserBlockedProvider(user.uid));
                ref.invalidate(isEitherBlockedProvider(user.uid));
                ref.invalidate(userProfileByIdProvider(user.uid));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked @${user.username}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock @${user.username}?'),
        content: const Text(
          'They will now be able to see your posts and follow you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(blockingNotifierProvider.notifier)
                    .unblockUser(user.uid);

                // Invalidate the provider to refresh UI instantly
                ref.invalidate(isUserBlockedProvider(user.uid));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unblocked @${user.username}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to unblock: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
