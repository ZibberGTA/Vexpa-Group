/// Central runtime configuration for Vexda mobile.
library;

/// Google Routes API key precedence:
/// 1. `--dart-define=GOOGLE_ROUTES_API_KEY=...` (CI/release override)
/// 2. Untracked [AppSecrets.localRoutesApiKey] from `app_secrets.local.dart`
/// 3. Empty — in-app routes fail with existing user-facing error handling
///
/// Run `dart run tool/ensure_local_platform_config.dart` once after clone.
/// See docs/platform/API_KEYS_SETUP.md.
import 'app_secrets.dart';

class AppConfig {
  const AppConfig._();

  static const String googleRoutesApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
  );

  static String get routesApiKey {
    final fromDefine = googleRoutesApiKey.trim();
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromLocal = AppSecrets.localRoutesApiKey.trim();
    if (fromLocal.isNotEmpty) return fromLocal;

    return '';
  }

  static bool get hasRoutesApiKey => routesApiKey.isNotEmpty;
}
