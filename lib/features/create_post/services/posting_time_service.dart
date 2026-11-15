import '../models/post_metadata.dart';

/// Service for analyzing optimal posting times
class PostingTimeService {
  /// Analyze current time for posting
  PostingTimeQuality analyzeCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday

    // Weekend vs Weekday
    final isWeekend = dayOfWeek >= 6;

    if (isWeekend) {
      return _analyzeWeekendTime(hour);
    } else {
      return _analyzeWeekdayTime(hour);
    }
  }

  /// Analyze weekday posting time
  PostingTimeQuality _analyzeWeekdayTime(int hour) {
    // Excellent times (less competition, good engagement)
    if ((hour >= 10 && hour < 11) || (hour >= 14 && hour < 16)) {
      return PostingTimeQuality.excellent;
    }

    // Good times
    if ((hour >= 7 && hour < 9) ||
        (hour >= 12 && hour < 14) ||
        (hour >= 19 && hour < 21)) {
      return PostingTimeQuality.good;
    }

    // Fair times
    if ((hour >= 9 && hour < 10) ||
        (hour >= 16 && hour < 19) ||
        (hour >= 21 && hour < 23)) {
      return PostingTimeQuality.fair;
    }

    // Poor times (late night, early morning)
    return PostingTimeQuality.poor;
  }

  /// Analyze weekend posting time
  PostingTimeQuality _analyzeWeekendTime(int hour) {
    // Excellent times
    if ((hour >= 9 && hour < 11) || (hour >= 19 && hour < 21)) {
      return PostingTimeQuality.excellent;
    }

    // Good times
    if ((hour >= 11 && hour < 13) ||
        (hour >= 17 && hour < 19) ||
        (hour >= 21 && hour < 23)) {
      return PostingTimeQuality.good;
    }

    // Fair times
    if ((hour >= 7 && hour < 9) || (hour >= 13 && hour < 17)) {
      return PostingTimeQuality.fair;
    }

    // Poor times
    return PostingTimeQuality.poor;
  }

  /// Get next best posting times
  List<DateTime> suggestBestTimes({int count = 3}) {
    final now = DateTime.now();
    final suggestions = <DateTime>[];

    // Check next 48 hours
    for (int i = 1; i <= 48; i++) {
      final futureTime = now.add(Duration(hours: i));
      final quality = _getTimeQuality(futureTime);

      if (quality == PostingTimeQuality.excellent) {
        suggestions.add(futureTime);
        if (suggestions.length >= count) break;
      }
    }

    // If not enough excellent times, add good times
    if (suggestions.length < count) {
      for (int i = 1; i <= 48; i++) {
        final futureTime = now.add(Duration(hours: i));
        final quality = _getTimeQuality(futureTime);

        if (quality == PostingTimeQuality.good &&
            !suggestions.contains(futureTime)) {
          suggestions.add(futureTime);
          if (suggestions.length >= count) break;
        }
      }
    }

    return suggestions;
  }

  /// Get time quality for specific datetime
  PostingTimeQuality _getTimeQuality(DateTime dateTime) {
    final hour = dateTime.hour;
    final isWeekend = dateTime.weekday >= 6;

    if (isWeekend) {
      return _analyzeWeekendTime(hour);
    } else {
      return _analyzeWeekdayTime(hour);
    }
  }

  /// Get detailed time analysis
  Map<String, dynamic> getDetailedAnalysis() {
    final now = DateTime.now();
    final currentQuality = analyzeCurrentTime();
    final bestTimes = suggestBestTimes(count: 3);

    return {
      'currentTime': now,
      'currentQuality': currentQuality,
      'currentScore': _getQualityScore(currentQuality),
      'isWeekend': now.weekday >= 6,
      'suggestedTimes': bestTimes,
      'recommendation': _getRecommendation(currentQuality),
      'engagementPrediction': _predictEngagement(currentQuality),
    };
  }

  /// Get quality score (0-100)
  int _getQualityScore(PostingTimeQuality quality) {
    switch (quality) {
      case PostingTimeQuality.excellent:
        return 90;
      case PostingTimeQuality.good:
        return 70;
      case PostingTimeQuality.fair:
        return 50;
      case PostingTimeQuality.poor:
        return 30;
      case PostingTimeQuality.unknown:
        return 0;
    }
  }

  /// Get recommendation text
  String _getRecommendation(PostingTimeQuality quality) {
    switch (quality) {
      case PostingTimeQuality.excellent:
        return 'Perfect time to post! High engagement expected.';
      case PostingTimeQuality.good:
        return 'Good time to post. Your audience is likely active.';
      case PostingTimeQuality.fair:
        return 'Moderate engagement expected. Consider waiting for a better time.';
      case PostingTimeQuality.poor:
        return 'Not ideal. Your post may get less visibility. Schedule for later?';
      case PostingTimeQuality.unknown:
        return 'Unable to analyze posting time.';
    }
  }

  /// Predict engagement level
  String _predictEngagement(PostingTimeQuality quality) {
    switch (quality) {
      case PostingTimeQuality.excellent:
        return 'High (80-100% of average)';
      case PostingTimeQuality.good:
        return 'Good (60-80% of average)';
      case PostingTimeQuality.fair:
        return 'Moderate (40-60% of average)';
      case PostingTimeQuality.poor:
        return 'Low (20-40% of average)';
      case PostingTimeQuality.unknown:
        return 'Unknown';
    }
  }

  /// Format time for display
  String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    final dayName = _getDayName(time.weekday);
    final monthName = _getMonthName(time.month);

    return '$dayName, $monthName ${time.day} at $displayHour:$minute $period';
  }

  /// Get day name
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get time until next excellent time
  Duration getTimeUntilNextExcellentTime() {
    final now = DateTime.now();
    final bestTimes = suggestBestTimes(count: 1);

    if (bestTimes.isEmpty) {
      return Duration.zero;
    }

    return bestTimes.first.difference(now);
  }

  /// Check if should post now or schedule
  Map<String, dynamic> shouldPostNow() {
    final quality = analyzeCurrentTime();
    final score = _getQualityScore(quality);

    return {
      'shouldPostNow': score >= 70,
      'quality': quality,
      'score': score,
      'reason': score >= 70
          ? 'Good time to post now'
          : 'Consider scheduling for better engagement',
    };
  }
}
