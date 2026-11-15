import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/notification_provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/pages/profile_page.dart';
import '../../posts/pages/post_detail_page.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isNotEmpty) {
                    return PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'mark_all_read':
                            ref
                                .read(notificationProvider.notifier)
                                .markAllAsRead();
                            break;
                          case 'clear_all':
                            _showClearAllDialog(context, ref);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read),
                              SizedBox(width: 8),
                              Text('Mark all as read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all),
                              SizedBox(width: 8),
                              Text('Clear all'),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(notificationProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(
                  context,
                  ref,
                  notification,
                  theme,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Notifications will appear here when other users interact with your posts or follow you!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Start creating posts to get your first notifications!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              'Error loading notifications',
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
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    ThemeData theme,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (direction) {
        ref
            .read(notificationProvider.notifier)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surface
              : theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? theme.colorScheme.outline.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildNotificationAvatar(notification, theme),
          title: Text(
            notification.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _formatNotificationTime(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEW',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: _buildNotificationTypeIcon(notification, theme),
          onTap: () => _handleNotificationTap(context, ref, notification),
        ),
      ),
    );
  }

  Widget _buildNotificationAvatar(
    NotificationModel notification,
    ThemeData theme,
  ) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: notification.fromUserAvatar != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: notification.fromUserAvatar!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildNotificationTypeIcon(
    NotificationModel notification,
    ThemeData theme,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'like':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        color = theme.colorScheme.primary;
        break;
      case 'follow':
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case 'share':
        icon = Icons.share;
        color = Colors.blue;
        break;
      case 'mention':
        icon = Icons.alternate_email;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'follow':
        // Navigate to user profile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfilePage(uid: notification.fromUserId),
          ),
        );
        break;
      case 'like':
      case 'comment':
      case 'mention':
      case 'share':
        // Navigate to post detail if postId exists
        if (notification.postId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailPage(postId: notification.postId!),
            ),
          );
        }
        break;
      default:
        // Handle other notification types
        break;
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
