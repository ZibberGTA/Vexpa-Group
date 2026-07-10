/// Compile-time configuration for the temporary private development gate.
///
/// Enable when deploying a pre-launch build:
/// `flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true`
///
/// Disable for public launch (default when the flag is omitted):
/// `flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=false`
class DevelopmentGateConfig {
  DevelopmentGateConfig._();

  /// When `false`, [DevelopmentGate] is a no-op and the app behaves normally.
  static const bool privateDevelopmentMode = bool.fromEnvironment(
    'PRIVATE_DEVELOPMENT_MODE',
    defaultValue: false,
  );

  /// Firebase Auth emails allowed through the gate while development mode is on.
  ///
  /// This list is compile-time configuration for a temporary preview gate only.
  /// Flutter Web release builds can be inspected in the browser, so treat these
  /// addresses as convenience controls — not confidential secrets.
  static const Set<String> approvedEmails = {
    'jason.cook@gmail.com',
    'albert@random.com',
  };

  static bool isApprovedEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return approvedEmails.contains(email.trim().toLowerCase());
  }
}
