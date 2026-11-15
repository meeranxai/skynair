import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/content_moderation_service.dart';

/// Content Moderation State
class ContentModerationState {
  final ModerationResult? result;
  final bool canPublish;
  final String? warningMessage;

  ContentModerationState({
    this.result,
    required this.canPublish,
    this.warningMessage,
  });

  ContentModerationState copyWith({
    ModerationResult? result,
    bool? canPublish,
    String? warningMessage,
  }) {
    return ContentModerationState(
      result: result ?? this.result,
      canPublish: canPublish ?? this.canPublish,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }
}

/// Content Moderation Provider
class ContentModerationNotifier extends StateNotifier<ContentModerationState> {
  final ContentModerationService _moderationService;

  ContentModerationNotifier(this._moderationService)
    : super(ContentModerationState(canPublish: true));

  /// Check content and update state
  void checkContent(String content) {
    final result = _moderationService.checkContent(content);
    final canPublish = result.isClean;
    final warningMessage = canPublish
        ? null
        : _moderationService.getWarningMessage(result);

    state = ContentModerationState(
      result: result,
      canPublish: canPublish,
      warningMessage: warningMessage,
    );
  }

  /// Reset state
  void reset() {
    state = ContentModerationState(canPublish: true);
  }

  /// Get highlights for UI
  List<TextHighlight> getHighlights(String content) {
    return _moderationService.getHighlights(content);
  }
}

/// Provider instance
final contentModerationProvider =
    StateNotifierProvider<ContentModerationNotifier, ContentModerationState>(
      (ref) => ContentModerationNotifier(ContentModerationService()),
    );
