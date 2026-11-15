import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';

import '../services/connectivity_service.dart';

/// Provider for connectivity service instance
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for current connectivity status
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// Provider for simple boolean connectivity check
final isConnectedProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);

  return connectivityAsync.when(
    data: (status) => status == ConnectivityStatus.connected,
    loading: () => true, // Assume connected while checking
    error: (_, __) => false,
  );
});

/// State notifier for managing connectivity-dependent operations
class ConnectivityGuardNotifier extends StateNotifier<ConnectivityGuardState> {
  final ConnectivityService _connectivityService;

  ConnectivityGuardNotifier(this._connectivityService)
    : super(ConnectivityGuardState.initial()) {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      state = state.copyWith(
        status: status,
        isBlocked: status != ConnectivityStatus.connected,
      );

      if (status == ConnectivityStatus.connected) {
        _onConnectionRestored();
      }
    });
  }

  void _onConnectionRestored() {
    log(
      '✅ ConnectivityGuard: Connection restored, clearing pending operations',
    );

    // Clear any error states
    state = state.copyWith(lastError: null, retryCount: 0);
  }

  /// Check if operation should be blocked
  bool shouldBlockOperation(String operationType) {
    if (!_connectivityService.isConnected) {
      log(
        '🚫 ConnectivityGuard: Blocking $operationType - No internet connection',
      );
      state = state.copyWith(
        lastError: 'No internet connection. Please check your network.',
        blockedOperation: operationType,
      );
      return true;
    }
    return false;
  }

  /// Record a failed operation
  void recordFailedOperation(String operation, String error) {
    log('❌ ConnectivityGuard: Operation failed - $operation: $error');
    state = state.copyWith(
      lastError: error,
      blockedOperation: operation,
      retryCount: state.retryCount + 1,
    );
  }

  /// Force retry connectivity check
  Future<bool> forceRetry() async {
    log('🔄 ConnectivityGuard: Force retrying connection check...');
    state = state.copyWith(status: ConnectivityStatus.checking);

    final isConnected = await _connectivityService.forceCheck();

    if (isConnected) {
      state = state.copyWith(
        status: ConnectivityStatus.connected,
        isBlocked: false,
        lastError: null,
        retryCount: 0,
      );
    } else {
      state = state.copyWith(
        status: ConnectivityStatus.disconnected,
        isBlocked: true,
        retryCount: state.retryCount + 1,
      );
    }

    return isConnected;
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(lastError: null, blockedOperation: null);
  }
}

/// State for connectivity guard
class ConnectivityGuardState {
  final ConnectivityStatus status;
  final bool isBlocked;
  final String? lastError;
  final String? blockedOperation;
  final int retryCount;

  ConnectivityGuardState({
    required this.status,
    required this.isBlocked,
    this.lastError,
    this.blockedOperation,
    this.retryCount = 0,
  });

  factory ConnectivityGuardState.initial() {
    return ConnectivityGuardState(
      status: ConnectivityStatus.checking,
      isBlocked: false,
    );
  }

  ConnectivityGuardState copyWith({
    ConnectivityStatus? status,
    bool? isBlocked,
    String? lastError,
    String? blockedOperation,
    int? retryCount,
  }) {
    return ConnectivityGuardState(
      status: status ?? this.status,
      isBlocked: isBlocked ?? this.isBlocked,
      lastError: lastError,
      blockedOperation: blockedOperation,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Provider for connectivity guard
final connectivityGuardProvider =
    StateNotifierProvider<ConnectivityGuardNotifier, ConnectivityGuardState>((
      ref,
    ) {
      final service = ref.watch(connectivityServiceProvider);
      return ConnectivityGuardNotifier(service);
    });
