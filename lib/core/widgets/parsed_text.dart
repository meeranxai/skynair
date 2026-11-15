import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/profile_navigation.dart';

class ParsedDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const ParsedDescription({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = style ?? theme.textTheme.bodyLarge;
    final mentionStyle = defaultStyle?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    if (text.isEmpty) return const SizedBox.shrink();

    final List<TextSpan> spans = [];
    final mentionRegex = RegExp(r'@(\w+)');
    
    int lastMatchEnd = 0;
    final matches = mentionRegex.allMatches(text);

    for (final match in matches) {
      // Add text before match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      final String username = match.group(1)!;
      final String fullMention = match.group(0)!;

      spans.add(TextSpan(
        text: fullMention,
        style: mentionStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            // We need UID to navigate, but we only have username.
            // ProfileNavigation.navigateToProfile usually takes UID.
            // However, we can implement navigateToProfileByUsername if needed,
            // or use a search/resolve service.
            // For now, let's assume we can navigate by username if the system supports it.
            ProfileNavigation.navigateToProfileByUsername(context, username);
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
