import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/photo_quality_result.dart';

/// Service for analyzing photo quality
class PhotoQualityService {
  // Quality thresholds
  static const int minWidth = 800;
  static const int minHeight = 600;
  static const int minFileSize = 100 * 1024; // 100KB
  static const int maxFileSize =
      8 * 1024 * 1024; // 8MB (Updated to match user settings)
  static const double blurThreshold = 100.0; // Laplacian variance threshold

  /// Analyze photo quality
  Future<PhotoQualityResult> analyzePhoto(XFile photoFile) async {
    try {
      // Read bytes
      final bytes = await photoFile.readAsBytes();
      final fileSize = bytes.length;

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        return _createErrorResult('Failed to decode image');
      }

      final width = image.width;
      final height = image.height;
      final aspectRatio = width / height;

      // Perform checks
      final issues = <String>[];
      final suggestions = <String>[];
      int score = 100;

      // Check resolution
      final isTooSmall = width < minWidth || height < minHeight;
      if (isTooSmall) {
        issues.add('Resolution too low ($width x $height)');
        suggestions.add('Use a photo with at least 800x600 pixels');
        score -= 40;
      }

      // Check file size
      final isTooLarge = fileSize > maxFileSize;
      final isTooSmallFile = fileSize < minFileSize;

      if (isTooLarge) {
        issues.add('File size too large (${_formatFileSize(fileSize)})');
        suggestions.add('Compress the image or choose a smaller file');
        score -= 30;
      } else if (isTooSmallFile) {
        issues.add('File size very small - may be low quality');
        score -= 10;
      }

      // Check blur (simplified - using brightness variance as proxy)
      final isBlurry = _checkBlur(image);
      if (isBlurry) {
        issues.add('Image appears blurry or out of focus');
        suggestions.add('Take a clearer photo with better focus');
        score -= 25;
      }

      // Check brightness
      final brightness = _calculateBrightness(image);
      final isDark = brightness < 50;
      final isBright = brightness > 200;

      if (isDark) {
        issues.add('Image is too dark');
        suggestions.add('Increase brightness or take photo in better lighting');
        score -= 15;
      } else if (isBright) {
        issues.add('Image is too bright/overexposed');
        suggestions.add('Reduce brightness or avoid direct sunlight');
        score -= 15;
      }

      // Check aspect ratio
      if (aspectRatio < 0.5 || aspectRatio > 2.0) {
        issues.add('Unusual aspect ratio');
        suggestions.add(
          'Consider cropping to standard ratio (1:1, 4:5, or 16:9)',
        );
        score -= 5;
      }

      // Ensure score is within bounds
      score = score.clamp(0, 100);

      // Determine quality level
      final level = _getQualityLevel(score);

      return PhotoQualityResult(
        score: score,
        width: width,
        height: height,
        fileSize: fileSize,
        aspectRatio: aspectRatio,
        isBlurry: isBlurry,
        isTooSmall: isTooSmall,
        isTooLarge: isTooLarge,
        isDark: isDark,
        isBright: isBright,
        issues: issues,
        suggestions: suggestions,
        level: level,
      );
    } catch (e) {
      return _createErrorResult('Error analyzing photo: $e');
    }
  }

  /// Check if image is blurry (simplified method)
  bool _checkBlur(img.Image image) {
    // Calculate variance of pixel values as a simple blur detection
    // Lower variance often indicates blur
    final pixels = image.getBytes();
    if (pixels.isEmpty) return false;

    double sum = 0;
    for (final pixel in pixels) {
      sum += pixel;
    }
    final mean = sum / pixels.length;

    double variance = 0;
    for (final pixel in pixels) {
      variance += (pixel - mean) * (pixel - mean);
    }
    variance /= pixels.length;

    // If variance is too low, image might be blurry
    return variance < blurThreshold;
  }

  /// Calculate average brightness
  double _calculateBrightness(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Calculate perceived brightness
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    return pixelCount > 0 ? totalBrightness / pixelCount : 128;
  }

  /// Get quality level from score
  QualityLevel _getQualityLevel(int score) {
    if (score >= 80) return QualityLevel.excellent;
    if (score >= 60) return QualityLevel.good;
    if (score >= 40) return QualityLevel.fair;
    return QualityLevel.poor;
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create error result
  PhotoQualityResult _createErrorResult(String error) {
    return PhotoQualityResult(
      score: 0,
      width: 0,
      height: 0,
      fileSize: 0,
      aspectRatio: 0,
      isBlurry: false,
      isTooSmall: true,
      isTooLarge: false,
      isDark: false,
      isBright: false,
      issues: [error],
      suggestions: ['Please select a valid image file'],
      level: QualityLevel.poor,
    );
  }

  /// Quick validation without full analysis
  Future<bool> quickValidation(XFile photoFile) async {
    try {
      final bytes = await photoFile.readAsBytes();
      final fileSize = bytes.length;
      if (fileSize > maxFileSize || fileSize < minFileSize) {
        return false;
      }

      final image = img.decodeImage(bytes);
      if (image == null) return false;

      return image.width >= minWidth && image.height >= minHeight;
    } catch (e) {
      return false;
    }
  }
}
