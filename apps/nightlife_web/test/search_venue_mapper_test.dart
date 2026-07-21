import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/features/search/data/search_venue_mapper.dart';
import 'package:nightlife_web/features/search/data/search_venue_open_status.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('SearchVenueMapper', () {
    test('maps Firestore venue with GeoPoint location', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'The Neon Room',
        'address': {
          'line1': '12 Brick Lane',
          'city': 'London',
          'area': 'Shoreditch',
        },
        'category': 'Cocktail Bar',
        'venueType': 'Cocktail Bar',
        'location': const GeoPoint(51.5234, -0.0789),
        'bannerImageUrl': 'https://example.com/banner.jpg',
        'logoUrl': 'https://example.com/logo.jpg',
        'averageRating': 4.8,
        'featureTags': ['Cocktails', 'Late Night'],
        'hasDeals': true,
        'openingHours': {
          'monday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'tuesday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'wednesday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'thursday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'friday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'saturday': {'open': '00:00', 'close': '23:59', 'closed': false},
          'sunday': {'open': '00:00', 'close': '23:59', 'closed': false},
        },
      });

      final result = SearchVenueMapper.fromVenueModel(venue);

      expect(result, isNotNull);
      expect(result!.id, 'venue-1');
      expect(result.name, 'The Neon Room');
      expect(result.area, 'Shoreditch');
      expect(result.city, 'London');
      expect(result.venueType, 'Cocktail Bar');
      expect(result.rating, 4.8);
      expect(result.latitude, 51.5234);
      expect(result.longitude, -0.0789);
      expect(result.bannerImageUrl, 'https://example.com/banner.jpg');
      expect(result.logoUrl, 'https://example.com/logo.jpg');
      expect(result.tags, ['Cocktails', 'Late Night']);
      expect(result.resultReason, 'Happy Hour active');
      expect(result.isOpen, isTrue);
    });

    test('returns null when coordinates are missing', () {
      final venue = VenueModel.fromMap('venue-2', {
        'name': 'No Map Venue',
        'address': 'Northern Quarter, Manchester',
        'category': 'Bar',
      });

      expect(SearchVenueMapper.fromVenueModel(venue), isNull);
    });

    test('accepts lat/lng map location format', () {
      final venue = VenueModel.fromMap('venue-3', {
        'name': 'Map Format Venue',
        'address': 'City Centre, Leeds',
        'category': 'Pub',
        'location': {'lat': 53.8008, 'lng': -1.5491},
      });

      final result = SearchVenueMapper.fromVenueModel(venue);

      expect(result, isNotNull);
      expect(result!.latitude, 53.8008);
      expect(result.longitude, -1.5491);
    });

    test('uses zero rating when averageRating is absent', () {
      final venue = VenueModel.fromMap('venue-4', {
        'name': 'Rated Later',
        'address': 'Soho, London',
        'category': 'Bar',
        'location': const GeoPoint(51.513, -0.134),
      });

      final result = SearchVenueMapper.fromVenueModel(venue);

      expect(result, isNotNull);
      expect(result!.rating, 0);
    });
  });

  group('SearchVenueOpenStatus', () {
    test('defaults to open when opening hours are missing', () {
      final status = SearchVenueOpenStatus.fromOpeningHours(const {});

      expect(status.hasHours, isFalse);
      expect(status.isOpen, isTrue);
    });
  });
}
