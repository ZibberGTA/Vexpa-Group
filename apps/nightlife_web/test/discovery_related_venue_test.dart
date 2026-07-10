import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vex_engines/discovery/application/discovery_related_venue_service.dart';

import 'package:nightlife_web/features/search/data/search_venue_catalog.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';
import 'package:nightlife_web/features/venue/data/venue_related_repository.dart';
import 'package:nightlife_web/features/venue/models/venue_details_view.dart';

VenueSearchResult _sampleVenue({
  required String id,
  required String name,
  required String city,
  String venueType = 'Cocktail Bar',
}) {
  return VenueSearchResult(
    id: id,
    name: name,
    area: 'Shoreditch',
    city: city,
    venueType: venueType,
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [Color(0xFF3D1054), Color(0xFF9D28FF)],
    logoGradient: const [Color(0xFFFF2D95), Color(0xFF9D28FF)],
    resultReason: 'Open until late',
    isOpen: true,
    latitude: 51.52,
    longitude: -0.08,
  );
}

void main() {
  group('VenueRelatedRepository via Discovery Engine', () {
    test('uses Discovery Engine scoring without extra catalog loads', () async {
      var catalogLoads = 0;
      final repository = VenueRelatedRepository.withCatalog(
        SearchVenueCatalog(
          venues: [
            _sampleVenue(id: 'venue-1', name: 'The Neon Room', city: 'London'),
            _sampleVenue(id: 'venue-2', name: 'Electric Bar', city: 'London'),
            _sampleVenue(
              id: 'venue-3',
              name: 'Manchester Pub',
              city: 'Manchester',
            ),
          ],
          usingFallback: false,
        ),
        relatedVenueService: const DiscoveryRelatedVenueService(),
      );

      const venue = VenueDetailsView(
        id: 'venue-1',
        name: 'The Neon Room',
        address: '12 Brick Lane',
        area: 'Shoreditch',
        city: 'London',
        postcode: '',
        category: 'Cocktail Bar',
        venueType: 'Cocktail Bar',
        rating: 4.8,
        isOpen: true,
        tags: ['Cocktails'],
        highlights: ['Cocktails'],
      );

      final suggestions = await repository.loadSuggestions(venue);
      expect(catalogLoads, 0);
      expect(suggestions.similarVenues.first.id, 'venue-2');
      expect(suggestions.nearbyVenues.first.city, 'London');
    });
  });
}
