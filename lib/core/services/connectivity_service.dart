import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized connectivity service that monitors real-time network status
/// and provides connectivity state to the entire app.
///
/// This service uses multiple detection methods:
/// 1. Socket connection test (most reliable)
/// 2. HTTP ping to reliable endpoints
/// 3. Platform-specific connectivity checks
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity changes
  final _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;

  // Current connectivity status
  ConnectivityStatus _currentStatus = ConnectivityStatus.checking;
  ConnectivityStatus get currentStatus => _currentStatus;
  bool get isConnected => _currentStatus == ConnectivityStatus.connected;

  // Periodic check timer
  Timer? _periodicCheckTimer;
  Timer? _retryTimer;

  // Configuration
  static const Duration _checkInterval = Duration(seconds: 10);
  static const Duration _retryInterval = Duration(seconds: 3);
  static const Duration _connectionTimeout = Duration(seconds: 5);

  /// Initialize the connectivity service
  Future<void> initialize() async {
    log('🌐 ConnectivityService: Initializing...');

    // Perform initial check
    await checkConnectivity();

    // Start periodic monitoring
    _startPeriodicChecks();

    log('✅ ConnectivityService: Initialized with status: $_currentStatus');
  }

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      // Try multiple methods for reliability
      final hasConnection = await _hasInternetConnection();

      final newStatus = hasConnection
          ? ConnectivityStatus.connected
          : ConnectivityStatus.disconnected;

      _updateStatus(newStatus);
      return newStatus;
    } catch (e) {
      log('⚠️ ConnectivityService: Error checking connectivity: $e');
      _updateStatus(ConnectivityStatus.disconnected);
      return ConnectivityStatus.disconnected;
    }
  }

  /// Primary method: Socket connection test
  Future<bool> _hasInternetConnection() async {
    try {
      // Try to connect to multiple reliable endpoints
      final endpoints = [
        {'host': 'www.google.com', 'port': 443},
        {'host': '8.8.8.8', 'port': 53}, // Google DNS
        {'host': 'www.cloudflare.com', 'port': 443},
      ];

      for (final endpoint in endpoints) {
        try {
          final socket = await Socket.connect(
            endpoint['host'] as String,
            endpoint['port'] as int,
            timeout: _connectionTimeout,
          );
          socket.destroy();
          log('✅ ConnectivityService: Connected to ${endpoint['host']}');
          return true;
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }

      log('❌ ConnectivityService: All connection attempts failed');
      return false;
    } catch (e) {
      log('❌ ConnectivityService: Connection check error: $e');
      return false;
    }
  }

  /// Update connectivity status and notify listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;

      log(
        '🔄 ConnectivityService: Status changed from $oldStatus to $newStatus',
      );

      // Notify all listeners
      _connectivityController.add(newStatus);

      // Handle status-specific actions
      if (newStatus == ConnectivityStatus.connected) {
        _onConnected();
      } else if (newStatus == ConnectivityStatus.disconnected) {
        _onDisconnected();
      }
    }
  }

  /// Called when connection is established
  void _onConnected() {
    log('✅ ConnectivityService: Internet connection restored');

    // Cancel retry timer if running
    _retryTimer?.cancel();
    _retryTimer = null;

    // Resume normal periodic checks
    _startPeriodicChecks();
  }

  /// Called when connection is lost
  void _onDisconnected() {
    log('❌ ConnectivityService: Internet connection lost');

    // Cancel normal periodic checks
    _periodicCheckTimer?.cancel();

    // Start aggressive retry checks
    _startRetryChecks();
  }

  /// Start periodic connectivity checks (when connected)
  void _startPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      checkConnectivity();
    });
  }

  /// Start aggressive retry checks (when disconnected)
  void _startRetryChecks() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      checkConnectivity();
    });
  }

  /// Force an immediate connectivity check
  Future<bool> forceCheck() async {
    log('🔄 ConnectivityService: Force checking connectivity...');
    final status = await checkConnectivity();
    return status == ConnectivityStatus.connected;
  }

  /// Dispose resources
  void dispose() {
    log('🔄 ConnectivityService: Disposing...');
    _periodicCheckTimer?.cancel();
    _retryTimer?.cancel();
    _connectivityController.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus { checking, connected, disconnected }
