import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      if (kIsWeb) {
        _googleSignIn = GoogleSignIn(
          clientId:
              '358032029950-dd16pt5sf8r0u0cen0b9g891pkjfkacn.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
      } else {
        _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      }
    } catch (e) {
      log('❌ Google Sign In initialization failed: $e');
      _googleSignIn = GoogleSignIn();
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      log('🔄 Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('✅ User signed in: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      log('❌ Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('❌ Unexpected sign in error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      log('🔄 Creating account with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('✅ User account created: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      log('❌ Account creation error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('❌ Unexpected account creation error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Get Google Account
  Future<GoogleSignInAccount?> getGoogleAccount() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      log('❌ Google Sign In error: $e');
      return null;
    }
  }

  // Get Firebase Credential from Google Account
  Future<AuthCredential> getFirebaseCredential(GoogleSignInAccount googleUser) async {
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw 'Failed to get Google authentication tokens.';
    }

    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  // Sign in with Firebase Credential
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Sign in with Google (Legacy method kept for compatibility or updated)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      log('🔄 Starting Google Sign In...');
      final GoogleSignInAccount? googleUser = await getGoogleAccount();
      
      if (googleUser == null) {
        log('⚠️ Google Sign In canceled by user');
        return null;
      }

      final credential = await getFirebaseCredential(googleUser);
      final userCredential = await signInWithCredential(credential);
      
      log('✅ User signed in with Google: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('❌ Google sign in Firebase error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('❌ Google sign in error: $e');
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      log('🔄 Signing out...');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut().catchError((e) {
          log('⚠️ Google Sign Out error (ignored): $e');
          return null;
        }),
      ]);
      log('✅ User signed out successfully');
    } catch (e) {
      log('❌ Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      log('🔄 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      log('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      log('❌ Password reset error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('❌ Unexpected password reset error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in.';

      log('🔄 Updating user profile...');
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Reload user to get updated info
      await user.reload();
      log('✅ User profile updated');
    } catch (e) {
      log('❌ Profile update error: $e');
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Get Firebase ID token
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await user.getIdToken();
    } catch (e) {
      log('❌ Get ID token error: $e');
      return null;
    }
  }

  // Check if Google Sign In is available
  bool get isGoogleSignInAvailable => true;

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your login details.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
