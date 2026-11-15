import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/content_moderation_service.dart';

/// Moderated Text Field with Real-time Content Detection
/// Shows inline warnings when restricted words are detected
class ModeratedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<ModerationResult>? onModerationChange;
  final bool showInlineWarning;
  final bool showCharacterCount;

  const ModeratedTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onModerationChange,
    this.showInlineWarning = true,
    this.showCharacterCount = false,
  });

  @override
  State<ModeratedTextField> createState() => _ModeratedTextFieldState();
}

class _ModeratedTextFieldState extends State<ModeratedTextField> {
  final _moderationService = ContentModerationService();
  ModerationResult? _currentResult;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkContent);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkContent);
    super.dispose();
  }

  void _checkContent() {
    final content = widget.controller.text;
    final result = _moderationService.checkContent(content);

    setState(() {
      _currentResult = result;
      _showWarning = !result.isClean;
    });

    // Notify parent
    widget.onModerationChange?.call(result);
    widget.onChanged?.call(content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Field
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _showWarning
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
                width: _showWarning ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _showWarning
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
                width: _showWarning ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _showWarning
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            counterText: widget.showCharacterCount ? null : '',
            prefixIcon: _showWarning
                ? Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  )
                : null,
          ),
        ),

        // Inline Warning
        if (widget.showInlineWarning &&
            _showWarning &&
            _currentResult != null) ...[
          const SizedBox(height: 8),
          _buildInlineWarning(theme),
        ],
      ],
    );
  }

  Widget _buildInlineWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Guidelines Alert',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restricted words detected: ${_currentResult!.restrictedWords.take(3).join(", ")}${_currentResult!.restrictedWords.length > 3 ? "..." : ""}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inhe hatayein warna publish nahi kar sakte.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
