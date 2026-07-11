import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vex_engines/discovery/shared/discovery_map_geometry.dart';

import 'package:nightlife_web/features/search/data/search_venue_map_geometry.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';

void main() {
  group('SearchVenueMapGeometry', () {
    test('delegates centroid calculation to DiscoveryMapGeometry', () {
      final venues = [
        VenueSearchResult(
          id: '1',
          name: 'A',
          area: 'Area',
          city: 'London',
          postcode: 'E1',
          venueType: 'Bar',
          rating: 4.5,
          tags: const ['Bar'],
          bannerGradient: const [Color(0xFF000000)],
          logoGradient: const [Color(0xFF000000)],
          resultReason: 'Open',
          isOpen: true,
          latitude: 51.0,
          longitude: -0.1,
        ),
        VenueSearchResult(
          id: '2',
          name: 'B',
          area: 'Area',
          city: 'London',
          postcode: 'E2',
          venueType: 'Bar',
          rating: 4.5,
          tags: const ['Bar'],
          bannerGradient: const [Color(0xFF000000)],
          logoGradient: const [Color(0xFF000000)],
          resultReason: 'Open',
          isOpen: true,
          latitude: 53.0,
          longitude: -1.0,
        ),
      ];

      final center = SearchVenueMapGeometry.initialCenterFor(venues);
      final engineCentroid = DiscoveryMapGeometry.centroid(
        venues.map(
          (venue) => DiscoveryCoordinate(
            latitude: venue.latitude,
            longitude: venue.longitude,
          ),
        ),
      );

      expect(center.latitude, engineCentroid!.latitude);
      expect(center.longitude, engineCentroid.longitude);
    });
  });
}
