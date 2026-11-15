import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/socket_service.dart';
import '../services/user_migration_service.dart';
import 'security_provider.dart';
import '../services/notification_service.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

class AuthState {
  final User? firebaseUser;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.firebaseUser, this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    User? firebaseUser,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => firebaseUser != null;
  bool get hasProfile => user != null;
}

class AuthNotifier extends StateNotifier<AuthState>
    with WidgetsBindingObserver {
  final AuthService _authService;
  final Ref ref;
  bool _forceProfileCreation = false;

  AuthNotifier(this._authService, this.ref) : super(AuthState(isLoading: true)) {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentUser = this.state.user;
    
    // App Lock logic
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(appLockProvider.notifier).recordPause();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(appLockProvider.notifier).lock();
    }

    if (currentUser == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _updateOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _init() {
    log('🔄 AuthProvider: Initializing...');

    // Check current user immediately
    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      log('✅ AuthProvider: Found existing user: ${currentUser.email}');
      // Set the firebaseUser immediately so isAuthenticated becomes true
      state = state.copyWith(firebaseUser: currentUser, isLoading: true);
      // User is already signed in, load their profile
      _loadUserProfile(currentUser)
          .then((_) {
            log('✅ AuthProvider: User profile loaded');
            _connectSocket(currentUser);
            _updateOnlineStatus(true);
            NotificationService.updateToken(currentUser.uid);
          })
          .catchError((e) {
            log('❌ AuthProvider: Failed to load user profile: $e');
            state = state.copyWith(
              isLoading: false,
              error: 'Failed to load user profile: $e',
            );
          });
    } else {
      log('ℹ️ AuthProvider: No existing user, showing login');
      // No user signed in, set to not loading
      state = AuthState(isLoading: false);
    }

    // Listen to auth state changes with error handling
    _authService.authStateChanges.listen(
      (firebaseUser) async {
        try {
          log(
            '🔄 AuthProvider: Auth state changed - User: ${firebaseUser?.email ?? 'null'}',
          );

          if (firebaseUser != null) {
            // Update firebaseUser immediately in state
            if (state.firebaseUser?.uid != firebaseUser.uid) {
              state = state.copyWith(firebaseUser: firebaseUser, isLoading: true);
              log('🔄 AuthProvider: Loading profile for new user');
              await _loadUserProfile(firebaseUser);
              await _connectSocket(firebaseUser);
              _updateOnlineStatus(true);
              NotificationService.updateToken(firebaseUser.uid);
            } else {
              // Just update the firebaseUser object if it's the same UID (e.g. reload)
              // But ENSURE we stop the loading state if it was triggered by a login call
              state = state.copyWith(firebaseUser: firebaseUser, isLoading: false);
            }
          } else {
            log('ℹ️ AuthProvider: User signed out');
            _disconnectSocket();
            // Set not loading and not authenticated
            state = AuthState(isLoading: false);
          }
        } catch (e) {
          log('❌ AuthProvider: Auth state change error: $e');
          // Handle any errors during initialization
          state = state.copyWith(
            isLoading: false,
            error: 'Authentication initialization failed: $e',
          );
        }
      },
      onError: (error) {
        log('❌ AuthProvider: Auth stream error: $error');
        // Handle stream errors
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication error: $error',
        );
      },
    );

    // Add a timeout to prevent infinite loading (increased to 15 seconds for slow networks)
    Future.delayed(const Duration(seconds: 15), () {
      if (state.isLoading) {
        log('⚠️ AuthProvider: Timeout reached, stopping loading');

        // If we have a Firebase user but no profile, create a minimal one
        final currentFirebaseUser = _authService.currentUser;
        if (currentFirebaseUser != null && state.user == null) {
          log('🔄 AuthProvider: Creating minimal profile due to timeout');

          final fallbackProfile = UserModel(
            uid: currentFirebaseUser.uid,
            email: currentFirebaseUser.email ?? '',
            displayName:
                currentFirebaseUser.displayName ??
                currentFirebaseUser.email?.split('@').first ??
                'User',
            username: _generateUsername(currentFirebaseUser.email ?? ''),
            photoURL: currentFirebaseUser.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          state = state.copyWith(
            firebaseUser: currentFirebaseUser,
            user: fallbackProfile,
            isLoading: false,
            error: null, // Don't show error, just continue
          );

          log('✅ AuthProvider: Using timeout fallback profile');

          // Try to connect socket in background
          _connectSocket(currentFirebaseUser);
          _updateOnlineStatus(true);
        } else {
          state = state.copyWith(
            isLoading: false,
            error:
                'Authentication timeout. Please check your internet connection and try again.',
          );
        }
      }
    });
  }

  Future<void> _loadUserProfile(User firebaseUser) async {
    final shouldCreate = _forceProfileCreation;
    _forceProfileCreation = false; // Reset immediately
    try {
      log('🔄 AuthProvider: Loading user profile for ${firebaseUser.email} (shouldCreate: $shouldCreate)');
      state = state.copyWith(isLoading: true, error: null);

      // Try to get user profile from Firestore with timeout
      UserModel? userProfile;

      try {
        // Add timeout for Firestore operations
        userProfile = await FirestoreService.getUserProfile(firebaseUser.uid)
            .timeout(
              Duration(seconds: 10),
              onTimeout: () {
                log('⚠️ AuthProvider: Firestore getUserProfile timeout');
                return null;
              },
            );
        log(
          'ℹ️ AuthProvider: Firestore query result: ${userProfile != null ? 'found' : 'not found'}',
        );
      } catch (firestoreError) {
        log('⚠️ AuthProvider: Firestore access failed: $firestoreError');
        // Continue with local profile creation if Firestore fails
      }

      // Create profile if it doesn't exist or Firestore failed
      if (userProfile == null) {
        if (!shouldCreate) {
          log('ℹ️ AuthProvider: Profile not found and shouldCreate is false. Skipping auto-creation.');
          state = state.copyWith(isLoading: false, user: null);
          return;
        }
        log('🔄 AuthProvider: Creating new user profile');
        log(
          '📋 AuthProvider: Firebase user data - Name: ${firebaseUser.displayName}, Email: ${firebaseUser.email}, Photo: ${firebaseUser.photoURL}',
        );

        // Generate unique username with timeout
        final baseUsername = firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : firebaseUser.email?.split('@').first ?? 'user';

        String uniqueUsername;
        try {
          uniqueUsername =
              await FirestoreService.generateUniqueUsername(
                baseUsername,
              ).timeout(
                Duration(seconds: 5),
                onTimeout: () {
                  log(
                    '⚠️ AuthProvider: Username generation timeout, using fallback',
                  );
                  return _generateUsername(firebaseUser.email ?? '');
                },
              );
          log('✅ AuthProvider: Generated unique username: $uniqueUsername');
        } catch (e) {
          log(
            '⚠️ AuthProvider: Failed to generate unique username, using fallback: $e',
          );
          uniqueUsername = _generateUsername(firebaseUser.email ?? '');
        }

        userProfile = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName:
              firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ??
              'User',
          username: uniqueUsername,
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Try to save to Firestore with timeout, but don't fail if it doesn't work
        try {
          await FirestoreService.createUserProfile(userProfile).timeout(
            Duration(seconds: 8),
            onTimeout: () {
              log('⚠️ AuthProvider: Firestore createUserProfile timeout');
              throw TimeoutException('Firestore save timeout');
            },
          );
          log('✅ AuthProvider: User profile saved to Firestore');
        } catch (firestoreError) {
          log(
            '⚠️ AuthProvider: Failed to save to Firestore (continuing anyway): $firestoreError',
          );
          // Continue with local profile - don't fail the login
        }
      }

      // Set the user profile regardless of Firestore success
      state = state.copyWith(
        firebaseUser: firebaseUser,
        user: userProfile,
        isLoading: false,
      );

      log('✅ AuthProvider: User profile loaded successfully');

      // Fix missing follow counts in background (non-blocking)
      UserMigrationService.fixMissingFollowCounts(firebaseUser.uid)
          .then((_) {
            log('✅ AuthProvider: Follow counts verified/fixed');
          })
          .catchError((e) {
            log(
              '⚠️ AuthProvider: Failed to fix follow counts (non-critical): $e',
            );
          });
    } catch (e) {
      log('❌ AuthProvider: Critical error in _loadUserProfile: $e');

      // Create a minimal profile to allow login to continue
      log(
        '📋 AuthProvider: Creating fallback profile - Name: ${firebaseUser.displayName}, Email: ${firebaseUser.email}',
      );

      // Generate fallback username
      final baseUsername = firebaseUser.displayName?.isNotEmpty == true
          ? firebaseUser.displayName!
          : firebaseUser.email?.split('@').first ?? 'user';

      String fallbackUsername;
      try {
        fallbackUsername =
            await FirestoreService.generateUniqueUsername(baseUsername).timeout(
              Duration(seconds: 3),
              onTimeout: () => _generateUsername(firebaseUser.email ?? ''),
            );
      } catch (e) {
        fallbackUsername = _generateUsername(firebaseUser.email ?? '');
      }

      final fallbackProfile = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName:
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User',
        username: fallbackUsername,
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        firebaseUser: firebaseUser,
        user: fallbackProfile,
        isLoading: false,
        error: null, // Don't show error, just continue with fallback
      );

      log('✅ AuthProvider: Using fallback profile to continue login');
    }
  }

  Future<void> _connectSocket(User firebaseUser) async {
    try {
      log('🔄 AuthProvider: Attempting socket connection...');
      await SocketService().connectWithFirebaseUser(firebaseUser);
      log('✅ AuthProvider: Socket connected successfully');
    } catch (e) {
      // Socket connection is not critical, just log the error
      log('⚠️ AuthProvider: Socket connection failed (non-critical): $e');
    }
  }

  void _disconnectSocket() {
    SocketService().disconnect();
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = state.user;
    if (user != null) {
      try {
        log('🔄 AuthProvider: Updating online status to $isOnline');
        await FirestoreService.updateUserOnlineStatus(user.uid, isOnline);
        log('✅ AuthProvider: Online status updated');
      } catch (e) {
        log(
          '⚠️ AuthProvider: Failed to update online status (non-critical): $e',
        );
      }
    }
  }

  String _generateUsername(String email) {
    final username = email.split('@').first.toLowerCase();
    return username.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Auth actions
  Future<void> login(String email, String password) =>
      signInWithEmailAndPassword(email, password);

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      log('🔄 AuthProvider: Attempting sign in for $email');
      state = state.copyWith(isLoading: true, error: null);
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('✅ AuthProvider: Sign in call successful');
    } catch (e) {
      log('❌ AuthProvider: Sign in failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (userCredential?.user != null &&
          !(userCredential?.user?.emailVerified ?? true)) {
        await userCredential?.user?.sendEmailVerification();
        log('✅ AuthProvider: Verification email sent to $email');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => state.firebaseUser?.emailVerified ?? false;

  // Send verification email
  Future<void> sendEmailVerification() async {
    try {
      final user = _authService.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        log('✅ AuthProvider: Verification email sent');
      }
    } catch (e) {
      log('❌ AuthProvider: Failed to send verification email: $e');
      rethrow;
    }
  }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _authService.currentUser;
        if (updatedUser != null) {
          state = state.copyWith(firebaseUser: updatedUser);
          log(
            '✅ AuthProvider: User reloaded, emailVerified: ${updatedUser.emailVerified}',
          );
        }
      }
    } catch (e) {
      log('❌ AuthProvider: Failed to reload user: $e');
    }
  }

  Future<void> signInWithGoogle({bool isSignUp = false}) async {
    try {
      log('🔄 AuthProvider: Starting Google Sign In (isSignUp: $isSignUp)');
      state = state.copyWith(isLoading: true, error: null);
      
      // 1. Get Google Account details first
      final googleUser = await _authService.getGoogleAccount();
      
      if (googleUser == null) {
        log('⚠️ AuthProvider: Google Sign In canceled');
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. Proceed with Firebase authentication
      _forceProfileCreation = isSignUp;
      final credential = await _authService.getFirebaseCredential(googleUser);
      final result = await _authService.signInWithCredential(credential);

      // 3. If it's a sign-in attempt (not sign-up), check if the profile exists
      if (!isSignUp && result.user != null) {
        log('🔄 AuthProvider: Checking if profile exists for ${result.user!.uid}');
        final profile = await FirestoreService.getUserProfile(result.user!.uid);
        
        if (profile == null) {
          log('❌ AuthProvider: Profile not found for existing auth user. Aborting sign-in.');
          // Sign out both Firebase and Google
          await _authService.signOut();
          state = state.copyWith(
            isLoading: false, 
            error: 'No Skynaire profile found for this Google account. Please sign up first.'
          );
          return;
        }
      }

      log('✅ AuthProvider: Google Sign In successful for ${result.user?.email}');
      // The auth listener will handle _loadUserProfile which uses _forceProfileCreation
    } catch (e) {
      log('❌ AuthProvider: Google Sign In error: $e');
      _forceProfileCreation = false;
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Check if a user profile already exists in Firestore (for Google login gate)
  Future<bool> checkUserProfileExists(String uid) async {
    try {
      final profile = await FirestoreService.getUserProfile(uid).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      return profile != null;
    } catch (e) {
      log('⚠️ AuthProvider: checkUserProfileExists error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _updateOnlineStatus(false);
      _disconnectSocket();
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Alias for sendPasswordResetEmail
  Future<void> resetPassword(String email) async {
    return sendPasswordResetEmail(email);
  }

  Future<void> deleteAccount(String password) async {
    try {
      final user = state.firebaseUser;
      if (user == null || user.email == null) throw 'No user is currently signed in.';

      state = state.copyWith(isLoading: true, error: null);

      // 1. Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Delete Firestore data
      await FirestoreService.deleteUserData(user.uid);

      // 3. Delete Firebase Auth account
      await user.delete();
      
      log('✅ AuthProvider: Account deleted successfully');
      state = AuthState(isLoading: false);
    } catch (e) {
      log('❌ AuthProvider: Account deletion failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final user = state.user;
      if (user == null) return;

      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await _authService.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }

      // Update Firestore profile
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (bio != null) updateData['bio'] = bio;

      if (updateData.isNotEmpty) {
        await FirestoreService.updateUserProfile(user.uid, updateData);

        // Update local state
        state = state.copyWith(
          user: user.copyWith(
            displayName: displayName ?? user.displayName,
            photoURL: photoURL ?? user.photoURL,
            bio: bio ?? user.bio,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? username,
  }) async {
    try {
      final user = state.user;
      if (user == null) return;

      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await _authService.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }

      // Update Firestore profile
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      
      // Add timestamp to photoURL to bust cache
      String? finalPhotoURL = photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        finalPhotoURL = photoURL.contains('?') 
            ? '$photoURL&t=$timestamp' 
            : '$photoURL?t=$timestamp';
        updateData['photoURL'] = finalPhotoURL;
      }
      
      if (bio != null) updateData['bio'] = bio;
      if (username != null) updateData['username'] = username;

      if (updateData.isNotEmpty) {
        await FirestoreService.updateUserProfile(user.uid, updateData);

        // Update local state
        state = state.copyWith(
          user: user.copyWith(
            displayName: displayName ?? user.displayName,
            photoURL: finalPhotoURL ?? user.photoURL,
            bio: bio ?? user.bio,
            username: username ?? user.username,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Update user's post count in real-time
  void updateUserPostCount(int newCount) {
    final currentUser = state.user;
    if (currentUser != null) {
      state = state.copyWith(
        user: currentUser.copyWith(
          postsCount: newCount,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // Update user's article count in real-time
  void updateUserArticleCount(int newCount) {
    final currentUser = state.user;
    if (currentUser != null) {
      state = state.copyWith(
        user: currentUser.copyWith(
          articlesCount: newCount,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // Refresh user post count from Firestore (for accuracy)
  Future<void> refreshUserPostCount() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    try {
      // Get actual post count from Firestore
      final userProfile = await FirestoreService.getUserProfile(
        currentUser.uid,
      );
      if (userProfile != null) {
        state = state.copyWith(
          user: currentUser.copyWith(
            postsCount: userProfile.postsCount,
            articlesCount: userProfile.articlesCount,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Silently handle error - this is just for sync
    }
  }
}
