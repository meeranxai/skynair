import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
// import 'package:screenshot/screenshot.dart'; // Optional package
import '../models/post_model.dart';

class ShareService {
  // static final ScreenshotController screenshotController =
  //     ScreenshotController();

  /// Share post externally (WhatsApp, Instagram, etc.)
  static Future<void> sharePostExternal({
    required PostModel post,
    BuildContext? context,
    Uint8List? screenshot,
  }) async {
    try {
      // Create share text
      final shareText = _createShareText(post);

      // If post has image, download and share with image
      if (post.image != null && post.image!.isNotEmpty) {
        await _shareWithImage(
          text: shareText,
          imageUrl: post.image!,
          context: context,
        );
      } else if (screenshot != null) {
        // Share with screenshot
        await _shareWithScreenshot(
          text: shareText,
          screenshot: screenshot,
          context: context,
        );
      } else {
        // Share text only
        await Share.share(
          shareText,
          subject: 'Check out this post on Skynaire',
        );
      }
    } catch (e) {
      debugPrint('Error sharing post: $e');
      rethrow;
    }
  }

  /// Share post with image
  static Future<void> _shareWithImage({
    required String text,
    required String imageUrl,
    BuildContext? context,
  }) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_image.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // Share with image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Check out this post on Skynaire',
      );

      // Clean up
      await file.delete();
    } catch (e) {
      debugPrint('Error sharing with image: $e');
      // Fallback to text only
      await Share.share(text);
    }
  }

  /// Share with screenshot
  static Future<void> _shareWithScreenshot({
    required String text,
    required Uint8List screenshot,
    BuildContext? context,
  }) async {
    try {
      // Save screenshot to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_screenshot.png');
      await file.writeAsBytes(screenshot);

      // Share with screenshot
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Check out this post on Skynaire',
      );

      // Clean up
      await file.delete();
    } catch (e) {
      debugPrint('Error sharing with screenshot: $e');
      // Fallback to text only
      await Share.share(text);
    }
  }

  /// Create share text from post
  static String _createShareText(PostModel post) {
    final buffer = StringBuffer();

    // Add title if exists
    if (post.title.isNotEmpty) {
      buffer.writeln(post.title);
      buffer.writeln();
    }

    // Add description
    if (post.description.isNotEmpty) {
      buffer.writeln(post.description);
      buffer.writeln();
    }

    // Add author
    buffer.writeln('Posted by ${post.authorName}');
    buffer.writeln();

    // Add app link
    buffer.writeln('Shared from Skynaire');
    // TODO: Add deep link when available
    // buffer.writeln('https://skynaire.app/post/${post.id}');

    return buffer.toString();
  }

  /// Share to specific app
  static Future<void> shareToApp({
    required PostModel post,
    required ShareDestination destination,
    Uint8List? screenshot,
  }) async {
    final shareText = _createShareText(post);

    switch (destination) {
      case ShareDestination.whatsapp:
        await _shareToWhatsApp(shareText, post.image, screenshot);
        break;
      case ShareDestination.instagram:
        await _shareToInstagram(post.image, screenshot);
        break;
      case ShareDestination.facebook:
        await _shareToFacebook(shareText, post.image, screenshot);
        break;
      case ShareDestination.twitter:
        await _shareToTwitter(shareText, post.image, screenshot);
        break;
      case ShareDestination.telegram:
        await _shareToTelegram(shareText, post.image, screenshot);
        break;
      case ShareDestination.sms:
        await _shareViaSMS(shareText);
        break;
      case ShareDestination.email:
        await _shareViaEmail(shareText, post);
        break;
      case ShareDestination.copyLink:
        await _copyLink(post);
        break;
    }
  }

  /// Share to WhatsApp
  static Future<void> _shareToWhatsApp(
    String text,
    String? imageUrl,
    Uint8List? screenshot,
  ) async {
    // Note: share_plus will handle WhatsApp sharing
    if (imageUrl != null) {
      await _shareWithImage(text: text, imageUrl: imageUrl);
    } else if (screenshot != null) {
      await _shareWithScreenshot(text: text, screenshot: screenshot);
    } else {
      await Share.share(text);
    }
  }

  /// Share to Instagram
  static Future<void> _shareToInstagram(
    String? imageUrl,
    Uint8List? screenshot,
  ) async {
    // Instagram requires image
    if (imageUrl != null) {
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/instagram_share.jpg');
      await file.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([XFile(file.path)]);
      await file.delete();
    } else if (screenshot != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/instagram_share.png');
      await file.writeAsBytes(screenshot);
      await Share.shareXFiles([XFile(file.path)]);
      await file.delete();
    }
  }

  /// Share to Facebook
  static Future<void> _shareToFacebook(
    String text,
    String? imageUrl,
    Uint8List? screenshot,
  ) async {
    if (imageUrl != null) {
      await _shareWithImage(text: text, imageUrl: imageUrl);
    } else {
      await Share.share(text);
    }
  }

  /// Share to Twitter
  static Future<void> _shareToTwitter(
    String text,
    String? imageUrl,
    Uint8List? screenshot,
  ) async {
    // Twitter has character limit
    final twitterText = text.length > 280
        ? '${text.substring(0, 277)}...'
        : text;

    if (imageUrl != null) {
      await _shareWithImage(text: twitterText, imageUrl: imageUrl);
    } else {
      await Share.share(twitterText);
    }
  }

  /// Share to Telegram
  static Future<void> _shareToTelegram(
    String text,
    String? imageUrl,
    Uint8List? screenshot,
  ) async {
    if (imageUrl != null) {
      await _shareWithImage(text: text, imageUrl: imageUrl);
    } else {
      await Share.share(text);
    }
  }

  /// Share via SMS
  static Future<void> _shareViaSMS(String text) async {
    await Share.share(text);
  }

  /// Share via Email
  static Future<void> _shareViaEmail(String text, PostModel post) async {
    await Share.share(
      text,
      subject: post.title.isNotEmpty ? post.title : 'Check out this post',
    );
  }

  /// Copy link to clipboard
  static Future<void> _copyLink(PostModel post) async {
    // TODO: Implement deep linking
    final link = 'https://skynaire.app/post/${post.id}';
    await Share.share(link);
  }

  /// Take screenshot of widget (requires screenshot package)
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      // TODO: Implement with screenshot package
      // return await screenshotController.captureFromWidget(widget);
      return null;
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      return null;
    }
  }

  /// Get share statistics
  static Map<String, dynamic> getShareStats(PostModel post) {
    return {
      'shareCount': post.shareCount,
      'hasImage': post.image != null,
      'hasTitle': post.title.isNotEmpty,
      'contentLength': post.description.length,
    };
  }
}

