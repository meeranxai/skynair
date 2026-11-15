import 'package:flutter/foundation.dart';

/// Content Moderation Service
/// Real-time detection of restricted words and policy violations
class ContentModerationService {
  // Singleton pattern
  static final ContentModerationService _instance =
      ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  // Restricted Keywords Database (English + Roman Urdu)
  static const Map<String, List<String>> _restrictedKeywords = {
    // Scams & Fraud
    'scams': [
      'free money',
      'paisa double',
      'investment scam',
      'get rich quick',
      'easy money',
      'guaranteed profit',
      'no risk investment',
      'double your money',
      'paisa kamao',
      'ghar baithe kamao',
      'lottery winner',
      'prize money',
      'bank account hack',
      'credit card free',
      'loan without documents',
      'instant loan',
      'bitcoin scam',
      'crypto fraud',
    ],

    // Platform Integrity
    'platform_integrity': [
      'follow for follow',
      'f4f',
      'follow back',
      'buy followers',
      'buy likes',
      'fake followers',
      'followers kharido',
      'likes kharido',
      'engagement pod',
      'sub4sub',
      'like4like',
      'comment4comment',
      'spam',
      'bot followers',
      'auto followers',
    ],

    // Hate Speech & Abuse (Sample - expand as needed)
    'hate_speech': [
      'hate',
      'kill',
      'terrorist',
      'bomb',
      'attack',
      'violence',
      'abuse',
      'harass',
      'bully',
      'threat',
      'racist',
      'sexist',
      // Add more as per your community guidelines
    ],

    // Adult Content
    'adult_content': [
      'porn',
      'xxx',
      'adult content',
      'explicit',
      'nsfw',
      '18+',
      'sex',
      'nude',
      // Add more as needed
    ],

    // Misinformation
    'misinformation': [
      'fake news',
      'conspiracy',
      'hoax',
      'false information',
      'misleading',
      'propaganda',
      'jhooti khabar',
      'galat khabar',
    ],

    // Personal Information
    'personal_info': [
      'phone number',
      'email address',
      'home address',
      'credit card',
      'password',
      'social security',
      'bank account number',
      'aadhar number',
      'cnic number',
    ],
  };

  /// Check if content contains restricted words
  /// Returns ModerationResult with details
  ModerationResult checkContent(String content) {
    if (content.trim().isEmpty) {
      return ModerationResult(
        isClean: true,
        violations: [],
        restrictedWords: [],
      );
    }

    final lowerContent = content.toLowerCase();
    final List<String> foundWords = [];
    final List<String> categories = [];

    // Check each category
    _restrictedKeywords.forEach((category, keywords) {
      for (final keyword in keywords) {
        // Use word boundary regex for accurate matching
        final pattern = RegExp(
          r'\b' + RegExp.escape(keyword) + r'\b',
          caseSensitive: false,
        );

        if (pattern.hasMatch(lowerContent)) {
          foundWords.add(keyword);
          if (!categories.contains(category)) {
            categories.add(category);
          }
        }
      }
    });

    return ModerationResult(
      isClean: foundWords.isEmpty,
      violations: categories,
      restrictedWords: foundWords,
    );
  }

  /// Get user-friendly message for violation category
  String getViolationMessage(String category) {
    switch (category) {
      case 'scams':
        return 'Scam ya fraud related content detect hua hai. Yeh community guidelines ke khilaf hai.';
      case 'platform_integrity':
        return 'Platform integrity violation detect hua hai (e.g., Follow4Follow, Buy Followers).';
      case 'hate_speech':
        return 'Hate speech ya abusive language detect hui hai. Yeh strictly prohibited hai.';
      case 'adult_content':
        return 'Adult ya inappropriate content detect hua hai. Yeh allowed nahi hai.';
      case 'misinformation':
        return 'Misinformation ya fake news detect hua hai. Verified information share karein.';
      case 'personal_info':
        return 'Personal information share karna unsafe hai. Ise remove karein.';
      default:
        return 'Community guidelines violation detect hua hai.';
    }
  }

  /// Get comprehensive warning message
  String getWarningMessage(ModerationResult result) {
    if (result.isClean) return '';

    final buffer = StringBuffer();
    buffer.writeln('⚠️ Community Guidelines Alert');
    buffer.writeln();
    buffer.writeln(
      'Aapne aise alfaz istemal kiye hain jo hamari policy ke khilaf hain:',
    );
    buffer.writeln();

    for (final category in result.violations) {
      buffer.writeln('• ${getViolationMessage(category)}');
    }

    buffer.writeln();
    buffer.writeln('Detected Words: ${result.restrictedWords.join(", ")}');
    buffer.writeln();
    buffer.writeln(
      '⚠️ Warning: Inhe hatayein warna aapka account restrict ho sakta hai.',
    );

    return buffer.toString();
  }

  /// Check if content is safe to publish
  bool canPublish(String content) {
    return checkContent(content).isClean;
  }

  /// Get severity level (for future use - strikes system)
  ModerationSeverity getSeverity(ModerationResult result) {
    if (result.isClean) return ModerationSeverity.none;

    if (result.violations.contains('hate_speech') ||
        result.violations.contains('adult_content')) {
      return ModerationSeverity.severe;
    }

    if (result.violations.contains('scams') ||
        result.violations.contains('misinformation')) {
      return ModerationSeverity.high;
    }

    return ModerationSeverity.medium;
  }

  /// Highlight restricted words in content (for UI)
  List<TextHighlight> getHighlights(String content) {
    final result = checkContent(content);
    if (result.isClean) return [];

    final List<TextHighlight> highlights = [];
    final lowerContent = content.toLowerCase();

    for (final word in result.restrictedWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(word) + r'\b',
        caseSensitive: false,
      );

      final matches = pattern.allMatches(lowerContent);
      for (final match in matches) {
        highlights.add(
          TextHighlight(
            start: match.start,
            end: match.end,
            word: content.substring(match.start, match.end),
          ),
        );
      }
    }

    return highlights;
  }
}

/// Moderation Result Model
class ModerationResult {
  final bool isClean;
  final List<String> violations;
  final List<String> restrictedWords;

  ModerationResult({
    required this.isClean,
    required this.violations,
    required this.restrictedWords,
  });

  @override
  String toString() {
    return 'ModerationResult(isClean: $isClean, violations: $violations, words: $restrictedWords)';
  }
}

/// Severity Levels
enum ModerationSeverity { none, medium, high, severe }

/// Text Highlight Model (for UI highlighting)
class TextHighlight {
  final int start;
  final int end;
  final String word;

  TextHighlight({required this.start, required this.end, required this.word});
}
