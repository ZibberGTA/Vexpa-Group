import 'package:geolocator/geolocator.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/discovery/application/discovery_nearby_sorter.dart';

import '../../../core/vexcore/mobile_venue_document_mapper.dart';
import '../../../core/vexcore/mobile_vexcore.dart';
import '../../home/models/venue_model.dart';
import '../models/startup_data.dart';
import 'startup_cache.dart';

class StartupDataService {
  StartupDataService._();

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
    final result = await MobileVexCore.venueRepository.loadPublicVenues();
    return switch (result) {
      DataSuccess(:final value) =>
        value.map(MobileVenueDocumentMapper.homeVenueFromVexVenue).toList(),
      DataFailure() => <VenueModel>[],
    };
  }

  static List<VenueModel> _sortNearby({
    required List<VenueModel> venues,
    required Position? position,
  }) {
    final sorted = [...venues];

    DiscoveryNearbySorter.sortByNearby(
      items: sorted,
      userLatitude: position?.latitude,
      userLongitude: position?.longitude,
      readVenueLatitude: (venue) => venue.location?.latitude,
      readVenueLongitude: (venue) => venue.location?.longitude,
      readFallbackScore: (venue) => DiscoveryNearbySorter.fallbackPopularityScore(
        hasDeals: venue.hasDeals,
        crowdLevel: venue.crowdLevel,
        hasBannerImage: venue.bannerImageUrl.isNotEmpty,
      ),
    );

    return sorted;
  }
}
