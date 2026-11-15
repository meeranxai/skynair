import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/follow_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/utils/profile_navigation.dart';

class FollowRequestsPage extends ConsumerWidget {
  const FollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(incomingFollowRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_disabled_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No follow requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final request = requests[index];
              final followerId = request['followerId'] as String;
              
              return FollowRequestTile(followerId: followerId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class FollowRequestTile extends ConsumerWidget {
  final String followerId;

  const FollowRequestTile({super.key, required this.followerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileByIdProvider(followerId));

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return ListTile(
          onTap: () => ProfileNavigation.navigateToProfile(context, followerId),
          leading: CircleAvatar(
            backgroundImage: user.photoURL != null
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(user.displayName[0].toUpperCase())
                : null,
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('@${user.username}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: ref.watch(followProvider).isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.green),
                onPressed: ref.watch(followProvider).isLoading 
                  ? null 
                  : () async {
                      try {
                        await ref.read(followProvider.notifier).acceptFollowRequest(followerId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Follow request accepted')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: theme.colorScheme.error),
                          );
                        }
                      }
                    },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: ref.watch(followProvider).isLoading 
                  ? null 
                  : () async {
                      try {
                        await ref.read(followProvider.notifier).declineFollowRequest(followerId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Follow request declined')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: theme.colorScheme.error),
                          );
                        }
                      }
                    },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
