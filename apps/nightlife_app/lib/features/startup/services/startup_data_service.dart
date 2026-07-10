import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../home/models/venue_model.dart';
import '../models/startup_data.dart';
import 'startup_cache.dart';

class StartupDataService {
  StartupDataService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<StartupData> load({
    void Function(String message)? onStatus,
  }) async {
    onStatus?.call('Finding nearby drinks and venues...');

    Position? position;
    String? warning;

    try {
      position = await _tryGetPosition(onStatus: onStatus).timeout(
        const Duration(seconds: 7),
        onTimeout: () => null,
      );
    } catch (_) {
      warning = 'Location is unavailable. Showing popular venues instead.';
    }

    onStatus?.call('Checking deals and venues...');

    final venues = await _loadVenues().timeout(
      const Duration(seconds: 10),
      onTimeout: () => <VenueModel>[],
    );

    onStatus?.call('Preparing your map...');

    final nearbyVenues = _sortNearby(
      venues: venues,
      position: position,
    ).take(25).toList();

    if (venues.isEmpty && warning == null) {
      warning = 'Could not preload venues. The app will refresh again on the map.';
    }

    final data = StartupData(
      venues: venues,
      nearbyVenues: nearbyVenues,
      locationLoaded: position != null,
      warningMessage: warning,
      userLatitude: position?.latitude,
      userLongitude: position?.longitude,
    );

    StartupCache.save(data);
    return data;
  }

  static Future<Position?> _tryGetPosition({
    void Function(String message)? onStatus,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      onStatus?.call('Requesting location access...');
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    onStatus?.call('Finding venues near you...');

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 6),
      ),
    );
  }

  static Future<List<VenueModel>> _loadVenues() async {
    final snapshot = await _db
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => VenueModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  static List<VenueModel> _sortNearby({
    required List<VenueModel> venues,
    required Position? position,
  }) {
    final sorted = [...venues];

    if (position == null) {
      sorted.sort((a, b) {
        final aScore = _fallbackVenueScore(a);
        final bScore = _fallbackVenueScore(b);
        return bScore.compareTo(aScore);
      });
      return sorted;
    }

    sorted.sort((a, b) {
      final aDistance = _distanceMiles(position, a);
      final bDistance = _distanceMiles(position, b);
      return aDistance.compareTo(bDistance);
    });

    return sorted;
  }

  static int _fallbackVenueScore(VenueModel venue) {
    var score = 0;
    if (venue.hasDeals) score += 5;
    if (venue.crowdLevel.toLowerCase().contains('busy')) score += 3;
    if (venue.crowdLevel.toLowerCase().contains('packed')) score += 4;
    if (venue.bannerImageUrl.isNotEmpty) score += 1;
    return score;
  }

  static double _distanceMiles(Position position, VenueModel venue) {
    final location = venue.location;
    if (location == null) return double.maxFinite;

    const earthRadiusMiles = 3958.8;
    final lat1 = _degToRad(position.latitude);
    final lon1 = _degToRad(position.longitude);
    final lat2 = _degToRad(location.latitude);
    final lon2 = _degToRad(location.longitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMiles * c;
  }

  static double _degToRad(double value) => value * math.pi / 180;
}
