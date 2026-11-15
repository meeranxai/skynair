import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _jwtToken;
  final Dio _dio = Dio();

  // Event callbacks
  Function(Map<String, dynamic>)? onNewPost;
  Function(Map<String, dynamic>)? onPostUpdate;
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onUserOnline;
  Function(Map<String, dynamic>)? onUserOffline;
  Function(List<Map<String, dynamic>>)? onOnlineUsersList;
  Function(Map<String, dynamic>)? onTyping;
  Function(Map<String, dynamic>)? onStopTyping;
  Function(Map<String, dynamic>)? onNewNotification;
  Function(Map<String, dynamic>)? onNotificationUpdate;
  Function(Map<String, dynamic>)?
  onPostInteraction; // New: For likes, shares, etc.
  Function(Map<String, dynamic>)? onFollowUpdate; // New: For follow counts

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  // Connect with Firebase User and get JWT token
  Future<void> connectWithFirebaseUser(User firebaseUser) async {
    if (_isConnected && _currentUserId == firebaseUser.uid) {
      log('Socket already connected for current user');
      return;
    }

    _currentUserId = firebaseUser.uid;
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Get Firebase ID Token with retry
        final firebaseIdToken = await _getFirebaseTokenWithRetry(firebaseUser);
        if (firebaseIdToken == null) {
          throw SocketException(
            'Failed to get Firebase ID token after retries',
          );
        }

        // Exchange Firebase token for JWT backend token with retry
        await _getJWTTokenFromBackendWithRetry(firebaseIdToken, firebaseUser);
        if (_jwtToken == null) {
          throw SocketException(
            'Failed to get JWT token from backend after retries',
          );
        }

        // Disconnect existing socket if any
        if (_socket != null) {
          _socket!.disconnect();
          _socket!.dispose();
        }

        // Create new socket connection with JWT authentication
        _socket = io.io(
          AppConfig.socketUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .setAuth({'token': _jwtToken})
              .setExtraHeaders({'Authorization': 'Bearer $_jwtToken'})
              .setTimeout(AppConfig.socketTimeout.inMilliseconds)
              .build(),
        );

        _setupSocketListeners();
        _socket!.connect();

        // Wait for connection or timeout
        await _waitForConnection();
        return; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        log('❌ Socket connection error (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          log('🔄 Retrying socket connection in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          log('❌ Socket connection failed after $maxRetries attempts');
          // Continue without socket connection - app should still work
        }
      }
    }
  }

  // Get Firebase token with retry logic
  Future<String?> _getFirebaseTokenWithRetry(User firebaseUser) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final token = await firebaseUser.getIdToken(true); // Force refresh
        if (token != null) {
          return token;
        }
      } catch (e) {
        retryCount++;
        log('❌ Firebase token error (attempt $retryCount): $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }
    return null;
  }

  // Wait for socket connection with timeout
  Future<void> _waitForConnection() async {
    if (_socket == null) return;

    int attempts = 0;
    const maxAttempts = 10; // 5 seconds total

    while (attempts < maxAttempts && !_isConnected) {
      await Future.delayed(Duration(milliseconds: 500));
      attempts++;
    }

    if (!_isConnected) {
      throw SocketException('Socket connection timeout');
    }
  }

  // Get JWT token from backend with retry logic
  Future<void> _getJWTTokenFromBackendWithRetry(
    String firebaseToken,
    User user,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await _dio.post(
          '${AppConfig.baseUrl}/auth/firebase-login',
          data: {
            'firebaseToken': firebaseToken,
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $firebaseToken'},
            sendTimeout: AppConfig.apiTimeout,
            receiveTimeout: AppConfig.apiTimeout,
          ),
        );

        if (response.statusCode == 200 && response.data['token'] != null) {
          _jwtToken = response.data['token'];
          log('✅ JWT token obtained from backend');
          return;
        } else {
          throw SocketException(
            'Invalid response from backend: ${response.data}',
          );
        }
      } catch (e) {
        retryCount++;
        log('❌ JWT token request error (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          throw SocketException(
            'Failed to get JWT token after $maxRetries attempts: $e',
          );
        }
      }
    }
  }

  // Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      log('✅ Socket connected successfully');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      log('⚠️ Socket disconnected');
      _isConnected = false;

      // Auto-reconnect after a delay
      Future.delayed(Duration(seconds: 5), () {
        if (!_isConnected && _currentUserId != null) {
          log('🔄 Attempting auto-reconnect...');
          reconnect();
        }
      });
    });

    _socket!.onConnectError((error) {
      log('❌ Socket connection error: $error');
      _isConnected = false;
    });

    _socket!.onError((error) {
      log('❌ Socket error: $error');
    });

    // Real-time event listeners with error handling
    _socket!.on('user_online', (data) {
      try {
        log('👤 User online: $data');
        onUserOnline?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling user_online event: $e');
      }
    });

    _socket!.on('user_offline', (data) {
      try {
        log('👤 User offline: $data');
        onUserOffline?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling user_offline event: $e');
      }
    });

    _socket!.on('online_users_list', (data) {
      try {
        log('👥 Online users list updated');
        if (data is List) {
          onOnlineUsersList?.call(data.cast<Map<String, dynamic>>());
        }
      } catch (e) {
        log('❌ Error handling online_users_list event: $e');
      }
    });

    _socket!.on('new_post', (data) {
      try {
        log('📝 New post received: ${data['id']}');
        onNewPost?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling new_post event: $e');
      }
    });

    _socket!.on('post_updated', (data) {
      try {
        log('📝 Post updated: ${data['id']}');
        onPostUpdate?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling post_updated event: $e');
      }
    });

    _socket!.on('post_interaction', (data) {
      try {
        log('❤️ Post interaction: ${data['type']} on ${data['postId']}');
        onPostInteraction?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling post_interaction event: $e');
      }
    });

    _socket!.on('follow_update', (data) {
      try {
        log(
          'yw Follow update: ${data['followerId']} -> ${data['followingId']}',
        );
        onFollowUpdate?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling follow_update event: $e');
      }
    });

    _socket!.on('receive_message', (data) {
      try {
        log('💬 New message received');
        onNewMessage?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling receive_message event: $e');
      }
    });

    _socket!.on('typing', (data) {
      try {
        onTyping?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling typing event: $e');
      }
    });

    _socket!.on('stop_typing', (data) {
      try {
        onStopTyping?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling stop_typing event: $e');
      }
    });

    _socket!.on('notification', (data) {
      try {
        log('🔔 New notification received');
        onNewNotification?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling notification event: $e');
      }
    });

    _socket!.on('notification_update', (data) {
      try {
        log('🔔 Notification updated');
        onNotificationUpdate?.call(Map<String, dynamic>.from(data));
      } catch (e) {
        log('❌ Error handling notification_update event: $e');
      }
    });
  }

  // Emit events to server
  void emitNewPost(Map<String, dynamic> postData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('new_post', postData);
      log('📤 Emitted new post');
    }
  }

  // Deprecated: Remove after migrating all calls to emitPostInteraction
  void emitLikePost(String postId, String userId) {
    emitPostInteraction(postId: postId, type: 'like', userId: userId);
  }

  void emitPostInteraction({
    required String postId,
    required String type, // 'like', 'share', 'save'
    required String userId,
    Map<String, dynamic>? additionalData,
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('post_interaction', {
        'postId': postId,
        'type': type,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        if (additionalData != null) ...additionalData,
      });
      log('📤 Emitted post interaction: $type');
    }
  }

  void emitFollowUpdate({
    required String followerId,
    required String followingId,
    required bool isFollowing, // true = followed, false = unfollowed
  }) {
    if (_isConnected && _socket != null) {
      _socket!.emit('follow_update', {
        'followerId': followerId,
        'followingId': followingId,
        'type': isFollowing ? 'follow' : 'unfollow',
        'timestamp': DateTime.now().toIso8601String(),
      });
      log('📤 Emitted follow update');
    }
  }

  void emitSendMessage(Map<String, dynamic> messageData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('send_message', messageData);
      log('📤 Emitted send message');
    }
  }

  void emitTyping(String chatId, String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing', {'chatId': chatId, 'userId': userId});
    }
  }

  void emitStopTyping(String chatId, String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('stop_typing', {'chatId': chatId, 'userId': userId});
    }
  }

  void emitUserActivityUpdate(Map<String, dynamic> activityData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('user_activity_update', activityData);
    }
  }

  void emitNewNotification(Map<String, dynamic> notificationData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('new_notification', notificationData);
      log('📤 Emitted new notification: ${notificationData['type']}');
    }
  }

  void emitNotificationUpdate(Map<String, dynamic> updateData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('notification_update', updateData);
      log('📤 Emitted notification update: ${updateData['id']}');
    }
  }

  // Messaging events
  void emitNewMessage(Map<String, dynamic> messageData) {
    if (_isConnected && _socket != null) {
      _socket!.emit('new_message', messageData);
      log('📤 Emitted new message to chat: ${messageData['chatId']}');
    }
  }

  void emitMessageDelivered(String messageId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('message_delivered', {'messageId': messageId});
      log('📤 Emitted message delivered: $messageId');
    }
  }

  void emitMessageRead(String messageId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('message_read', {'messageId': messageId});
      log('📤 Emitted message read: $messageId');
    }
  }

  void emitChatRead(String chatId, String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat_read', {'chatId': chatId, 'userId': userId});
      log('📤 Emitted chat read: $chatId');
    }
  }

  void emitTypingStatus(String chatId, String userId, bool isTyping) {
    if (_isConnected && _socket != null) {
      _socket!.emit('typing_status', {
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
      });
    }
  }

  void emitMessageDeleted(String messageId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('message_deleted', {'messageId': messageId});
      log('📤 Emitted message deleted: $messageId');
    }
  }

  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _currentUserId = null;
    _jwtToken = null;
    log('🔌 Socket disconnected and cleaned up');
  }

  // Reconnect socket
  Future<void> reconnect() async {
    if (_currentUserId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await connectWithFirebaseUser(user);
      }
    }
  }
}

// Custom exception for socket errors
class SocketException implements Exception {
  final String message;
  SocketException(this.message);

  @override
  String toString() => 'SocketException: $message';
}
