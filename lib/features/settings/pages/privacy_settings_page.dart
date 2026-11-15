import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_profile_provider.dart';
import 'blocked_users_page.dart';
import '../../profile/pages/follow_requests_page.dart';
import '../../../core/providers/follow_provider.dart';

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(userProfileProvider);
    final user = profileState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Center'), centerTitle: true),
      body: ListView(
        children: [
          _buildInfoBanner(theme),

          _buildSectionHeader(theme, 'Account Visibility'),
          _buildPrivacyTile(
            theme,
            icon: Icons.lock_outline,
            title: 'Private Account',
            subtitle:
                'Only people you approve can see your profile and content.',
            trailing: Switch(
              value: user.isPrivate,
              onChanged:
                  (value) => _updatePrivacy(ref, context, {'isPrivate': value}),
            ),
          ),

          // Show follow requests if account is private
          if (user.isPrivate)
            ref.watch(incomingFollowRequestsProvider).when(
              data: (requests) => _buildPrivacyTile(
                theme,
                icon: Icons.person_add_outlined,
                title: 'Follow Requests',
                subtitle: 'Manage people who want to follow you.',
                trailing: requests.isNotEmpty ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${requests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ) : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FollowRequestsPage(),
                    ),
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          const Divider(),
          _buildSectionHeader(theme, 'Interactions'),
          _buildPrivacyTile(
            theme,
            icon: Icons.alternate_email,
            title: 'Mentions & Tags',
            subtitle: _getWhoCanMentionLabel(user.whoCanMention),
            onTap: () => _showSelectionDialog(
              context,
              ref,
              'Who can Mention you?',
              'whoCanMention',
              user.whoCanMention,
              {
                'everyone': 'Everyone',
                'following': 'People you follow',
                'no_one': 'No one',
              },
            ),
          ),
          _buildPrivacyTile(
            theme,
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            subtitle: _getWhoCanMessageLabel(user.whoCanMessage),
            onTap: () => _showSelectionDialog(
              context,
              ref,
              'Who can Message you?',
              'whoCanMessage',
              user.whoCanMessage,
              {'everyone': 'Everyone', 'following': 'People you follow'},
            ),
          ),
          _buildPrivacyTile(
            theme,
            icon: Icons.share_outlined,
            title: 'Story Sharing',
            subtitle: 'Allow others to share your stories as messages.',
            trailing: Switch(
              value: user.allowStorySharing,
              onChanged: (value) =>
                  _updatePrivacy(ref, context, {'allowStorySharing': value}),
            ),
          ),

          const Divider(),
          _buildSectionHeader(theme, 'Online Presence'),
          _buildPrivacyTile(
            theme,
            icon: Icons.visibility_outlined,
            title: 'Last Seen',
            subtitle: 'Show when you were last active.',
            trailing: Switch(
              value: user.showLastSeen,
              onChanged: (value) =>
                  _updatePrivacy(ref, context, {'showLastSeen': value}),
            ),
          ),
          _buildPrivacyTile(
            theme,
            icon: Icons.fiber_manual_record,
            title: 'Online Status',
            subtitle: 'Show when you are currently active.',
            trailing: Switch(
              value: user.showOnlineStatus,
              onChanged: (value) =>
                  _updatePrivacy(ref, context, {'showOnlineStatus': value}),
            ),
          ),
          _buildPrivacyTile(
            theme,
            icon: Icons.done_all,
            title: 'Read Receipts',
            subtitle: 'Allow others to see when you have read messages.',
            trailing: Switch(
              value: user.allowReadReceipts,
              onChanged: (value) =>
                  _updatePrivacy(ref, context, {'allowReadReceipts': value}),
            ),
          ),

          const Divider(),
          _buildSectionHeader(theme, 'Safety'),
          _buildPrivacyTile(
            theme,
            icon: Icons.block_flipped,
            title: 'Blocked Accounts',
            subtitle: 'See the list of accounts you have blocked.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersPage(),
                ),
              );
            },
          ),
          _buildPrivacyTile(
            theme,
            icon: Icons.volume_off_outlined,
            title: 'Muted Accounts',
            subtitle: 'Accounts you have muted for posts/stories.',
            onTap: () {
              // Navigate to muted accounts
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your privacy is our priority. Customize how you interact with the community.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrivacyTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }

  String _getWhoCanMentionLabel(String value) {
    if (value == 'everyone') return 'Allowed from Everyone';
    if (value == 'following') return 'Only from people you follow';
    return 'No one can mention you';
  }

  String _getWhoCanMessageLabel(String value) {
    if (value == 'everyone') return 'Anyone can send message requests';
    return 'Only people you follow';
  }

  void _showSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String key,
    String currentValue,
    Map<String, String> options,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...options.entries.map(
              (entry) => RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: currentValue,
                onChanged: (value) {
                  if (value != null) {
                    _updatePrivacy(ref, context, {key: value});
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePrivacy(
    WidgetRef ref,
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      await ref.read(userProfileProvider.notifier).updatePrivacySettings(data);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }
}
