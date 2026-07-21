import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../config/development_gate_config.dart';
import '../../features/auth/services/auth_service.dart';

/// User-safe failure categories for preview sign-in.
enum PreviewSignInFailureKind {
  invalidCredential,
  accessNotApproved,
  networkUnavailable,
  browserSession,
  unknown,
}

/// Outcome of a preview sign-in attempt.
class PreviewSignInResult {
  const PreviewSignInResult._({
    required this.success,
    this.failureKind,
    this.userMessage = '',
  });

  const PreviewSignInResult.success()
      : this._(success: true);

  const PreviewSignInResult.failure({
    required PreviewSignInFailureKind failureKind,
    required String userMessage,
  }) : this._(
          success: false,
          failureKind: failureKind,
          userMessage: userMessage,
        );

  final bool success;
  final PreviewSignInFailureKind? failureKind;
  final String userMessage;
}

/// Normalises preview sign-in email: trim whitespace and lowercase.
String normalizePreviewEmail(String raw) {
  return raw.trim().toLowerCase();
}

/// Maps a failure kind to user-safe copy.
String userMessageForPreviewSignInFailure(PreviewSignInFailureKind kind) {
  switch (kind) {
    case PreviewSignInFailureKind.invalidCredential:
      return 'Incorrect email or password.';
    case PreviewSignInFailureKind.accessNotApproved:
      return 'This account does not have preview access.';
    case PreviewSignInFailureKind.networkUnavailable:
      return 'Network unavailable. Check your connection and try again.';
    case PreviewSignInFailureKind.browserSession:
      return 'Your browser could not save the sign-in session. '
          'Try disabling private browsing or allow site storage for vexda.co.uk.';
    case PreviewSignInFailureKind.unknown:
      return 'Sign-in failed. Please try again in a moment.';
  }
}

/// Classifies Firebase and generic errors into preview failure kinds.
PreviewSignInFailureKind classifyPreviewSignInFailure(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'invalid-email':
        return PreviewSignInFailureKind.invalidCredential;
      case 'network-request-failed':
        return PreviewSignInFailureKind.networkUnavailable;
      case 'web-storage-unsupported':
      case 'storage-unsupported':
        return PreviewSignInFailureKind.browserSession;
      default:
        return PreviewSignInFailureKind.unknown;
    }
  }

  final message = error.toString().toLowerCase();
  if (message.contains('network') ||
      message.contains('offline') ||
      message.contains('failed to fetch') ||
      message.contains('connection')) {
    return PreviewSignInFailureKind.networkUnavailable;
  }
  if (message.contains('storage') ||
      message.contains('indexeddb') ||
      message.contains('quota')) {
    return PreviewSignInFailureKind.browserSession;
  }

  return PreviewSignInFailureKind.unknown;
}

/// Dependencies for preview sign-in — overridable in tests.
typedef PreviewSignInWithEmailPassword = Future<UserCredential> Function({
  required String email,
  required String password,
});

typedef PreviewGetCurrentUser = User? Function();

typedef PreviewWaitForAuthUser = Future<User?> Function();

typedef PreviewIsApprovedEmail = bool Function(String? email);

typedef PreviewSignOut = Future<void> Function();

typedef PreviewRecordSuccessfulLogin = Future<void> Function(User? user);

/// Authenticates approved preview accounts through the private-development gate.
class DevelopmentPreviewSignInService {
  DevelopmentPreviewSignInService({
    required PreviewSignInWithEmailPassword signInWithEmailAndPassword,
    required PreviewGetCurrentUser getCurrentUser,
    required PreviewWaitForAuthUser waitForAuthUser,
    required PreviewIsApprovedEmail isApprovedEmail,
    required PreviewSignOut signOut,
    required PreviewRecordSuccessfulLogin recordSuccessfulLogin,
  })  : _signInWithEmailAndPassword = signInWithEmailAndPassword,
        _getCurrentUser = getCurrentUser,
        _waitForAuthUser = waitForAuthUser,
        _isApprovedEmail = isApprovedEmail,
        _signOut = signOut,
        _recordSuccessfulLogin = recordSuccessfulLogin;

  factory DevelopmentPreviewSignInService.production() {
    return DevelopmentPreviewSignInService(
      signInWithEmailAndPassword: ({required String email, required String password}) {
        return AuthService.signInForPreview(email: email, password: password);
      },
      getCurrentUser: () => AuthService.currentUser,
      waitForAuthUser: _waitForProductionAuthUser,
      isApprovedEmail: DevelopmentGateConfig.isApprovedEmail,
      signOut: AuthService.logout,
      recordSuccessfulLogin: AuthService.recordSuccessfulLoginForPreview,
    );
  }

  static DevelopmentPreviewSignInService instance =
      DevelopmentPreviewSignInService.production();

  final PreviewSignInWithEmailPassword _signInWithEmailAndPassword;
  final PreviewGetCurrentUser _getCurrentUser;
  final PreviewWaitForAuthUser _waitForAuthUser;
  final PreviewIsApprovedEmail _isApprovedEmail;
  final PreviewSignOut _signOut;
  final PreviewRecordSuccessfulLogin _recordSuccessfulLogin;

  static Future<User?> _waitForProductionAuthUser() async {
    final immediate = AuthService.currentUser;
    if (immediate != null) return immediate;

    try {
      return await AuthService.authStateChanges
          .where((user) => user != null)
          .map((user) => user!)
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return AuthService.currentUser;
    }
  }

  Future<PreviewSignInResult> signIn({
    required String rawEmail,
    required String rawPassword,
  }) async {
    final email = normalizePreviewEmail(rawEmail);
    final password = rawPassword;

    UserCredential credential;
    try {
      credential = await _signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on Object catch (error) {
      final kind = classifyPreviewSignInFailure(error);
      return PreviewSignInResult.failure(
        failureKind: kind,
        userMessage: userMessageForPreviewSignInFailure(kind),
      );
    }

    final user = credential.user ?? await _waitForAuthUser();
    if (user == null) {
      const kind = PreviewSignInFailureKind.browserSession;
      return PreviewSignInResult.failure(
        failureKind: kind,
        userMessage: userMessageForPreviewSignInFailure(kind),
      );
    }

    if (!_isApprovedEmail(user.email)) {
      try {
        await _signOut();
      } on Object {
        // Deny access safely even when sign-out fails.
      }
      const kind = PreviewSignInFailureKind.accessNotApproved;
      return PreviewSignInResult.failure(
        failureKind: kind,
        userMessage: userMessageForPreviewSignInFailure(kind),
      );
    }

    try {
      await _recordSuccessfulLogin(user);
    } on Object {
      // Login audit must not block preview access.
    }

    if (_getCurrentUser() == null) {
      const kind = PreviewSignInFailureKind.browserSession;
      return PreviewSignInResult.failure(
        failureKind: kind,
        userMessage: userMessageForPreviewSignInFailure(kind),
      );
    }

    return const PreviewSignInResult.success();
  }
}
