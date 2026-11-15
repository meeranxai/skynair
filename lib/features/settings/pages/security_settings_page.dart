import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/services/session_service.dart';
import '../../../core/models/session_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockState = ref.watch(appLockProvider);
    final sessionsAsync = ref.watch(userSessionsProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Security Center'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Scoreboard removed as per request
          
          _buildSectionHeader(theme, 'Login & Recovery'),
          _buildSecurityTile(
            theme,
            icon: Icons.password_rounded,
            title: 'Change Password',
            subtitle: 'Update your account credentials',
            onTap: () => _showChangePasswordSheet(context, theme),
          ),
          _buildSecurityTile(
            theme,
            icon: Icons.security_rounded,
            title: 'Two-Factor Authentication',
            subtitle: 'Coming soon - Extra security layer',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Coming Soon'),
                  content: const Text(
                    '2FA (Two-Factor Authentication) will be available in the next update.\n\n'
                    'This feature will add an extra layer of security by requiring:\n'
                    '• SMS/Email verification codes\n'
                    '• Authenticator app support\n'
                    '• Backup recovery codes',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(indent: 20, endIndent: 20),
          
          _buildSectionHeader(theme, 'Device Security'),
          _buildSecurityTile(
            theme,
            icon: Icons.fingerprint_rounded,
            title: 'App Lock',
            subtitle: lockState.hasPin ? 'PIN Protection Active' : 'Set a PIN to enable App Lock',
            trailing: Switch(
              value: lockState.isEnabled && lockState.hasPin,
              onChanged: (value) async {
                if (value) {
                  if (!lockState.hasPin) {
                    await _showSetPinDialog(context, theme);
                  } else {
                    await ref.read(appLockProvider.notifier).setEnabled(true);
                    _showSecurityUpdateSnackBar('App Lock Enabled');
                  }
                } else {
                  await ref.read(appLockProvider.notifier).setEnabled(false);
                  _showSecurityUpdateSnackBar('App Lock Disabled');
                }
              }
            ),
          ),

          if (lockState.hasPin)
            _buildSecurityTile(
              theme,
              icon: Icons.lock_reset_rounded,
              title: 'Change PIN',
              subtitle: 'Update your 4-digit security code',
              onTap: () => _showSetPinDialog(context, theme, isUpdating: true),
            ),
          
          if (lockState.isEnabled)
            _buildSecurityTile(
              theme,
              icon: Icons.timer_rounded,
              title: 'Lock Timeout',
              subtitle: _getTimeoutLabel(lockState.lockTimeout),
              onTap: () => _showTimeoutPicker(context, theme, lockState),
            ),
          
          _buildSectionHeader(theme, 'Where You\'re Logged In'),
          
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No active sessions found (except this one).'),
                );
              }
              // Current session first, then others
              final sortedSessions = [...sessions];
              sortedSessions.sort((a, b) => (b.isCurrent ? 1 : 0).compareTo(a.isCurrent ? 1 : 0));
              
              return Column(
                children: sortedSessions.map((session) => _buildLoginActivityTile(theme, session)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading sessions: $err', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextButton.icon(
              onPressed: () => _signOutAllDevices(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out of all other sessions'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          
          const Divider(indent: 20, endIndent: 20),
          
          _buildSectionHeader(theme, 'Security Checklist'),
          _buildChecklistItem(theme, 'Email Verified', true),
          _buildChecklistItem(theme, 'Strong Password', true),
          _buildChecklistItem(theme, 'App Lock Active', lockState.isEnabled),
          
          if (lockState.securityLogs.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Recent Security Events'),
            ...lockState.securityLogs.take(5).map((log) {
              final title = log['event'] as String;
              final time = DateTime.tryParse(log['time'] ?? '') ?? DateTime.now();
              return _buildEventLog(
                theme, 
                title, 
                _formatTimeAgo(time), 
                _getIconForEvent(title), 
                _getColorForEvent(title)
              );
            }),
          ],
          
          const SizedBox(height: 16),
          _buildSectionHeader(theme, 'Account Actions'),
          _buildSecurityTile(
            theme,
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently remove your account and data',
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(context, theme),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getIconForEvent(String event) {
    if (event.contains('PIN')) return Icons.pin_rounded;
    if (event.contains('2FA')) return Icons.security_rounded;
    if (event.contains('App lock')) return Icons.app_blocking_rounded;
    if (event.contains('timeout')) return Icons.timer_rounded;
    return Icons.shield_rounded;
  }

  Color _getColorForEvent(String event) {
    if (event.contains('disabled')) return Colors.orange;
    if (event.contains('changed')) return Colors.blue;
    return Colors.green;
  }

  Future<void> _showSetPinDialog(BuildContext context, ThemeData theme, {bool isUpdating = false}) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpdating ? 'Change App Lock PIN' : 'Set App Lock PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isUpdating 
              ? 'Enter a new 4-digit PIN for your app.'
              : 'Choose a 4-digit PIN to protect your app.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter 4 digits',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                await ref.read(appLockProvider.notifier).setPin(controller.text);
                if (!isUpdating) {
                   await ref.read(appLockProvider.notifier).setEnabled(true);
                }
                Navigator.pop(context);
                _showSecurityUpdateSnackBar(isUpdating ? 'PIN Successfully Changed' : 'PIN Set and App Lock Enabled');
              }
            },
            child: Text(isUpdating ? 'Update PIN' : 'Set PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(ThemeData theme, String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(time, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildSecurityStatus(ThemeData theme, AppLockState lockState) {
    int score = 50; // Base score
    // Two-factor authentication not implemented yet
    if (lockState.isEnabled) score += 25;
    
    bool isFullySecure = score == 100;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFullySecure 
            ? [Colors.green.shade600, Colors.green.shade400]
            : score >= 75
                ? [Colors.blue.shade600, Colors.blue.shade400]
                : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isFullySecure ? Colors.green : theme.colorScheme.primary).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isFullySecure ? 'Your Account is Highly Secure' : 'Security Score: $score%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFullySecure 
              ? 'Great job! All protection layers are active.' 
              : 'Complete the checklist below to reach 100% protection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSecurityTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Widget _buildLoginActivityTile(ThemeData theme, SessionModel session) {
    final lastActiveStr = DateFormat('MMM d, h:mm a').format(session.lastActive);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        leading: Icon(
          session.deviceType == 'Mobile' ? Icons.smartphone_rounded : Icons.computer_rounded,
          color: session.isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Expanded(child: Text(session.deviceName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            if (session.isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'THIS DEVICE',
                  style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('Last active: $lastActiveStr\n${session.platform}'),
        isThreeLine: true,
        trailing: session.isCurrent ? null : IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showSessionOptions(context, session),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ThemeData theme, String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isDone ? Colors.green : theme.colorScheme.outline,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDone ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: isDone ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }



// ... (existing imports will be preserved by tools if I don't touch them, but here I'm editing the middle/end)

  void _showChangePasswordSheet(BuildContext context, ThemeData theme) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? errorMessage;

          void setLoading(bool value) {
            setState(() => isLoading = value);
          }

          void setError(String? value) {
            setState(() => errorMessage = value);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Enter your current password to set a new one.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      final currentPass = currentPasswordController.text;
                      final newPass = newPasswordController.text;
                      final confirmPass = confirmPasswordController.text;

                      if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                        setError('Please fill in all fields');
                        return;
                      }

                      if (newPass != confirmPass) {
                        setError('New passwords do not match');
                        return;
                      }

                      if (newPass.length < 6) {
                        setError('Password must be at least 6 characters');
                        return;
                      }

                      setLoading(true);
                      setError(null);

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          // Re-authenticate
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPass,
                          );

                          await user.reauthenticateWithCredential(cred);
                          
                          // Update password
                          await user.updatePassword(newPass);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          setError('User not found. Please login again.');
                        }
                      } on FirebaseAuthException catch (e) {
                         if (e.code == 'wrong-password') {
                           setError('Incorrect current password.');
                         } else if (e.code == 'weak-password') {
                           setError('The new password is too weak.');
                         } else {
                           setError(e.message ?? 'An error occurred.');
                         }
                      } catch (e) {
                        setError('An error occurred: $e');
                      } finally {
                        setLoading(false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('Update Password'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSessionOptions(BuildContext context, SessionModel session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Session Details'),
              subtitle: Text('ID: ${session.id}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Sign out from this device', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(sessionServiceProvider).deleteSession(session.id);
                _showSecurityUpdateSnackBar('Signed out from ${session.deviceName}');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _signOutAllDevices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of all sessions?'),
        content: const Text('This will log you out of Skynaire on every device except this one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(sessionServiceProvider).signOutAllExceptCurrent();
              _showSecurityUpdateSnackBar('Signed out of all other sessions');
            },
            child: const Text('Sign Out All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getTimeoutLabel(int minutes) {
    if (minutes == 0) return 'Immediate';
    if (minutes == 1) return 'After 1 minute';
    return 'After $minutes minutes';
  }

  void _showTimeoutPicker(BuildContext context, ThemeData theme, AppLockState lockState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Lock Timeout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            _buildTimeoutOption(0, 'Immediate', lockState.lockTimeout),
            _buildTimeoutOption(1, 'After 1 minute', lockState.lockTimeout),
            _buildTimeoutOption(5, 'After 5 minutes', lockState.lockTimeout),
            _buildTimeoutOption(15, 'After 15 minutes', lockState.lockTimeout),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutOption(int value, String label, int current) {
    return ListTile(
      title: Text(label),
      trailing: current == value ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: () async {
        await ref.read(appLockProvider.notifier).setLockTimeout(value);
        Navigator.pop(context);
        _showSecurityUpdateSnackBar('Lock timeout updated to $label');
      },
    );
  }

  void _showSecurityUpdateSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueGrey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, ThemeData theme) async {
    final passwordController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? errorMessage;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
                const SizedBox(width: 12),
                const Text('Delete Account'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete your account?',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently erase your profile, posts, comments, and followers. This action cannot be undone.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter Password to Confirm',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text('Keep Account', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : () async {
                  if (passwordController.text.isEmpty) {
                    setState(() => errorMessage = 'Please enter your password');
                    return;
                  }

                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                   try {
                    await ref.read(authProvider.notifier).deleteAccount(passwordController.text);
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    setState(() {
                      errorMessage = e.toString().contains('wrong-password') ? 'Incorrect password.' : 'An error occurred: $e';
                      isLoading = false;
                    });
                  }
                },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );
  }
}
