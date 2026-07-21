import 'dart:math' as math;

import '../../discovery/shared/discovery_geo_utils.dart';

/// Deterministic geo helpers for trail check-in assessment.
abstract final class TrailGeo {
  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return DiscoveryGeoUtils.distanceKm(
          lat1: lat1,
          lng1: lng1,
          lat2: lat2,
          lng2: lng2,
        ) *
        1000;
  }

  static bool isWithinRadius({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
    required double radiusMeters,
  }) {
    return distanceMeters(lat1: lat1, lng1: lng1, lat2: lat2, lng2: lng2) <=
        radiusMeters;
  }

  static double degreesToRadians(double value) => value * math.pi / 180;
}
