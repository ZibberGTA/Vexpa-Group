/// Central runtime configuration for DrinkSpot.
///
/// Keep secrets out of source code. Values are read from Flutter's
/// `--dart-define` system, or from IDE run configurations that pass the same
/// values automatically.
///
/// Required for in-app walking routes:
///   GOOGLE_ROUTES_API_KEY
///
/// Optional legacy fallback while migrating older local run configs:
///   GOOGLE_DIRECTIONS_API_KEY
class AppConfig {
  const AppConfig._();

  static const String googleRoutesApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
  );

  static const String googleDirectionsApiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
  );

  static String get routesApiKey {
    final routesKey = googleRoutesApiKey.trim();
    if (routesKey.isNotEmpty) return routesKey;

    final legacyDirectionsKey = googleDirectionsApiKey.trim();
    if (legacyDirectionsKey.isNotEmpty) return legacyDirectionsKey;

    return '';
  }

  static bool get hasRoutesApiKey => routesApiKey.isNotEmpty;
}
