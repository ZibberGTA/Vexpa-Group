import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/config/app_config.dart';
import 'package:nightlife_app/core/config/app_secrets.dart';

void main() {
  test('AppSecrets exposes local routes key constant', () {
    expect(AppSecrets.localRoutesApiKey, isA<String>());
  });

  test('AppConfig.routesApiKey prefers dart-define over local file', () {
    // Unit tests compile without GOOGLE_ROUTES_API_KEY.
    expect(AppConfig.googleRoutesApiKey, isEmpty);
    final local = AppSecrets.localRoutesApiKey.trim();
    if (local.isEmpty) {
      expect(AppConfig.routesApiKey, isEmpty);
    } else {
      expect(AppConfig.routesApiKey, local);
    }
  });

  test('AppConfig.hasRoutesApiKey reflects routesApiKey presence', () {
    expect(AppConfig.hasRoutesApiKey, AppConfig.routesApiKey.isNotEmpty);
  });
}
