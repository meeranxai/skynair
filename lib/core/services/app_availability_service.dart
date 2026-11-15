import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Service to check if apps are installed on device
class AppAvailabilityService {
  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    if (Platform.isAndroid) {
      return await _canLaunchUrl('whatsapp://send');
    } else if (Platform.isIOS) {
      return await _canLaunchUrl('whatsapp://');
    }
    return false;
  }

  /// Check if Instagram is installed
  static Future<bool> isInstagramInstalled() async {
    if (Platform.isAndroid) {
      return await _canLaunchUrl('instagram://');
    } else if (Platform.isIOS) {
      return await _canLaunchUrl('instagram://');
    }
    return false;
  }

  /// Check if Facebook is installed
  static Future<bool> isFacebookInstalled() async {
    if (Platform.isAndroid) {
      return await _canLaunchUrl('fb://');
    } else if (Platform.isIOS) {
      return await _canLaunchUrl('fb://');
    }
    return false;
  }

  /// Check if Twitter is installed
  static Future<bool> isTwitterInstalled() async {
    if (Platform.isAndroid) {
      return await _canLaunchUrl('twitter://');
    } else if (Platform.isIOS) {
      return await _canLaunchUrl('twitter://');
    }
    return false;
  }

  /// Check if Telegram is installed
  static Future<bool> isTelegramInstalled() async {
    if (Platform.isAndroid) {
      return await _canLaunchUrl('tg://');
    } else if (Platform.isIOS) {
      return await _canLaunchUrl('tg://');
    }
    return false;
  }

  /// Check if SMS app is available
  static Future<bool> isSMSAvailable() async {
    return await _canLaunchUrl('sms:');
  }

  /// Check if Email app is available
  static Future<bool> isEmailAvailable() async {
    return await _canLaunchUrl('mailto:');
  }

  /// Helper method to check if URL can be launched
  static Future<bool> _canLaunchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Get all available share destinations
  static Future<List<ShareDestinationAvailability>>
  getAvailableDestinations() async {
    final results = await Future.wait([
      isWhatsAppInstalled(),
      isInstagramInstalled(),
      isFacebookInstalled(),
      isTwitterInstalled(),
      isTelegramInstalled(),
      isSMSAvailable(),
      isEmailAvailable(),
    ]);

    return [
      ShareDestinationAvailability(
        destination: 'whatsapp',
        name: 'WhatsApp',
        isAvailable: results[0],
      ),
      ShareDestinationAvailability(
        destination: 'instagram',
        name: 'Instagram',
        isAvailable: results[1],
      ),
      ShareDestinationAvailability(
        destination: 'facebook',
        name: 'Facebook',
        isAvailable: results[2],
      ),
      ShareDestinationAvailability(
        destination: 'twitter',
        name: 'Twitter',
        isAvailable: results[3],
      ),
      ShareDestinationAvailability(
        destination: 'telegram',
        name: 'Telegram',
        isAvailable: results[4],
      ),
      ShareDestinationAvailability(
        destination: 'sms',
        name: 'SMS',
        isAvailable: results[5],
      ),
      ShareDestinationAvailability(
        destination: 'email',
        name: 'Email',
        isAvailable: results[6],
      ),
      ShareDestinationAvailability(
        destination: 'copyLink',
        name: 'Copy Link',
        isAvailable: true, // Always available
      ),
    ];
  }

  /// Get count of available apps
  static Future<int> getAvailableAppsCount() async {
    final destinations = await getAvailableDestinations();
    return destinations.where((d) => d.isAvailable).length;
  }

  /// Check if any social media app is installed
  static Future<bool> hasAnySocialMediaApp() async {
    final results = await Future.wait([
      isWhatsAppInstalled(),
      isInstagramInstalled(),
      isFacebookInstalled(),
      isTwitterInstalled(),
      isTelegramInstalled(),
    ]);

    return results.any((isInstalled) => isInstalled);
  }
}

/// Model for share destination availability
class ShareDestinationAvailability {
  final String destination;
  final String name;
  final bool isAvailable;

  ShareDestinationAvailability({
    required this.destination,
    required this.name,
    required this.isAvailable,
  });
}
