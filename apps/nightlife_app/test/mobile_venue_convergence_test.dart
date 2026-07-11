import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/firebase_venue_repository.dart';
import 'package:nightlife_app/core/vexcore/mobile_venue_document_mapper.dart';
import 'package:nightlife_app/core/vexcore/mobile_vexcore.dart';
import 'package:nightlife_app/features/home/models/venue_model.dart';
import 'package:nightlife_app/features/home/services/venue_service.dart';
import 'package:nightlife_app/features/venues/models/venue_details_model.dart';
import 'package:nightlife_app/features/venues/services/venue_details_service.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_repository.dart';

void main() {
  group('MobileVenueDocumentMapper', () {
    test('maps existing venue documents into VexCore venues', () {
      final venue = MobileVenueDocumentMapper.parseVexVenue('v1', {
        'name': 'Neon Room',
        'category': 'Bar',
        'venueType': 'Cocktail Bar',
        'address': '1 Brick Lane',
        'location': GeoPoint(51.52, -0.08),
        'currentCrowdLevel': 'busy',
        'bannerImageUrl': 'https://cdn.example.com/banner.jpg',
        'logoUrl': 'https://cdn.example.com/logo.jpg',
      });

      expect(venue, isNotNull);
      expect(venue!.name, 'Neon Room');
      expect(venue.crowdLevel, 'busy');
      expect(venue.hasValidCoordinates, isTrue);
    });

    test('excludes deleted venues from catalog parsing', () {
      expect(
        MobileVenueDocumentMapper.parseVexVenue('v1', {'isDeleted': true}),
        isNull,
      );
    });

    test('returns null for malformed venue documents', () {
      expect(
        MobileVenueDocumentMapper.parseVexVenue('v1', null),
        isNull,
      );
    });

    test('preserves deleted flag on venue details model', () {
      final details = MobileVenueDocumentMapper.parseVenueDetails('v1', {
        'name': 'Hidden Room',
        'isDeleted': true,
      });

      expect(details, isNotNull);
      expect(details!.isDeleted, isTrue);
    });

    test('maps home venue model fields from Firestore document', () {
      final model = MobileVenueDocumentMapper.parseHomeVenueModel('v1', {
        'ownerId': 'owner-1',
        'name': 'Neon Room',
        'description': 'Late-night cocktails',
        'address': '1 Brick Lane',
        'category': 'Bar',
        'currentCrowdLevel': 'steady',
        'bannerImageUrl': 'https://cdn.example.com/banner.jpg',
      });

      expect(model?.ownerId, 'owner-1');
      expect(model?.description, 'Late-night cocktails');
      expect(model?.crowdLevel, 'steady');
    });
  });

  group('Mobile venue service delegation', () {
    tearDown(() {
      MobileVexCore.overrideVenueRepository(null);
    });

    test('VenueDetailsService delegates watch to repository adapter', () async {
      final controller = StreamController<VenueDetailsModel?>();
      final repository = _DetailsWatchRepository(controller.stream);
      MobileVexCore.overrideVenueRepository(repository);

      final future = VenueDetailsService.venueStream('v1').first;
      controller.add(
        MobileVenueDocumentMapper.parseVenueDetails('v1', {
          'name': 'Neon Room',
          'category': 'Bar',
        }),
      );

      final venue = await future;

      expect(repository.watchDetailsCalls, 1);
      expect(venue?.name, 'Neon Room');
      await controller.close();
    });

    test('VenueService catalog stream uses repository watchHomeVenueCatalog', () async {
      final repository = _HomeCatalogRepository(
        homeVenues: [
          MobileVenueDocumentMapper.parseHomeVenueModel('v1', {
            'name': 'Neon Room',
            'category': 'Bar',
            'ownerId': 'owner-1',
          })!,
        ],
      );
      MobileVexCore.overrideVenueRepository(repository);

      final venues = await VenueService.getVenues().first;

      expect(repository.watchHomeCalls, 1);
      expect(venues.single.name, 'Neon Room');
    });

    test('catalog load uses one repository call', () async {
      final repository = MockVenueRepository(
        publicVenues: [mockVenue(id: 'v1', name: 'Neon Room')],
      );
      MobileVexCore.overrideVenueRepository(_CatalogLoadRepository(repository));

      final result = await MobileVexCore.venueRepository.loadPublicVenues();

      expect(result, isA<DataSuccess<List<Venue>>>());
      expect(repository.loadCalls, 1);
    });
  });
}

final class _DetailsWatchRepository extends FirebaseVenueRepository {
  _DetailsWatchRepository(this.detailsStream);

  final Stream<VenueDetailsModel?> detailsStream;
  int watchDetailsCalls = 0;

  @override
  Stream<VenueDetailsModel?> watchVenueDetails(String venueId) {
    watchDetailsCalls++;
    return detailsStream;
  }
}

final class _HomeCatalogRepository extends FirebaseVenueRepository {
  _HomeCatalogRepository({required this.homeVenues});

  final List<VenueModel> homeVenues;
  int watchHomeCalls = 0;

  @override
  Stream<List<VenueModel>> watchHomeVenueCatalog() {
    watchHomeCalls++;
    return Stream.value(homeVenues);
  }
}

final class _CatalogLoadRepository extends FirebaseVenueRepository {
  _CatalogLoadRepository(this.delegate);

  final MockVenueRepository delegate;

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() => delegate.loadPublicVenues();
}
