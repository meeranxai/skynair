import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission (especially for Android 13+, iOS and Web)
    if (!kIsWeb) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        dev.log('✅ User granted notification permission');
      } else {
        dev.log('❌ User declined notification permission');
      }
    }

    // Initialize local notifications for foreground messages
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create high importance channels for Android with custom sounds
    if (!kIsWeb) {
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
            'general_channel',
            'General Notifications',
            description:
                'Notifications for messages, follows, and system updates.',
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('app_notification'),
            playSound: true,
          );

      final flutterLocalNotificationsPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await flutterLocalNotificationsPlugin?.createNotificationChannel(
        generalChannel,
      );
    }
  }

  static Future<void> updateToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permissions (specifically for iOS/Web)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Get the token
      final token = await messaging.getToken();
      if (token != null) {
        dev.log('✅ FCM Token obtained: $token');
        await FirestoreService.updateUserFcmToken(uid, token);
      }
      
      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        FirestoreService.updateUserFcmToken(uid, newToken);
      });
      
      // Setup foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        dev.log('🔔 Got a message whilst in the foreground!');
        
        if (message.notification != null) {
          _showLocalNotification(
            message.notification!.title ?? 'New Notification',
            message.notification!.body ?? '',
          );
        }
      });
    } catch (e) {
      dev.log('❌ Error updating FCM token: $e');
    }
  }

  static Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'Notifications for messages, follows, and system updates.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      sound: RawResourceAndroidNotificationSound('app_notification'),
      playSound: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'app_notification.wav',
      ),
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Note: Sending notifications directly from the app is not recommended for production
    // due to security risks (exposing server keys). Professional apps use a backend (Node.js/Go)
    // or Cloud Functions to send notifications using FCM v1 API.
    
    dev.log('🚀 Sending push notification to token: $token');
    
    // In a real professional setup, this would be a call to your backend
    // which then sends the following payload to FCM v1:
    /*
    {
      "message": {
        "token": token,
        "notification": { "title": title, "body": body },
        "android": {
          "priority": "high",
          "notification": {
            "channel_id": "general_channel",
            "sound": "app_notification",
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "app_notification.wav",
              "category": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        },
        "data": data ?? {}
      }
    }
    */
  }
}
