import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/realtime_provider.dart';
import '../../../core/models/user_model.dart';

class OnlineUsersBar extends ConsumerWidget {
  const OnlineUsersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final theme = Theme.of(context);

    if (onlineUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Online Now (${onlineUsers.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: onlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = onlineUsers[index];
                    return _buildOnlineUserItem(context, theme, user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineUserItem(
    BuildContext context,
    ThemeData theme,
    UserModel user,
  ) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : 'U',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user.displayName.split(' ').first,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
