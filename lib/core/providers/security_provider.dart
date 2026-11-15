import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/security_service.dart';

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final securityService = ref.watch(securityServiceProvider);
  return AppLockNotifier(securityService);
});

class AppLockState {
  final bool isLocked;
  final bool isEnabled;
  final bool hasPin;
  final int lockTimeout; // In minutes
  final DateTime? lastPausedAt;
  final bool is2FAEnabled;
  final List<Map<String, dynamic>> securityLogs;

  AppLockState({
    required this.isLocked,
    required this.isEnabled,
    required this.hasPin,
    this.lockTimeout = 0,
    this.lastPausedAt,
    this.is2FAEnabled = false,
    this.securityLogs = const [],
  });

  AppLockState copyWith({
    bool? isLocked,
    bool? isEnabled,
    bool? hasPin,
    int? lockTimeout,
    DateTime? lastPausedAt,
    bool? is2FAEnabled,
    List<Map<String, dynamic>>? securityLogs,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isEnabled: isEnabled ?? this.isEnabled,
      hasPin: hasPin ?? this.hasPin,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      lastPausedAt: lastPausedAt ?? this.lastPausedAt,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      securityLogs: securityLogs ?? this.securityLogs,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final SecurityService _securityService;

  AppLockNotifier(this._securityService)
      : super(AppLockState(isLocked: false, isEnabled: false, hasPin: false)) {
    _init();
  }

  Future<void> _init() async {
    final isEnabled = await _securityService.isAppLockEnabled();
    final pin = await _securityService.getPin();
    final timeout = await _securityService.getLockTimeout();
    final is2FA = await _securityService.is2FAEnabled();
    final logs = await _securityService.getSecurityEvents();
    
    state = state.copyWith(
      isEnabled: isEnabled,
      hasPin: pin != null,
      lockTimeout: timeout,
      isLocked: isEnabled, // Lock initially if enabled
      is2FAEnabled: is2FA,
      securityLogs: logs,
    );
  }
  
  Future<void> refreshLogs() async {
    final logs = await _securityService.getSecurityEvents();
    state = state.copyWith(securityLogs: logs);
  }

  void unlock() {
    state = state.copyWith(isLocked: false, lastPausedAt: null);
  }

  void recordPause() {
    if (state.isEnabled) {
      state = state.copyWith(lastPausedAt: DateTime.now());
    }
  }

  void lock() {
    if (!state.isEnabled) return;

    // If timeout is 0 (immediate) or lastPausedAt is null (first time), lock it
    if (state.lockTimeout == 0 || state.lastPausedAt == null) {
      state = state.copyWith(isLocked: true);
      return;
    }

    // Check if enough time has passed
    final diff = DateTime.now().difference(state.lastPausedAt!);
    if (diff.inMinutes >= state.lockTimeout) {
      state = state.copyWith(isLocked: true);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _securityService.setAppLockEnabled(enabled);
    final logs = await _securityService.getSecurityEvents();
    state = state.copyWith(isEnabled: enabled, securityLogs: logs);
  }
  
  Future<void> set2FA(bool enabled) async {
    await _securityService.set2FAEnabled(enabled);
    final logs = await _securityService.getSecurityEvents();
    state = state.copyWith(is2FAEnabled: enabled, securityLogs: logs);
  }

  Future<void> setLockTimeout(int minutes) async {
    await _securityService.setLockTimeout(minutes);
    final logs = await _securityService.getSecurityEvents();
    state = state.copyWith(lockTimeout: minutes, securityLogs: logs);
  }

  Future<void> setPin(String pin) async {
    await _securityService.savePin(pin);
    final logs = await _securityService.getSecurityEvents();
    state = state.copyWith(hasPin: true, securityLogs: logs);
  }
  
  Future<bool> verifyPin(String pin) async {
    final isValid = await _securityService.verifyPin(pin);
    if (isValid) {
      unlock();
    }
    return isValid;
  }
}
