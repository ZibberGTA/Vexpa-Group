import 'dart:math' as math;

/// Platform-independent geo helpers for discovery flows.
final class DiscoveryGeoUtils {
  DiscoveryGeoUtils._();

  static double distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double value) => value * math.pi / 180;
}

/// Simple lat/lng bounds for map discovery checks.
final class DiscoveryLatLngBounds {
  const DiscoveryLatLngBounds({
    required this.southLatitude,
    required this.westLongitude,
    required this.northLatitude,
    required this.eastLongitude,
  });

  final double southLatitude;
  final double westLongitude;
  final double northLatitude;
  final double eastLongitude;
}

/// Map bounds helpers without Flutter or Google Maps dependencies.
final class DiscoveryMapBounds {
  DiscoveryMapBounds._();

  static bool contains({
    required double latitude,
    required double longitude,
    required DiscoveryLatLngBounds bounds,
  }) {
    final withinLat =
        latitude >= bounds.southLatitude && latitude <= bounds.northLatitude;

    final west = bounds.westLongitude;
    final east = bounds.eastLongitude;
    final withinLng = west <= east
        ? longitude >= west && longitude <= east
        : longitude >= west || longitude <= east;

    return withinLat && withinLng;
  }
}
