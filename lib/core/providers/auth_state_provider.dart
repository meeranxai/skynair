import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Minimal auth state provider - ONLY for routing decisions
/// This provider emits ONLY on actual login/logout events
/// It does NOT change when user profile data is updated
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  log('🔄 AuthStateProvider: Listening to auth state changes');

  return authService.authStateChanges.map((user) {
    log(
      '🔄 AuthStateProvider: Auth state changed - User: ${user?.email ?? 'null'}',
    );
    return user;
  });
});

/// Simple boolean for routing - stable and predictable
/// This is what the router should watch
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      final isAuth = user != null;
      log('🔄 IsAuthenticatedProvider: $isAuth');
      return isAuth;
    },
    loading: () {
      log('🔄 IsAuthenticatedProvider: loading (false)');
      return false;
    },
    error: (error, stack) {
      log('❌ IsAuthenticatedProvider: error (false) - $error');
      return false;
    },
  );
});

/// Get current Firebase user (for operations that need it)
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Auth actions provider - for login, logout, signup
final authActionsProvider = Provider<AuthActions>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthActions(authService);
});

/// Auth actions class - handles login, logout, signup
class AuthActions {
  final AuthService _authService;

  AuthActions(this._authService);

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      log('🔄 AuthActions: Attempting sign in for $email');
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('✅ AuthActions: Sign in successful');
    } catch (e) {
      log('❌ AuthActions: Sign in failed: $e');
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      log('🔄 AuthActions: Creating user for $email');
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (userCredential?.user != null &&
          !(userCredential?.user?.emailVerified ?? true)) {
        await userCredential?.user?.sendEmailVerification();
        log('✅ AuthActions: Verification email sent to $email');
      }

      log('✅ AuthActions: User created successfully');
      return userCredential;
    } catch (e) {
      log('❌ AuthActions: User creation failed: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      log('🔄 AuthActions: Starting Google Sign In');
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        log('⚠️ AuthActions: Google Sign In canceled');
      } else {
        log(
          '✅ AuthActions: Google Sign In successful for ${result.user?.email}',
        );
      }

      return result;
    } catch (e) {
      log('❌ AuthActions: Google Sign In error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      log('🔄 AuthActions: Signing out');
      await _authService.signOut();
      log('✅ AuthActions: Sign out successful');
    } catch (e) {
      log('❌ AuthActions: Sign out failed: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      log('🔄 AuthActions: Sending password reset email to $email');
      await _authService.sendPasswordResetEmail(email);
      log('✅ AuthActions: Password reset email sent');
    } catch (e) {
      log('❌ AuthActions: Failed to send password reset email: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _authService.currentUser;
      if (user != null && !user.emailVerified) {
        log('🔄 AuthActions: Sending verification email');
        await user.sendEmailVerification();
        log('✅ AuthActions: Verification email sent');
      }
    } catch (e) {
      log('❌ AuthActions: Failed to send verification email: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        log('🔄 AuthActions: Reloading user');
        await user.reload();
        log('✅ AuthActions: User reloaded');
      }
    } catch (e) {
      log('❌ AuthActions: Failed to reload user: $e');
      rethrow;
    }
  }

  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;
}
