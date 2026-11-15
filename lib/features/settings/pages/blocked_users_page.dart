import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/blocking_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
        centerTitle: true,
      ),
      body: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) return _buildEmptyState(theme);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return _buildBlockedUserTile(context, theme, user, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Accounts',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Blocked accounts will appear here. When you block someone, they won\'t be able to find your profile, posts, or stories on Skynaire.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUserTile(BuildContext context, ThemeData theme, UserModel user, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
          child: user.photoURL == null ? Text(user.displayName[0].toUpperCase()) : null,
        ),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('@${user.username}'),
        trailing: OutlinedButton(
          onPressed: () => _unblockUser(context, user, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Unblock'),
        ),
      ),
    );
  }

  void _unblockUser(BuildContext context, UserModel user, WidgetRef ref) {
    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user.displayName}?'),
        content: const Text('They will now be able to see your posts and follow you on Skynaire.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(blockingNotifierProvider.notifier).unblockUser(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unblocked ${user.displayName}')),
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
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
