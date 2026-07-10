import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared external directions launcher for DrinkSpot.
///
/// This intentionally uses Google Maps URLs rather than duplicating map-routing UI.
/// It can be reused by venue cards, trail stops, saved venues and search results.
class DirectionsService {
  const DirectionsService._();

  static Future<bool> openDirections({
    required String destinationName,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    bool requestCurrentLocation = true,
  }) async {
    final destination = _buildDestination(
      name: destinationName,
      address: destinationAddress,
      latitude: destinationLatitude,
      longitude: destinationLongitude,
    );

    if (destination.isEmpty) return false;

    String? origin;
    if (requestCurrentLocation) {
      origin = await _tryCurrentLocation();
    }

    final query = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'walking',
    };

    if (origin != null && origin.isNotEmpty) {
      query['origin'] = origin;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', query);

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    final fallback = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': destination,
    });

    if (await canLaunchUrl(fallback)) {
      return launchUrl(fallback, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  static String _buildDestination({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return '$latitude,$longitude';
    }

    final parts = <String>[];
    final cleanName = name.trim();
    final cleanAddress = (address ?? '').trim();

    if (cleanName.isNotEmpty) parts.add(cleanName);
    if (cleanAddress.isNotEmpty) parts.add(cleanAddress);

    return parts.join(', ');
  }

  static Future<String?> _tryCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return '${position.latitude},${position.longitude}';
    } catch (_) {
      return null;
    }
  }
}