/// Share destinations
enum ShareDestination {
  whatsapp,
  instagram,
  facebook,
  twitter,
  telegram,
  sms,
  email,
  copyLink,
}

/// Share destination info
class ShareDestinationInfo {
  final ShareDestination destination;
  final String name;
  final IconData icon;
  final Color color;

  const ShareDestinationInfo({
    required this.destination,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ShareDestinationInfo> all = [
    ShareDestinationInfo(
      destination: ShareDestination.whatsapp,
      name: 'WhatsApp',
      icon: Icons.chat,
      color: Color(0xFF25D366),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.instagram,
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.facebook,
      name: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.twitter,
      name: 'Twitter',
      icon: Icons.flutter_dash, // Using as placeholder
      color: Color(0xFF1DA1F2),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.telegram,
      name: 'Telegram',
      icon: Icons.send,
      color: Color(0xFF0088CC),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.sms,
      name: 'SMS',
      icon: Icons.message,
      color: Color(0xFF34B7F1),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.email,
      name: 'Email',
      icon: Icons.email,
      color: Color(0xFFEA4335),
    ),
    ShareDestinationInfo(
      destination: ShareDestination.copyLink,
      name: 'Copy Link',
      icon: Icons.link,
      color: Color(0xFF757575),
    ),
  ];
}
