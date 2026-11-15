import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/socket_service.dart';
import '../services/user_migration_service.dart';
import 'auth_state_provider.dart';

/// User profile state - separate from auth state
/// This can change frequently without affecting routing
class UserProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  UserProfileState({this.user, this.isLoading = false, this.error});

  UserProfileState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return UserProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User profile provider - manages user data separately from auth state
/// Updates to this provider DO NOT trigger router rebuilds
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final authState = ref.watch(authStateProvider);
      return UserProfileNotifier(authState.value, ref);
    });

class UserProfileNotifier extends StateNotifier<UserProfileState>
    with WidgetsBindingObserver {
  final Ref _ref;
  User? _firebaseUser;

  UserProfileNotifier(User? firebaseUser, this._ref)
    : super(UserProfileState(isLoading: firebaseUser != null)) {
    _firebaseUser = firebaseUser;

    if (firebaseUser != null) {
      log('🔄 UserProfileProvider: Loading profile for ${firebaseUser.email}');
      _loadProfile(firebaseUser);
    } else {
      log('ℹ️ UserProfileProvider: No user, setting to not loading');
      state = UserProfileState(isLoading: false);
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    final currentUser = state.user;
    if (currentUser == null) return;

    switch (lifecycleState) {
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

  Future<void> _loadProfile(User firebaseUser) async {
    try {
      log(
        '🔄 UserProfileProvider: Loading user profile for ${firebaseUser.email}',
      );
      state = state.copyWith(isLoading: true, error: null);

      // Try to get user profile from Firestore with timeout
      UserModel? userProfile;

      try {
        userProfile = await FirestoreService.getUserProfile(firebaseUser.uid)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                log('⚠️ UserProfileProvider: Firestore getUserProfile timeout');
                return null;
              },
            );
        log(
          'ℹ️ UserProfileProvider: Firestore query result: ${userProfile != null ? 'found' : 'not found'}',
        );
      } catch (firestoreError) {
        log('⚠️ UserProfileProvider: Firestore access failed: $firestoreError');
      }

      // Create profile if it doesn't exist
      if (userProfile == null) {
        log('🔄 UserProfileProvider: Creating new user profile');

        final baseUsername = firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : firebaseUser.email?.split('@').first ?? 'user';

        String uniqueUsername;
        try {
          uniqueUsername =
              await FirestoreService.generateUniqueUsername(
                baseUsername,
              ).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  log('⚠️ UserProfileProvider: Username generation timeout');
                  return _generateUsername(firebaseUser.email ?? '');
                },
              );
          log(
            '✅ UserProfileProvider: Generated unique username: $uniqueUsername',
          );
        } catch (e) {
          log('⚠️ UserProfileProvider: Failed to generate username: $e');
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

        // Try to save to Firestore
        try {
          await FirestoreService.createUserProfile(userProfile).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              log(
                '⚠️ UserProfileProvider: Firestore createUserProfile timeout',
              );
              throw Exception('Firestore save timeout');
            },
          );
          log('✅ UserProfileProvider: User profile saved to Firestore');
        } catch (firestoreError) {
          log(
            '⚠️ UserProfileProvider: Failed to save to Firestore (continuing): $firestoreError',
          );
        }
      }

      // Set the user profile
      state = UserProfileState(user: userProfile, isLoading: false);
      log('✅ UserProfileProvider: User profile loaded successfully');

      // Connect socket
      _connectSocket(firebaseUser);
      _updateOnlineStatus(true);

      // Fix missing follow counts in background
      UserMigrationService.fixMissingFollowCounts(firebaseUser.uid)
          .then((_) {
            log('✅ UserProfileProvider: Follow counts verified/fixed');
          })
          .catchError((e) {
            log('⚠️ UserProfileProvider: Failed to fix follow counts: $e');
          });
    } catch (e) {
      log('❌ UserProfileProvider: Critical error in _loadProfile: $e');

      // Create fallback profile
      final fallbackUsername = _generateUsername(firebaseUser.email ?? '');

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

      state = UserProfileState(user: fallbackProfile, isLoading: false);
      log('✅ UserProfileProvider: Using fallback profile');
    }
  }

  Future<void> _connectSocket(User firebaseUser) async {
    try {
      log('🔄 UserProfileProvider: Attempting socket connection...');
      await SocketService().connectWithFirebaseUser(firebaseUser);
      log('✅ UserProfileProvider: Socket connected successfully');
    } catch (e) {
      log('⚠️ UserProfileProvider: Socket connection failed: $e');
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = state.user;
    if (user != null) {
      try {
        log('🔄 UserProfileProvider: Updating online status to $isOnline');
        await FirestoreService.updateUserOnlineStatus(user.uid, isOnline);
        log('✅ UserProfileProvider: Online status updated');
      } catch (e) {
        log('⚠️ UserProfileProvider: Failed to update online status: $e');
      }
    }
  }

  String _generateUsername(String email) {
    final username = email.split('@').first.toLowerCase();
    return username.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Update user profile - THIS DOES NOT AFFECT ROUTING
  /// Only updates the user profile state, not auth state
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? username,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      log('⚠️ UserProfileProvider: Cannot update profile - no user');
      return;
    }

    try {
      log('🔄 UserProfileProvider: Updating profile for ${currentUser.uid}');

      // Update Firebase Auth profile if needed
      if (displayName != null || photoURL != null) {
        final firebaseUser = _firebaseUser;
        if (firebaseUser != null) {
          await firebaseUser.updateDisplayName(displayName);
          if (photoURL != null) {
            await firebaseUser.updatePhotoURL(photoURL);
          }
          log('✅ UserProfileProvider: Firebase Auth profile updated');
        }
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
        await FirestoreService.updateUserProfile(currentUser.uid, updateData);
        log('✅ UserProfileProvider: Firestore profile updated');

        // Update local state - NO ROUTER REBUILD
        state = state.copyWith(
          user: currentUser.copyWith(
            displayName: displayName ?? currentUser.displayName,
            photoURL: finalPhotoURL ?? currentUser.photoURL,
            bio: bio ?? currentUser.bio,
            username: username ?? currentUser.username,
            updatedAt: DateTime.now(),
          ),
        );

        log('✅ UserProfileProvider: Local state updated - NO APP RESTART');
      }
    } catch (e) {
      log('❌ UserProfileProvider: Update failed: $e');
      rethrow;
    }
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> data) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    try {
      await FirestoreService.updateUserProfile(currentUser.uid, data);

      state = state.copyWith(
        user: currentUser.copyWith(
          isPrivate: data['isPrivate'] ?? currentUser.isPrivate,
          showLastSeen: data['showLastSeen'] ?? currentUser.showLastSeen,
          showOnlineStatus: data['showOnlineStatus'] ?? currentUser.showOnlineStatus,
          allowReadReceipts: data['allowReadReceipts'] ?? currentUser.allowReadReceipts,
          whoCanMessage: data['whoCanMessage'] ?? currentUser.whoCanMessage,
          whoCanMention: data['whoCanMention'] ?? currentUser.whoCanMention,
          allowStorySharing: data['allowStorySharing'] ?? currentUser.allowStorySharing,
        ),
      );
    } catch (e) {
      log('❌ UserProfileProvider: Privacy update failed: $e');
      rethrow;
    }
  }

  /// Refresh profile from Firestore
  Future<void> refreshProfile() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    try {
      log('🔄 UserProfileProvider: Refreshing profile from Firestore');
      final profile = await FirestoreService.getUserProfile(currentUser.uid);
      if (profile != null) {
        state = state.copyWith(user: profile);
        log('✅ UserProfileProvider: Profile refreshed');
      }
    } catch (e) {
      log('⚠️ UserProfileProvider: Failed to refresh profile: $e');
    }
  }

  /// Update user's post count in real-time
  void updateUserPostCount(int newCount) {
    final currentUser = state.user;
    if (currentUser != null) {
      log('🔄 UserProfileProvider: Updating post count to $newCount');
      state = state.copyWith(
        user: currentUser.copyWith(
          postsCount: newCount,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Refresh user post count from Firestore
  Future<void> refreshUserPostCount() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    try {
      final userProfile = await FirestoreService.getUserProfile(
        currentUser.uid,
      );
      if (userProfile != null &&
          userProfile.postsCount != currentUser.postsCount) {
        state = state.copyWith(
          user: currentUser.copyWith(
            postsCount: userProfile.postsCount,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Silently handle error
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
