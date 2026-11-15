import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/user_providers.dart';
import '../../core/models/user_model.dart';

class AuthorHeader extends ConsumerWidget {
  final String authorId;
  final String fallbackName;
  final String? fallbackAvatar;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? nameStyle;
  final double avatarSize;

  const AuthorHeader({
    super.key,
    required this.authorId,
    required this.fallbackName,
    this.fallbackAvatar,
    this.trailing,
    this.onTap,
    this.nameStyle,
    this.avatarSize = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileByIdProvider(authorId));

    return userAsync.when(
      data: (user) {
        final displayName = user?.displayName ?? fallbackName;
        final avatarUrl = user?.photoURL ?? fallbackAvatar;
        final username = user?.username;

        return Row(
          children: [
            GestureDetector(
              onTap: onTap,
              child: _buildAvatar(theme, avatarUrl, displayName),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: nameStyle ??
                                theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user?.isVerified ?? false) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (username != null)
                      Text(
                        '@$username',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        );
      },
      loading: () => _buildLoadingHeader(theme),
      error: (_, __) => _buildErrorHeader(theme),
    );
  }

  Widget _buildAvatar(ThemeData theme, String? url, String name) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.secondary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Container(
            width: avatarSize,
            height: avatarSize,
            color: theme.colorScheme.surfaceContainerHighest,
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => _buildFallbackInitial(theme, name),
                  )
                : _buildFallbackInitial(theme, name),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackInitial(ThemeData theme, String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: avatarSize * 0.4,
        ),
      ),
    );
  }

  Widget _buildLoadingHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: avatarSize + 8,
          height: avatarSize + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorHeader(ThemeData theme) {
    return _buildAvatar(theme, null, fallbackName);
  }
}
