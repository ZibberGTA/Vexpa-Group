/// Google Maps web setup for the Vexda search page.
///
/// The key below is loaded by [web/index.html] for the Maps JavaScript API.
/// It matches the Vexda mobile Android Maps SDK key in
/// `nightlife_app/android/app/src/main/AndroidManifest.xml`.
///
/// If the browser shows "Sorry! Something went wrong" or
/// `ApiNotActivatedMapError`, enable **Maps JavaScript API** for GCP project
/// `nightlife-app-19acd` and ensure billing is active:
/// https://console.cloud.google.com/google/maps-apis/api-list?project=nightlife-app-19acd
///
/// Development referrer restrictions (HTTP referrers on the key):
/// - `http://localhost:*`
/// - `http://127.0.0.1:*`
///
/// Add your production domain before release, e.g. `https://vexda.com/*`.
class GoogleMapsWebConfig {
  GoogleMapsWebConfig._();

  static const String apiKey = 'AIzaSyAFWa2Zluet2Hon97PZS0k6lhmynjqSQM8';
  static const String gcpProjectId = 'nightlife-app-19acd';

  static const String mapsJavaScriptApiEnableUrl =
      'https://console.cloud.google.com/marketplace/product/google/maps-javascript-api.googleapis.com'
      '?project=$gcpProjectId';

  static const String apiCredentialsUrl =
      'https://console.cloud.google.com/google/maps-apis/credentials'
      '?project=$gcpProjectId';

  static const String setupHint =
      'Enable Maps JavaScript API for project $gcpProjectId, confirm billing '
      'is active, and allow http://localhost:* on the browser API key.';
}
