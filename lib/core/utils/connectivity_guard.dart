import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';

import '../providers/connectivity_provider.dart';

/// Mixin to add connectivity guard functionality to any widget
/// Use this to automatically block operations when offline
mixin ConnectivityGuardMixin {
  /// Check if operation should proceed based on connectivity
  /// Returns true if connected, false if blocked
  bool checkConnectivity(
    WidgetRef ref,
    BuildContext context,
    String operation,
  ) {
    final guard = ref.read(connectivityGuardProvider.notifier);

    if (guard.shouldBlockOperation(operation)) {
      _showNoConnectionSnackbar(context);
      return false;
    }

    return true;
  }

  void _showNoConnectionSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.wifi_off_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('No internet connection. Please check your network.'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Extension on WidgetRef for easy connectivity checks
extension ConnectivityGuardExtension on WidgetRef {
  /// Check if connected before performing operation
  bool requiresConnection(BuildContext context, String operation) {
    final guard = read(connectivityGuardProvider.notifier);

    if (guard.shouldBlockOperation(operation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('No internet connection')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  /// Get current connection status
  bool get isConnected {
    return watch(isConnectedProvider);
  }
}

/// Wrapper for async operations that require connectivity
class ConnectivityGuardedOperation<T> {
  final WidgetRef ref;
  final BuildContext context;
  final String operationName;
  final Future<T> Function() operation;

  ConnectivityGuardedOperation({
    required this.ref,
    required this.context,
    required this.operationName,
    required this.operation,
  });

  /// Execute the operation with connectivity guard
  Future<T?> execute() async {
    final guard = ref.read(connectivityGuardProvider.notifier);

    // Check connectivity before operation
    if (guard.shouldBlockOperation(operationName)) {
      log('🚫 ConnectivityGuard: Blocked $operationName');
      _showError('No internet connection. Please check your network.');
      return null;
    }

    try {
      log('✅ ConnectivityGuard: Executing $operationName');
      final result = await operation();
      return result;
    } catch (e) {
      log('❌ ConnectivityGuard: $operationName failed: $e');

      // Check if error is network-related
      if (_isNetworkError(e)) {
        guard.recordFailedOperation(operationName, e.toString());
        _showError('Network error. Please check your connection.');
      } else {
        _showError('Operation failed: ${e.toString()}');
      }

      rethrow;
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable');
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Decorator for functions that require connectivity
Future<T?> withConnectivityGuard<T>({
  required WidgetRef ref,
  required BuildContext context,
  required String operation,
  required Future<T> Function() action,
}) async {
  return ConnectivityGuardedOperation<T>(
    ref: ref,
    context: context,
    operationName: operation,
    operation: action,
  ).execute();
}
