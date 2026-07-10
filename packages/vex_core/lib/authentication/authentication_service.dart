import 'authenticated_user.dart';

abstract interface class AuthenticationService {
  Stream<AuthenticatedUser?> get authStateChanges;

  AuthenticatedUser? get currentUser;

  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
