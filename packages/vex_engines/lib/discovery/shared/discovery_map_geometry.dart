/// Platform-independent map coordinate helpers for discovery.
class DiscoveryCoordinate {
  const DiscoveryCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

final class DiscoveryMapGeometry {
  DiscoveryMapGeometry._();

  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  static DiscoveryCoordinate? centroid(Iterable<DiscoveryCoordinate> points) {
    var count = 0;
    var latSum = 0.0;
    var lngSum = 0.0;

    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
      count++;
    }

    if (count == 0) return null;

    return DiscoveryCoordinate(
      latitude: latSum / count,
      longitude: lngSum / count,
    );
  }
}
