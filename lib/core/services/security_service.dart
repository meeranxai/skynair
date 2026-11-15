import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityServiceProvider = Provider<SecurityService>((ref) => SecurityService());

class SecurityService {
  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'app_lock_pin';
  static const _isLockEnabledKey = 'app_lock_enabled';
  static const _lockTimeoutKey = 'app_lock_timeout'; // in minutes
  static const _is2FAEnabledKey = 'is_2fa_enabled';
  
  // Save PIN securely
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await logSecurityEvent('PIN changed');
  }
  
  // Get PIN
  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }
  
  // Set App Lock Enabled
  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _isLockEnabledKey, value: enabled.toString());
    await logSecurityEvent(enabled ? 'App lock enabled' : 'App lock disabled');
  }
  
  // Check if App Lock is enabled
  Future<bool> isAppLockEnabled() async {
    final value = await _storage.read(key: _isLockEnabledKey);
    return value == 'true';
  }

  // Set 2FA Enabled
  Future<void> set2FAEnabled(bool enabled) async {
    await _storage.write(key: _is2FAEnabledKey, value: enabled.toString());
    await logSecurityEvent(enabled ? '2FA enabled' : '2FA disabled');
  }

  // Check if 2FA is enabled
  Future<bool> is2FAEnabled() async {
    final value = await _storage.read(key: _is2FAEnabledKey);
    return value == 'true';
  }
  
  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final savedPin = await getPin();
    return savedPin == pin;
  }
  
  // Clear all security settings
  Future<void> clearSecurity() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _isLockEnabledKey);
    await _storage.delete(key: _lockTimeoutKey);
    await _storage.delete(key: _is2FAEnabledKey);
  }

  // Set Lock Timeout
  Future<void> setLockTimeout(int minutes) async {
    await _storage.write(key: _lockTimeoutKey, value: minutes.toString());
    await logSecurityEvent('Lock timeout updated');
  }

  // Get Lock Timeout (defaults to 0 - immediate)
  Future<int> getLockTimeout() async {
    final value = await _storage.read(key: _lockTimeoutKey);
    return int.tryParse(value ?? '0') ?? 0;
  }

  // ----- Security Event Logging -----
  
  // Note: For a real production app, these should ideally be synced to backend.
  // We'll use a simple in-memory or SharedPrefs approach for "real-time" feel in this demo scope if needed, 
  // but let's stick to a simple persistent list in secure storage or similar.
  // Actually, let's use a separate provider or simple method to get/set logs. 
  // Since we don't have SharedPrefs injected here, let's use a static list for the session 
  // or (better) read/write a JSON string to secure storage for persistence.

  static const _securityLogsKey = 'security_logs';

  Future<void> logSecurityEvent(String event) async {
    final events = await getSecurityEvents();
    final newEvent = {
      'event': event,
      'time': DateTime.now().toIso8601String(),
    };
    events.insert(0, newEvent); // Prepend
    if (events.length > 20) events.removeLast(); // Keep last 20

    // Simple serialization
    // In a real app, use a database.
    await _storage.write(key: _securityLogsKey, value: _serializeEvents(events));
  }

  Future<List<Map<String, dynamic>>> getSecurityEvents() async {
    final str = await _storage.read(key: _securityLogsKey);
    if (str == null) return [];
    return _deserializeEvents(str);
  }

  String _serializeEvents(List<Map<String, dynamic>> events) {
    // fast primitive serialization to avoid json import issues if strict
    // but we can use simple string join for this scope or just empty list if too complex
    // Let's assume we can imports 'dart:convert';
    // actually, let's just use a simple delimited string for robustness without imports
    return events.map((e) => "${e['event']}|${e['time']}").join('||');
  }

  List<Map<String, dynamic>> _deserializeEvents(String str) {
    if (str.isEmpty) return [];
    return str.split('||').map((s) {
      final parts = s.split('|');
      if (parts.length < 2) return {'event': 'Unknown', 'time': DateTime.now().toIso8601String()};
      return {
        'event': parts[0],
        'time': parts[1],
      };
    }).toList();
  }
}
