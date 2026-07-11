import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_core/vex_core.dart';

import '../../features/auth/services/auth_service.dart';

/// Firebase Auth adapter for VexCore [AuthenticationService].
final class FirebaseAuthenticationAdapter implements AuthenticationService {
  const FirebaseAuthenticationAdapter();

  @override
  Stream<AuthenticatedUser?> get authStateChanges {
    return AuthService.authStateChanges.map(_mapUser);
  }

  @override
  AuthenticatedUser? get currentUser => _mapUser(AuthService.currentUser);

  @override
  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await AuthService.login(email: email, password: password);
    final user = AuthService.currentUser;
    if (user == null) {
      throw StateError('Login succeeded but no Firebase user is available.');
    }
    return _mapUser(user)!;
  }

  @override
  Future<void> signOut() => AuthService.logout();

  AuthenticatedUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthenticatedUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
    );
  }
}
