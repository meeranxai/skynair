import 'package:flutter/material.dart';
import '../services/content_moderation_service.dart';

/// Content Warning Dialog
/// Shows detailed warning when user tries to publish restricted content
class ContentWarningDialog extends StatelessWidget {
  final ModerationResult moderationResult;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const ContentWarningDialog({
    super.key,
    required this.moderationResult,
    this.onEdit,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context, ModerationResult result) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContentWarningDialog(
        moderationResult: result,
        onEdit: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moderationService = ContentModerationService();
    final severity = moderationService.getSeverity(moderationResult);

    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: _getSeverityColor(severity, theme),
        size: 48,
      ),
      title: Text(
        'Community Guidelines Alert',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aapne aise alfaz istemal kiye hain jo hamari policy ke khilaf hain:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Violations List
            ...moderationResult.violations.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        moderationService.getViolationMessage(category),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Detected Words
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Words:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: moderationResult.restrictedWords.map((word) {
                      return Chip(
                        label: Text(word, style: theme.textTheme.bodySmall),
                        backgroundColor: theme.colorScheme.errorContainer,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSeverityColor(
                  severity,
                  theme,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSeverityColor(
                    severity,
                    theme,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: _getSeverityColor(severity, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getSeverityMessage(severity),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Content'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(ModerationSeverity severity, ThemeData theme) {
    switch (severity) {
      case ModerationSeverity.severe:
        return Colors.red;
      case ModerationSeverity.high:
        return Colors.orange;
      case ModerationSeverity.medium:
        return Colors.amber;
      case ModerationSeverity.none:
        return theme.colorScheme.primary;
    }
  }

  String _getSeverityMessage(ModerationSeverity severity) {
    switch (severity) {
      case ModerationSeverity.severe:
        return '⚠️ Severe Violation: Aapka account immediately suspend ho sakta hai.';
      case ModerationSeverity.high:
        return '⚠️ High Risk: Multiple violations se account restrict hoga.';
      case ModerationSeverity.medium:
        return '⚠️ Warning: Inhe hatayein warna publish nahi kar sakte.';
      case ModerationSeverity.none:
        return 'Content is clean.';
    }
  }
}
