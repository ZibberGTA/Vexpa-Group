import 'dart:js_interop';

/// Reads Maps load errors set by [web/index.html] on Flutter Web.
@JS('vexdaMapsLoadState')
extension type _GoogleMapsLoadStateJs._(JSObject _) {
  external String? get error;
  external String? get errorDetail;
}

@JS('vexdaMapsLoadState')
external _GoogleMapsLoadStateJs? get _vexdaMapsLoadState;

class GoogleMapsLoadState {
  GoogleMapsLoadState._();

  static String? get error => _vexdaMapsLoadState?.error;
  static String? get errorDetail => _vexdaMapsLoadState?.errorDetail;
}
