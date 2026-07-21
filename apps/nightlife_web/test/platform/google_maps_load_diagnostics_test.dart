import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/map/google_maps_load_diagnostics.dart';

void main() {
  test('developerHint includes classified error codes', () {
    final hint = GoogleMapsLoadDiagnostics.developerHint(
      errorCode: 'billing_failure',
      error: 'billing',
      errorDetail: 'Billing disabled',
    );

    expect(hint, contains('billing_failure'));
    expect(hint, contains('Billing disabled'));
    expect(hint, contains('nightlife-app-19acd'));
  });
}
