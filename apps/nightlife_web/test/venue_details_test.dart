import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/core/routing/app_router.dart';
import 'package:nightlife_web/features/search/data/search_venue_catalog.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';
import 'package:nightlife_web/features/venue/data/venue_details_mapper.dart';
import 'package:nightlife_web/features/venue/data/venue_drinks_grouper.dart';
import 'package:nightlife_web/features/venue/data/venue_highlights_mapper.dart';
import 'package:nightlife_web/features/venue/data/venue_opening_hours_formatter.dart';
import 'package:nightlife_web/features/venue/data/venue_related_repository.dart';
import 'package:nightlife_web/features/venue/data/models/drink_model.dart';
import 'package:nightlife_web/features/venue/models/venue_details_view.dart';
import 'package:nightlife_web/features/venue/models/venue_opening_hours_entry.dart';
import 'package:nightlife_web/features/venue/widgets/venue_details_hero.dart';
import 'package:nightlife_web/features/venue/widgets/venue_details_info_panel.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('AppRouter', () {
    test('builds venue details path from id', () {
      expect(AppRouter.venueDetails('venue-1'), '/venue/venue-1');
    });
  });

  group('VenueOpeningHoursFormatter', () {
    test('formats weekly opening hours with closed days', () {
      final entries = VenueOpeningHoursFormatter.fromMap({
        'monday': {'open': '18:00', 'close': '02:00', 'closed': false},
        'tuesday': {'closed': true},
      });

      expect(entries, hasLength(7));
      expect(entries.first.hoursLabel, '18:00 – 02:00');
      expect(entries[1].isClosed, isTrue);
    });
  });

  group('VenueDetailsMapper', () {
    test('maps Firestore venue to production details view', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'The Neon Room',
        'description': 'A premium late-night cocktail destination.',
        'address': {
          'line1': '12 Brick Lane',
          'city': 'London',
          'area': 'Shoreditch',
        },
        'category': 'Cocktail Bar',
        'venueType': 'Cocktail Bar',
        'phone': '+44 20 7946 0958',
        'website': 'https://neonroom.example',
        'galleryImageUrls': ['https://example.com/1.jpg'],
        'featureTags': ['Cocktails', 'Late Night', 'Live Music'],
        'openingHours': {
          'monday': {'open': '00:00', 'close': '23:59', 'closed': false},
        },
      });

      final view = VenueDetailsMapper.fromVenueModel(venue);

      expect(view.phone, '+44 20 7946 0958');
      expect(view.description, 'A premium late-night cocktail destination.');
      expect(view.galleryImageUrls, ['https://example.com/1.jpg']);
      expect(view.highlights, isNotEmpty);
      expect(view.hasOpeningHours, isTrue);
    });
  });

  group('VenueHighlightsMapper', () {
    test('limits highlights to six items', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test',
        'featureTags': List.generate(8, (i) => 'Tag $i'),
      });

      expect(VenueHighlightsMapper.fromVenueModel(venue), hasLength(6));
    });
  });

  group('VenueDrinksGrouper', () {
    test('groups drinks by normalised category', () {
      const drinks = [
        DrinkModel(
          id: '1',
          venueId: 'v1',
          name: 'Negroni',
          category: 'cocktails',
          price: 12,
          description: '',
          available: true,
          featured: false,
          isDeleted: false,
        ),
      ];

      final grouped = VenueDrinksGrouper.groupByCategory(drinks);
      expect(grouped.containsKey('Cocktails'), isTrue);
    });
  });

  group('VenueRelatedRepository', () {
    test('ranks similar venues by category and city', () async {
      final repository = VenueRelatedRepository.withCatalog(
        SearchVenueCatalog(
          venues: [
            _sampleVenue(id: 'venue-1', name: 'The Neon Room', city: 'London'),
            _sampleVenue(id: 'venue-2', name: 'Electric Bar', city: 'London'),
            _sampleVenue(id: 'venue-3', name: 'Manchester Pub', city: 'Manchester'),
          ],
          usingFallback: false,
        ),
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
      expect(suggestions.similarVenues.first.id, 'venue-2');
      expect(suggestions.nearbyVenues.first.city, 'London');
    });
  });

  group('VenueDetailsHero', () {
    const venue = VenueDetailsView(
      id: 'venue-1',
      name: 'The Neon Room',
      address: '12 Brick Lane, Shoreditch, London',
      area: 'Shoreditch',
      city: 'London',
      postcode: '',
      category: 'Cocktail Bar',
      venueType: 'Cocktail Bar',
      rating: 4.8,
      isOpen: true,
      tags: ['Cocktails', 'Late Night'],
      highlights: ['Cocktails', 'Late Night'],
    );

    testWidgets('prioritises get directions as primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueDetailsHero(
              venue: venue,
              onBackToSearch: () {},
            ),
          ),
        ),
      );

      expect(find.text('Get directions'), findsOneWidget);
      expect(find.text('Save venue'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('View on map'), findsOneWidget);
    });
  });

  group('VenueDetailsInfoPanel', () {
    testWidgets('shows today hours and hides unavailable rows', (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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
        openingHours: [
          VenueOpeningHoursEntry(
            dayLabel: 'Monday',
            hoursLabel: '18:00 – 02:00',
            isToday: true,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VenueDetailsInfoPanel(venue: venue),
          ),
        ),
      );

      expect(find.text('Opening hours today'), findsOneWidget);
      expect(find.text('Nearest station'), findsNothing);
      expect(find.text('Walking time'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });
  });
}

VenueSearchResult _sampleVenue({
  required String id,
  required String name,
  required String city,
}) {
  return VenueSearchResult(
    id: id,
    name: name,
    area: 'Central',
    city: city,
    venueType: 'Cocktail Bar',
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [Color(0xFF3D1054), Color(0xFF9D28FF)],
    logoGradient: const [Color(0xFFFF2D95), Color(0xFF9D28FF)],
    resultReason: 'Featured',
    isOpen: true,
    latitude: 51.5,
    longitude: -0.12,
  );
}
