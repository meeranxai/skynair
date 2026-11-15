import 'package:image_picker/image_picker.dart';
import 'photo_quality_result.dart';
import 'edit_parameters.dart';

/// Complete Post Metadata Model
class PostMetadata {
  final XFile? originalPhoto;
  final XFile? editedPhoto;
  final PhotoQualityResult? qualityResult;
  final EditParameters? editParameters;

  final String? hookText;
  final String? messageText;
  final String? ctaText;

  final List<String> hashtags;
  final String category;

  final DateTime? scheduledTime;
  final PostingTimeQuality timeQuality;

  final bool checklistCompleted;

  PostMetadata({
    this.originalPhoto,
    this.editedPhoto,
    this.qualityResult,
    this.editParameters,
    this.hookText,
    this.messageText,
    this.ctaText,
    this.hashtags = const [],
    this.category = 'General',
    this.scheduledTime,
    this.timeQuality = PostingTimeQuality.unknown,
    this.checklistCompleted = false,
  });

  PostMetadata copyWith({
    XFile? originalPhoto,
    XFile? editedPhoto,
    PhotoQualityResult? qualityResult,
    EditParameters? editParameters,
    String? hookText,
    String? messageText,
    String? ctaText,
    List<String>? hashtags,
    String? category,
    DateTime? scheduledTime,
    PostingTimeQuality? timeQuality,
    bool? checklistCompleted,
  }) {
    return PostMetadata(
      originalPhoto: originalPhoto ?? this.originalPhoto,
      editedPhoto: editedPhoto ?? this.editedPhoto,
      qualityResult: qualityResult ?? this.qualityResult,
      editParameters: editParameters ?? this.editParameters,
      hookText: hookText ?? this.hookText,
      messageText: messageText ?? this.messageText,
      ctaText: ctaText ?? this.ctaText,
      hashtags: hashtags ?? this.hashtags,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timeQuality: timeQuality ?? this.timeQuality,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
    );
  }

  XFile? get photoToUse => editedPhoto ?? originalPhoto;

  String get fullCaption {
    final parts = <String>[];
    if (hookText?.isNotEmpty == true) parts.add(hookText!);
    if (messageText?.isNotEmpty == true) parts.add(messageText!);
    if (ctaText?.isNotEmpty == true) parts.add(ctaText!);
    return parts.join('\n\n');
  }

  String get captionWithHashtags {
    final caption = fullCaption;
    if (hashtags.isEmpty) return caption;
    return '$caption\n\n${hashtags.join(' ')}';
  }

  bool get isReadyToPost =>
      photoToUse != null &&
      qualityResult != null &&
      qualityResult!.isAcceptable &&
      hookText?.isNotEmpty == true &&
      messageText?.isNotEmpty == true &&
      hashtags.length >= 5;

  List<String> get missingRequirements {
    final missing = <String>[];
    if (photoToUse == null) missing.add('Photo not selected');
    if (qualityResult == null || !qualityResult!.isAcceptable) {
      missing.add('Photo quality too low');
    }
    if (hookText?.isEmpty != false) missing.add('Hook text missing');
    if (messageText?.isEmpty != false) missing.add('Message text missing');
    if (hashtags.length < 5) missing.add('Need at least 5 hashtags');
    return missing;
  }
}

enum PostingTimeQuality { excellent, good, fair, poor, unknown }

extension PostingTimeQualityExtension on PostingTimeQuality {
  String get label {
    switch (this) {
      case PostingTimeQuality.excellent:
        return 'Excellent Time';
      case PostingTimeQuality.good:
        return 'Good Time';
      case PostingTimeQuality.fair:
        return 'Fair Time';
      case PostingTimeQuality.poor:
        return 'Poor Time';
      case PostingTimeQuality.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case PostingTimeQuality.excellent:
        return '🟢';
      case PostingTimeQuality.good:
        return '🟡';
      case PostingTimeQuality.fair:
        return '🟠';
      case PostingTimeQuality.poor:
        return '🔴';
      case PostingTimeQuality.unknown:
        return '⚪';
    }
  }

  String get description {
    switch (this) {
      case PostingTimeQuality.excellent:
        return 'High engagement expected - perfect time to post!';
      case PostingTimeQuality.good:
        return 'Good engagement expected - great time to post';
      case PostingTimeQuality.fair:
        return 'Moderate engagement expected';
      case PostingTimeQuality.poor:
        return 'Low engagement expected - consider posting later';
      case PostingTimeQuality.unknown:
        return 'Time quality not analyzed';
    }
  }
}
