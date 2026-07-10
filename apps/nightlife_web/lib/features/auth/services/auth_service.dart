import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/signup_account_type.dart';
import 'user_role_service.dart';

/// Firebase Authentication entry point for Vexda Web.
///
/// All sign-in, sign-out, and session persistence go through [FirebaseAuth.instance].
/// Firestore role checks happen in [UserRoleService] after the user is authenticated.
class AuthService {
  AuthService._();

  static FirebaseAuth? get _auth {
    if (!VexdaFirebase.isReady) return null;
    return FirebaseAuth.instance;
  }

  static bool get isAvailable => _auth != null;

  /// Currently signed-in Firebase user, or null when logged out.
  static User? get currentUser => _auth?.currentUser;

  /// Emits whenever the Firebase Auth session changes (login, logout, refresh).
  /// Web sessions persist across browser refresh via Firebase Auth persistence.
  static Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    return auth.authStateChanges();
  }

  static void _requireAuth() {
    if (_auth == null) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not initialised. Please refresh and try again.',
      );
    }
  }

  /// Signs in with email and password using the shared Firebase project.
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    _requireAuth();
    final credential = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _recordSuccessfulLogin(credential.user);
  }

  /// Creates a Firebase Auth account and the matching `users/{uid}` profile.
  static Future<User> register({
    required String displayName,
    required String email,
    required String password,
    required SignupAccountType accountType,
  }) async {
    _requireAuth();

    final trimmedName = displayName.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Enter your full name.',
      );
    }
    if (!_isAllowedSignupAccountType(accountType)) {
      throw FirebaseAuthException(
        code: 'invalid-account-type',
        message: 'That account type is not available for self-service signup.',
      );
    }

    final credential = await _auth!.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password.trim(),
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Account could not be created. Please try again.',
      );
    }

    await user.updateDisplayName(trimmedName);

    if (!VexdaFirebase.isReady) return user;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': trimmedName,
        'name': trimmedName,
        'email': trimmedEmail,
        'role': accountType.firestoreRole,
        'accountType': accountType.firestoreAccountType,
        'status': 'active',
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      try {
        await user.delete();
      } on Object {
        // Best-effort cleanup if profile write fails.
      }
      rethrow;
    }

    await UserRoleService.clearSessionCache();
    return user;
  }

  /// Sends a Firebase password reset email.
  static Future<void> sendPasswordResetEmail({required String email}) async {
    _requireAuth();
    await _auth!.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  static bool _isAllowedSignupAccountType(SignupAccountType accountType) {
    return accountType == SignupAccountType.venueOwner ||
        accountType == SignupAccountType.customer;
  }

  /// Best-effort Firestore login audit — never blocks auth success.
  static Future<void> _recordSuccessfulLogin(User? user) async {
    if (user == null || !VexdaFirebase.isReady) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastLoginPlatform': _currentLoginPlatform(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // Login must succeed even when profile audit write is denied or offline.
    }
  }

  static String _currentLoginPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  /// Ends the current Firebase Auth session.
  static Future<void> logout() async {
    if (_auth == null) return;
    await _auth!.signOut();
    await UserRoleService.clearSessionCache();
  }

  /// Best-effort display name from Firebase Auth profile or email local-part.
  static String getDisplayName(User? user) {
    if (user == null) return 'Account';

    final firebaseName = user.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Account';
  }

  /// First name from display name, or null when unavailable.
  static String? getFirstName(User? user) {
    final displayName = getDisplayName(user);
    if (displayName == 'Account') return null;

    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return null;

    return parts.first;
  }

  /// Maps [FirebaseAuthException] codes to user-friendly copy.
  static String messageForAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'firebase-unavailable':
        return error.message ?? 'Firebase is unavailable.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in instead.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'invalid-display-name':
      case 'invalid-account-type':
        return error.message ?? 'Registration could not be completed.';
      default:
        return error.message ?? 'Login failed. Please try again.';
    }
  }
}
