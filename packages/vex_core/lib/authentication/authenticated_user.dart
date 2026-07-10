final class AuthenticatedUser {
  const AuthenticatedUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isEmailVerified = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
}
