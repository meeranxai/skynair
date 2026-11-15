import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_migration_service.dart';
import '../../../core/providers/auth_provider.dart';

class AdminMigrationPage extends ConsumerStatefulWidget {
  const AdminMigrationPage({super.key});

  @override
  ConsumerState<AdminMigrationPage> createState() => _AdminMigrationPageState();
}

class _AdminMigrationPageState extends ConsumerState<AdminMigrationPage> {
  bool _isFixingCurrentUser = false;
  bool _isFixingAllUsers = false;
  String? _resultMessage;
  bool _isSuccess = false;

  Future<void> _fixCurrentUser() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      setState(() {
        _resultMessage = 'No user logged in';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isFixingCurrentUser = true;
      _resultMessage = null;
    });

    try {
      await UserMigrationService.fixMissingFollowCounts(currentUser.uid);
      setState(() {
        _isFixingCurrentUser = false;
        _resultMessage = 'Successfully fixed follow counts for current user!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isFixingCurrentUser = false;
        _resultMessage = 'Error: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _fixAllUsers() async {
    setState(() {
      _isFixingAllUsers = true;
      _resultMessage = null;
    });

    try {
      await UserMigrationService.fixAllUsers();
      setState(() {
        _isFixingAllUsers = false;
        _resultMessage = 'Successfully fixed all users!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isFixingAllUsers = false;
        _resultMessage = 'Error: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Migration Tools'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Migration Tools',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These tools fix missing follow count fields in user profiles. '
                      'Use "Fix Current User" to fix your own profile, or "Fix All Users" '
                      'to fix all users in the database.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current User Info
            if (currentUser != null) ...[
              Text(
                'Current User',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: currentUser.photoURL != null
                        ? NetworkImage(currentUser.photoURL!)
                        : null,
                    child: currentUser.photoURL == null
                        ? Text(currentUser.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(currentUser.displayName),
                  subtitle: Text('@${currentUser.username}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Followers: ${currentUser.followersCount}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Following: ${currentUser.followingCount}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fix Current User Button
              ElevatedButton.icon(
                onPressed: _isFixingCurrentUser ? null : _fixCurrentUser,
                icon: _isFixingCurrentUser
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_outline),
                label: Text(
                  _isFixingCurrentUser
                      ? 'Fixing...'
                      : 'Fix Current User Follow Counts',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),

              const SizedBox(height: 24),
            ],

            // Fix All Users Button
            Text(
              'Admin Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warning',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will process all users in the database. '
                      'This may take some time depending on the number of users.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isFixingAllUsers ? null : _fixAllUsers,
              icon: _isFixingAllUsers
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.people_outline),
              label: Text(
                _isFixingAllUsers ? 'Processing...' : 'Fix All Users',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),

            const SizedBox(height: 24),

            // Result Message
            if (_resultMessage != null) ...[
              Card(
                color: _isSuccess
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _resultMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _isSuccess
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
