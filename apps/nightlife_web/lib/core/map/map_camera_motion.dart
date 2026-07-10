import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'vexda_map_constants.dart';

/// Camera motion helpers aligned with the mobile [VenueMapScreen] behaviour.
class MapCameraMotion {
  MapCameraMotion._();

  /// Smoothly brings [target] into view without unnecessary zoom jumps.
  ///
  /// Zoom only increases toward [VexdaMapConstants.focusZoom] when the map is
  /// currently zoomed out farther than the focus level.
  static Future<void> focusVenue(
    GoogleMapController controller, {
    required LatLng target,
    required double currentZoom,
  }) {
    final zoom = currentZoom < VexdaMapConstants.focusZoom
        ? VexdaMapConstants.focusZoom
        : currentZoom;

    if ((zoom - currentZoom).abs() < 0.05) {
      return controller.animateCamera(CameraUpdate.newLatLng(target));
    }

    return controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, zoom),
    );
  }
}
