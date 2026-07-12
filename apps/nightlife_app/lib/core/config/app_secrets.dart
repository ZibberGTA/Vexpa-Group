/// Untracked local mobile API secrets.
library;

/// Generated or copied by `dart run tool/ensure_local_platform_config.dart`.
/// See [app_secrets.local.dart.example] and docs/platform/API_KEYS_SETUP.md.
import 'app_secrets.local.dart' show kLocalRoutesApiKey;

/// Local platform secrets for Vexda mobile (Routes API, etc.).
abstract final class AppSecrets {
  AppSecrets._();

  /// Routes API key from untracked `app_secrets.local.dart`.
  static const localRoutesApiKey = kLocalRoutesApiKey;
}
