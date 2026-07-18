import 'dart:async';
import 'dart:js_interop';

/// Waits for [web/vexda_maps_loader.js] to finish loading `google.maps`.
@JS('vexdaMapsReady')
external JSPromise _vexdaMapsReady();

abstract final class GoogleMapsBootstrap {
  GoogleMapsBootstrap._();

  static Future<void>? _ensureReadyFuture;

  /// Resolves only after `google.maps.Map` is available, or completes
  /// immediately when the loader already settled before this call.
  static Future<void> ensureReady() {
    return _ensureReadyFuture ??= _ensureReadyImpl();
  }

  static Future<void> _ensureReadyImpl() async {
    try {
      await _vexdaMapsReady().toDart;
    } on Object {
      // Load errors are surfaced via [GoogleMapsLoadState] for UI messaging.
      rethrow;
    }
  }
}
