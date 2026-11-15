import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  /// Request all core permissions needed for the app
  static Future<void> requestAllPermissions(BuildContext context) async {
    // Check current statuses first to avoid unnecessary requests
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    // Handle storage permissions based on platform/version
    // On Android 13+ (SDK 33), photos and videos are separate
    await [
      Permission.photos,
      Permission.videos,
    ].request();

    dev.log('ℹ️ Permissions pre-requested on launch');
    // We don't show the error dialog here because some permissions might be optional
    // (like notifications or microphone if they just want to browse).
    // Specific features should use checkAndRequest() to show the dialog when needed.
  }

  /// Check and request specific permissions
  static Future<bool> checkAndRequest(Permission permission, BuildContext context) async {
    final status = await permission.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return false;
    }

    final result = await permission.request();
    return result.isGranted;
  }

  /// Request gallery permission with Android version handling
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    Permission permission = Permission.photos;
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Use storage permission for Android 12 (API 32) and below
      if (androidInfo.version.sdkInt <= 32) {
        permission = Permission.storage;
      }
    }
    
    return checkAndRequest(permission, context);
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Needed'),
        content: const Text(
          'Skynaire requires camera and storage access to share photos and articles. Please enable these in your device settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
