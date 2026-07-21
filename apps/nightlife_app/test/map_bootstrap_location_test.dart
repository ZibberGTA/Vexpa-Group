import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/home/models/venue_model.dart';
import 'package:nightlife_app/features/map/services/map_bootstrap_location.dart';
import 'package:nightlife_app/features/startup/models/startup_data.dart';

void main() {
  group('MapBootstrapLocation', () {
    test('prefers startup user location', () {
      final center = MapBootstrapLocation.resolveInitialCenter(
        startupData: const StartupData(
          venues: [],
          nearbyVenues: [],
          locationLoaded: true,
          userLatitude: 53.4808,
          userLongitude: -2.2426,
        ),
      );

      expect(center.latitude, closeTo(53.4808, 0.0001));
      expect(center.longitude, closeTo(-2.2426, 0.0001));
    });

    test('uses venue centroid before application fallback', () {
      final center = MapBootstrapLocation.resolveInitialCenter(
        startupData: StartupData(
          venues: [
            _venue(id: 'a', lat: 55.9533, lng: -3.1883),
            _venue(id: 'b', lat: 51.5074, lng: -0.1278),
          ],
          nearbyVenues: const [],
          locationLoaded: false,
        ),
      );

      expect(center, isNot(MapBootstrapLocation.applicationFallbackCenter));
      expect(center.latitude, closeTo(53.73035, 0.01));
    });

    test('falls back to UK centroid when location and venues unavailable', () {
      final center = MapBootstrapLocation.resolveInitialCenter(
        startupData: const StartupData(
          venues: [],
          nearbyVenues: [],
          locationLoaded: false,
        ),
      );

      expect(center, MapBootstrapLocation.applicationFallbackCenter);
    });
  });
}

VenueModel _venue({
  required String id,
  required double lat,
  required double lng,
}) {
  return VenueModel(
    id: id,
    ownerId: 'owner',
    name: id,
    description: '',
    address: '',
    category: 'bar',
    crowdLevel: 'quiet',
    location: GeoPoint(lat, lng),
  );
}
