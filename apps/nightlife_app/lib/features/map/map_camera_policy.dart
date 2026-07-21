import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Tracks map camera state so search/filter rebuilds do not reset the viewport.
final class MapCameraPolicy {
  MapCameraPolicy({
    required this.bootstrapTarget,
    this.bootstrapZoom = 13,
  })  : _lastTarget = bootstrapTarget,
        _lastZoom = bootstrapZoom;

  final LatLng bootstrapTarget;
  final double bootstrapZoom;

  LatLng _lastTarget;
  double _lastZoom;
  bool mapCreated = false;

  LatLng get lastTarget => _lastTarget;

  double get lastZoom => _lastZoom;

  CameraPosition get initialCameraPosition => CameraPosition(
        target: mapCreated ? _lastTarget : bootstrapTarget,
        zoom: mapCreated ? _lastZoom : bootstrapZoom,
      );

  /// Search refresh must never snap back to the bootstrap fallback.
  bool get shouldResetToBootstrapOnSearchRefresh => false;

  void recordCamera(LatLng target, double zoom) {
    _lastTarget = target;
    _lastZoom = zoom;
  }

  void markMapCreated() {
    mapCreated = true;
  }

  void onSearchChanged() {
    // Preserve the current viewport while venue results refresh.
  }

  void onSearchCleared() {
    // Preserve the current viewport when returning to the full catalog.
  }

  bool shouldAnimateToSelection(LatLng target) =>
      target.latitude != _lastTarget.latitude ||
      target.longitude != _lastTarget.longitude;
}
