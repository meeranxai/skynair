/// Photo Quality Analysis Result Model
class PhotoQualityResult {
  final int score; // 0-100
  final int width;
  final int height;
  final int fileSize; // in bytes
  final double aspectRatio;
  final bool isBlurry;
  final bool isTooSmall;
  final bool isTooLarge;
  final bool isDark;
  final bool isBright;
  final List<String> issues;
  final List<String> suggestions;
  final QualityLevel level;

  PhotoQualityResult({
    required this.score,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.aspectRatio,
    required this.isBlurry,
    required this.isTooSmall,
    required this.isTooLarge,
    required this.isDark,
    required this.isBright,
    required this.issues,
    required this.suggestions,
    required this.level,
  });

  bool get isAcceptable => score >= 60 && !isTooSmall && !isTooLarge;

  bool get needsWarning => score >= 40 && score < 60;

  bool get shouldReject => score < 40 || isTooSmall || isTooLarge;

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get resolutionFormatted => '${width}x$height';
}

enum QualityLevel {
  excellent, // 80-100
  good, // 60-79
  fair, // 40-59
  poor, // 0-39
}
