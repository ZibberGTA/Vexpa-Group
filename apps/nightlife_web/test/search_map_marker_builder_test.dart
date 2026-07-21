import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/theme/app_colors.dart';
import 'package:nightlife_web/features/search/map/search_map_marker_builder.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';

void main() {
  group('SearchMapMarkerBuilder marker requests', () {
    test('uses Firestore document id for marker identity and tap routing', () {
      final venues = [_venue(id: 'legacy-doc-1'), _venue(id: 'legacy-doc-2')];

      final requests = SearchMapMarkerBuilder.requestsForVenues(
        venues: venues,
        visibleVenueIndices: const [0, 1],
        selectedIndex: 1,
      );

      expect(requests, hasLength(2));
      expect(requests[0].venueId, 'legacy-doc-1');
      expect(requests[0].sourceIndex, 0);
      expect(requests[1].venueId, 'legacy-doc-2');
      expect(requests[1].sourceIndex, 1);
      expect(requests[1].selected, isTrue);
      expect(requests[1].glowColor, AppColors.primaryPink);
    });
  });
}

VenueSearchResult _venue({required String id}) {
  return VenueSearchResult(
    id: id,
    name: 'Test Venue',
    area: 'Shoreditch',
    city: 'London',
    venueType: 'Bar',
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [Color(0xFF3D1054), Color(0xFFFF2D95)],
    logoGradient: const [Color(0xFF3D1054), Color(0xFFFF2D95)],
    resultReason: 'Open until late',
    isOpen: true,
    latitude: 51.52,
    longitude: -0.08,
  );
}
