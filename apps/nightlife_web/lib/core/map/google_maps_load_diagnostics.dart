import '../constants/google_maps_web_config.dart';

/// User-facing and developer diagnostics for Google Maps web load failures.
class GoogleMapsLoadDiagnostics {
  GoogleMapsLoadDiagnostics._();

  static const String userTitle = 'Map temporarily unavailable';

  static const String userMessage =
      "We're having trouble loading the map right now. "
      'Please refresh the page or try again shortly.';

  /// Maps [GoogleMapsLoadState.errorCode] values to internal diagnostic labels.
  static String describeCode(String? code) {
    switch (code) {
      case 'missing_api_key':
        return 'Browser Maps API key is not configured';
      case 'missing_map_id':
        return 'Cloud Vector Map ID is not configured';
      case 'invalid_api_key':
        return 'Browser Maps API key is invalid';
      case 'auth_failure':
        return 'Maps JavaScript API authentication failed';
      case 'referrer_denied':
        return 'HTTP referrer restriction blocked this origin';
      case 'api_disabled':
        return 'Maps JavaScript API is disabled for the GCP project';
      case 'billing_failure':
        return 'Maps JavaScript API billing is not enabled';
      case 'request_denied':
        return 'Maps JavaScript API request denied';
      case 'network_failure':
        return 'Maps JavaScript API script download failed';
      case 'maps_api_error':
        return 'Maps JavaScript API returned an error';
      default:
        return code ?? 'unknown_maps_load_failure';
    }
  }

  /// Console-only guidance for developers (never shown in production UI).
  static String developerHint({
    required String? errorCode,
    String? error,
    String? errorDetail,
  }) {
    final buffer = StringBuffer()
      ..writeln('[Vexda Maps diagnostics]')
      ..writeln('code: ${errorCode ?? 'unknown'}')
      ..writeln('summary: ${describeCode(errorCode)}');

    if (error != null && error.isNotEmpty) {
      buffer.writeln('runtime: $error');
    }
    if (errorDetail != null && errorDetail.isNotEmpty) {
      buffer.writeln('detail: $errorDetail');
    }

    buffer
      ..writeln('gcpProjectId: ${GoogleMapsWebConfig.gcpProjectId}')
      ..writeln('setup: ${GoogleMapsWebConfig.setupHint}')
      ..writeln('enableApi: ${GoogleMapsWebConfig.mapsJavaScriptApiEnableUrl}')
      ..writeln('credentials: ${GoogleMapsWebConfig.apiCredentialsUrl}');

    return buffer.toString().trimRight();
  }
}
