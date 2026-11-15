import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/realtime_messaging_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/models/conversation_model.dart';

class MessagesListPage extends ConsumerWidget {
  const MessagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            _buildSearchBar(theme),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        currentUserId: currentUser?.uid ?? '',
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(theme, error, ref),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSearch(context),
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _showUserSearch(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search chats...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.messenger_outline_rounded, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          const Text('No messages yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Start a conversation with your connections'),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load chats: $error'),
          TextButton(
            onPressed: () => ref.invalidate(conversationsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showUserSearch(BuildContext context) {
    // Open user search bottom sheet or page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting new chat...')),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final otherUserId = conversation.getOtherUserId(currentUserId);
    final userAsync = ref.watch(userProfileByIdProvider(otherUserId));
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final messagingState = ref.watch(realtimeMessagingProvider);
    final isOtherUserTyping = messagingState.isUserTyping(conversation.id);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return InkWell(
          onTap: () {
            final queryParams = {
              'otherUserId': otherUserId,
              'otherUserName': user.displayName,
              if (user.photoURL != null) 'otherUserAvatar': user.photoURL!,
            };
            final uri = Uri(path: '/chat/${conversation.id}', queryParameters: queryParams);
            context.push(uri.toString());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
                        child: user.photoURL == null ? Text(user.displayName[0].toUpperCase()) : null,
                      ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageTime),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: unreadCount > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isOtherUserTyping ? 'typing...' : conversation.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOtherUserTyping
                                    ? theme.colorScheme.primary
                                    : unreadCount > 0
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                fontStyle: isOtherUserTyping ? FontStyle.italic : null,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        title: Container(
          height: 16,
          width: 120,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        subtitle: Container(
          height: 14,
          width: 200,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
