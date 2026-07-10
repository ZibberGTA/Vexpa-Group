import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_deal_repository.dart';
import 'package:nightlife_web/core/vexcore/vex_venue_deal_mapper.dart';
import 'package:nightlife_web/features/venue/data/public_venue_content_filters.dart';
import 'package:nightlife_web/features/venue/data/venue_deals_repository.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_deal_repository.dart';

void main() {
  final now = DateTime(2026, 7, 1, 12);

  group('FirebaseVenueDealRepository public deal mapping', () {
    test('maps valid deal documents', () {
      final deal = FirebaseVenueDealRepository.mapDealEntry('deal-1', {
        'venueId': 'venue-1',
        'title': 'Happy Hour',
        'description': 'Two for one cocktails',
        'dealType': 'percentage',
        'value': '50%',
        'startDateTime': now.toIso8601String(),
        'endDateTime': now.add(const Duration(days: 7)).toIso8601String(),
        'isActive': true,
        'featured': true,
        'isDeleted': false,
      });

      expect(deal, isNotNull);
      expect(deal!.id, 'deal-1');
      expect(deal.title, 'Happy Hour');
      expect(deal.featured, isTrue);
    });

    test('deleted deal is excluded', () {
      final deal = FirebaseVenueDealRepository.mapDealEntry('deal-1', {
        'venueId': 'venue-1',
        'title': 'Old Deal',
        'isDeleted': true,
      });

      expect(deal, isNull);
    });

    test('draft deal is excluded', () {
      final deal = FirebaseVenueDealRepository.mapDealEntry('deal-1', {
        'venueId': 'venue-1',
        'title': 'Draft Deal',
        'status': 'draft',
      });

      expect(deal, isNull);
    });

    test('hidden deal is excluded', () {
      final deal = FirebaseVenueDealRepository.mapDealEntry('deal-1', {
        'venueId': 'venue-1',
        'title': 'Hidden Deal',
        'isHidden': true,
      });

      expect(deal, isNull);
    });

    test('inactive deal is excluded at document level', () {
      final deal = FirebaseVenueDealRepository.mapDealEntry('deal-1', {
        'venueId': 'venue-1',
        'title': 'Inactive Deal',
        'status': 'inactive',
      });

      expect(deal, isNull);
    });

    test('malformed deal is denied safely', () {
      expect(FirebaseVenueDealRepository.mapDealEntry('deal-1', null), isNull);
    });

    test('preserves current and upcoming ordering behaviour', () {
      final deals =
          FirebaseVenueDealRepository.mapDealData([
                MapEntry('1', {
                  'venueId': 'venue-1',
                  'title': 'Upcoming Deal',
                  'startDateTime': now
                      .add(const Duration(days: 3))
                      .toIso8601String(),
                  'endDateTime': now
                      .add(const Duration(days: 10))
                      .toIso8601String(),
                  'isActive': true,
                }),
                MapEntry('2', {
                  'venueId': 'venue-1',
                  'title': 'Current Deal',
                  'startDateTime': now
                      .subtract(const Duration(days: 1))
                      .toIso8601String(),
                  'endDateTime': now
                      .add(const Duration(days: 1))
                      .toIso8601String(),
                  'isActive': true,
                }),
              ])
              .map(dealModelFromVexVenueDeal)
              .where((deal) => isPublicVisibleDeal(deal, now: now))
              .toList()
            ..sort((a, b) {
              final aUpcoming = isPublicUpcomingDeal(a, now: now);
              final bUpcoming = isPublicUpcomingDeal(b, now: now);
              if (aUpcoming != bUpcoming) return aUpcoming ? 1 : -1;
              return (a.startDateTime ?? DateTime(2100)).compareTo(
                b.startDateTime ?? DateTime(2100),
              );
            });

      expect(deals.map((deal) => deal.title), [
        'Current Deal',
        'Upcoming Deal',
      ]);
    });
  });

  group('VenueDealsRepository via VexCore', () {
    test('watchDeals streams deals through VenueDealDataService', () async {
      final now = DateTime.now();
      final repository = VenueDealsRepository(
        venueDealDataService: VenueDealDataService(
          repository: MockVenueDealRepository(
            publicDeals: [
              mockVenueDeal(
                id: '1',
                title: 'Current',
                startDateTime: now.subtract(const Duration(days: 1)),
                endDateTime: now.add(const Duration(days: 1)),
              ),
            ],
          ),
        ),
      );

      final deals = await repository.watchDeals('venue-1').first;

      expect(deals.single.title, 'Current');
    });

    test('returns empty list for blank venue ID', () async {
      final repository = VenueDealsRepository(
        venueDealDataService: VenueDealDataService(
          repository: MockVenueDealRepository(),
        ),
      );

      expect(await repository.watchDeals('  ').first, isEmpty);
    });

    test('rethrows repository failures for error state parity', () async {
      final repository = VenueDealsRepository(
        venueDealDataService: VenueDealDataService(
          repository: MockVenueDealRepository(
            watchStream: Stream.value(
              DataFailure(
                const VexException('denied', code: 'permission-denied'),
              ),
            ),
          ),
        ),
      );

      expect(
        () => repository.watchDeals('venue-1').first,
        throwsA(isA<VexException>()),
      );
    });
  });
}
