import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../startup/models/startup_data.dart';

/// Cached device-location reads for map orchestration.
///
/// Avoids repeated permission prompts and duplicate Geolocator calls during
/// widget rebuilds.
class DeviceLocationService {
  DeviceLocationService._();

  static LatLng? _cachedPosition;
  static bool _lookupAttempted = false;

  static void seedFromStartup(StartupData? startupData) {
    if (startupData?.hasUserLocation != true) return;
    _cachedPosition = LatLng(
      startupData!.userLatitude!,
      startupData.userLongitude!,
    );
  }

  static LatLng? get cachedPosition => _cachedPosition;

  /// Returns a cached or freshly resolved device location.
  ///
  /// When [requestPermission] is false, permission is never requested and a
  /// prior denial returns null immediately.
  static Future<LatLng?> readCurrentLocation({
    bool requestPermission = false,
  }) async {
    if (_cachedPosition != null) return _cachedPosition;
    if (_lookupAttempted && !requestPermission) return null;

    _lookupAttempted = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestPermission) return null;
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      _cachedPosition = LatLng(position.latitude, position.longitude);
      return _cachedPosition;
    } on Object {
      return null;
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _cachedPosition = null;
    _lookupAttempted = false;
  }
}
