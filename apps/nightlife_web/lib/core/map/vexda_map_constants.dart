/// Shared Vexda map constants aligned with the mobile app map screen.
class VexdaMapConstants {
  VexdaMapConstants._();

  /// Default nightlife discovery zoom on [VenueMapScreen].
  static const double defaultZoom = 13;

  /// Focus zoom when a venue becomes selected (mobile `_moveToResults`).
  static const double focusZoom = 14;

  /// Canvas render size passed to [VenueMapMarker.create] on mobile.
  static const int markerRenderSize = 200;

  /// Logical marker size on the map surface.
  static const double markerDisplaySize = 50;

  /// Pin anchor — matches mobile marker placement.
  static const double markerAnchorX = 0.5;
  static const double markerAnchorY = 0.92;

  /// UI motion timing used across Vexda surfaces (cards, panels, map focus).
  static const Duration motionDuration = Duration(milliseconds: 280);
  static const Duration motionDurationFast = Duration(milliseconds: 180);
}
