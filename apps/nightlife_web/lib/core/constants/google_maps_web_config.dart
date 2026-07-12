/// Google Maps web setup for the Vexda search page.
///
/// The Maps JavaScript API key is loaded from untracked
/// [web/vexda_maps_config.js] (see [web/vexda_maps_config.example.js]).
///
/// If the browser shows "Sorry! Something went wrong" or
/// `ApiNotActivatedMapError`, enable **Maps JavaScript API** for GCP project
/// `nightlife-app-19acd` and ensure billing is active:
/// https://console.cloud.google.com/google/maps-apis/api-list?project=nightlife-app-19acd
///
/// Development referrer restrictions (HTTP referrers on the browser key):
/// - `http://localhost:*`
/// - `http://127.0.0.1:*`
///
/// Production referrers:
/// - `https://vexda.co.uk/*`
/// - `https://www.vexda.co.uk/*`
/// - Firebase Hosting domains for project `nightlife-app-19acd`
class GoogleMapsWebConfig {
  GoogleMapsWebConfig._();

  static const String gcpProjectId = 'nightlife-app-19acd';

  static const String mapsJavaScriptApiEnableUrl =
      'https://console.cloud.google.com/marketplace/product/google/maps-javascript-api.googleapis.com'
      '?project=$gcpProjectId';

  static const String apiCredentialsUrl =
      'https://console.cloud.google.com/google/maps-apis/credentials'
      '?project=$gcpProjectId';

  static const String setupHint =
      'Copy web/vexda_maps_config.example.js to web/vexda_maps_config.js and '
      'set your Maps JavaScript API key. Enable Maps JavaScript API for project '
      '$gcpProjectId, confirm billing is active, and allow localhost and '
      'production referrers on the browser key.';
}
