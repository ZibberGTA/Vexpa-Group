import 'package:test/test.dart';
import 'package:vex_core/venue_deals/venue_deal.dart';
import 'package:vex_core/venue_deals/venue_deal_visibility.dart';
import 'package:vex_core/venue_events/venue_event.dart';
import 'package:vex_core/venue_events/venue_event_visibility.dart';
import 'package:vex_engines/experience/application/experience_deal_scheduling.dart';
import 'package:vex_engines/experience/application/experience_deal_status.dart';
import 'package:vex_engines/experience/application/experience_drink_grouper.dart';
import 'package:vex_engines/experience/application/experience_event_status.dart';
import 'package:vex_engines/experience/application/experience_deal_validator.dart';
import 'package:vex_engines/experience/application/experience_write_preparation.dart';
import 'package:vex_engines/experience/shared/experience_deal_types.dart';
import 'package:vex_engines/experience/shared/experience_drink_categories.dart';
import 'package:vex_engines/experience/application/experience_content_orchestrator.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/experience_drink_validator.dart';
import 'package:vex_engines/experience/application/experience_drink_visibility.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';
import 'package:vex_engines/experience/application/experience_featured_limit.dart';
import 'package:vex_engines/experience/application/experience_scheduling_utils.dart';
import 'package:vex_engines/experience/application/experience_update_preparation.dart';
import 'package:vex_engines/experience/domain/experience_content_kind.dart';
import 'package:vex_engines/experience/domain/experience_future_content.dart';
import 'package:vex_engines/experience/shared/experience_featured_sort.dart';
import 'package:vex_engines/experience/shared/experience_search_term_builder.dart';

final class _DealRow {
  const _DealRow({
    required this.id,
    required this.isDeleted,
    required this.isActive,
    this.startDateTime,
    this.endDateTime,
    this.effectiveEndDateTime,
    this.featured = false,
  });

  final String id;
  final bool isDeleted;
  final bool isActive;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? effectiveEndDateTime;
  final bool featured;
}

void main() {
  const orchestrator = ExperienceContentOrchestrator();
  final now = DateTime(2026, 7, 10, 12);

  group('ExperienceDealScheduling', () {
    test('resolves effective end from HH:mm fallback', () {
      final end = ExperienceDealScheduling.resolveEffectiveEndDateTime(
        endTime: '21:30',
        now: DateTime(2026, 7, 10, 12),
      );
      expect(end, DateTime(2026, 7, 10, 21, 30));
    });

    test('detects expired and future starts', () {
      final now = DateTime(2026, 7, 10, 12);
      expect(
        ExperienceDealScheduling.isExpired(
          endDateTime: now.subtract(const Duration(hours: 1)),
          endTime: '',
          now: now,
        ),
        isTrue,
      );
      expect(
        ExperienceDealScheduling.isFutureStart(
          startDateTime: now.add(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('ExperienceDealStatusRules', () {
    test('maps lifecycle states for management tables', () {
      final now = DateTime(2026, 7, 10, 12);
      expect(
        ExperienceDealStatusRules.compute(
          isActive: false,
          startDateTime: now,
          endDateTime: now.add(const Duration(days: 1)),
          now: now,
        ),
        ExperienceDealManagementStatus.paused,
      );
      expect(
        ExperienceDealStatusRules.passesStatusFilters(
          status: ExperienceDealManagementStatus.active,
          featured: true,
          selectedFilters: {'Featured'},
        ),
        isTrue,
      );
    });
  });

  group('ExperienceEventStatusRules', () {
    test('maps draft, live, and ended states', () {
      final now = DateTime(2026, 7, 10, 12);
      expect(
        ExperienceEventStatusRules.compute(
          isActive: true,
          startDateTime: now.subtract(const Duration(hours: 1)),
          endDateTime: now.add(const Duration(hours: 2)),
          now: now,
        ),
        ExperienceEventManagementStatus.live,
      );
    });
  });

  group('ExperienceDrinkCategories', () {
    test('normalises and validates allowed categories', () {
      expect(ExperienceDrinkCategories.displayName('beer'), 'Beer');
      expect(ExperienceDrinkCategories.isAllowed('Cocktails'), isTrue);
      expect(ExperienceDrinkCategories.isAllowed('Custom'), isFalse);
    });
  });

  group('ExperienceDealTypes', () {
    test('normalises display labels and allowed keys', () {
      expect(
        ExperienceDealTypes.normalize('Percentage Off'),
        ExperienceDealTypes.percentageOff,
      );
      expect(ExperienceDealTypes.isAllowed('happy_hour'), isTrue);
    });
  });

  group('ExperienceDealValidator', () {
    test('validates deal form fields', () {
      expect(ExperienceDealValidator.validateTitle('  '), isNotNull);
      expect(
        ExperienceDealValidator.validateDealType(ExperienceDealTypes.happyHour),
        isNull,
      );
      expect(ExperienceDealValidator.validateValue('20%'), isNull);
    });
  });

  group('ExperienceDrinkGrouper', () {
    test('groups drinks by normalised category', () {
      final grouped = ExperienceDrinkGrouper.groupByCategory(
        [
          _DrinkMenuRow(name: 'Lager', category: 'beer', available: true),
          _DrinkMenuRow(name: 'Gin', category: 'gin', available: false),
        ],
        category: (drink) => drink.category,
        name: (drink) => drink.name,
        available: (drink) => drink.available,
      );

      expect(grouped.keys, contains('Beers'));
      expect(grouped['Beers']!.single.name, 'Lager');
    });
  });

  group('ExperienceWritePreparation', () {
    test('prepares drink create fields with search terms', () {
      final fields = ExperienceWritePreparation.drinkCreateFields(
        venueId: 'v1',
        venueName: 'Neon Room',
        name: 'Espresso Martini',
        category: 'Cocktails',
        description: 'Classic',
        available: true,
        featured: false,
        createdBy: 'owner',
        price: 12,
      );

      expect(fields['category'], 'cocktails');
      expect(fields['searchTerms'], contains('espresso martini'));
    });
  });

  group('ExperienceDrinkVisibility', () {
    test('requires available and not deleted', () {
      expect(
        ExperienceDrinkVisibility.isPublicVisible(
          isDeleted: false,
          available: true,
        ),
        isTrue,
      );
      expect(
        ExperienceDrinkVisibility.isPublicVisible(
          isDeleted: true,
          available: true,
        ),
        isFalse,
      );
      expect(
        ExperienceDrinkVisibility.isPublicVisible(
          isDeleted: false,
          available: false,
        ),
        isFalse,
      );
    });
  });

  group('ExperienceDealVisibility parity with VexCore', () {
    test('matches current and upcoming deal windows', () {
      final currentStart = now.subtract(const Duration(hours: 1));
      final currentEnd = now.add(const Duration(hours: 2));
      final upcomingStart = now.add(const Duration(days: 1));
      final upcomingEnd = now.add(const Duration(days: 2));
      final currentDeal = _venueDeal(
        startDateTime: currentStart,
        endDateTime: currentEnd,
      );
      final upcomingDeal = _venueDeal(
        startDateTime: upcomingStart,
        endDateTime: upcomingEnd,
      );

      expect(
        ExperienceDealVisibility.isPublicCurrent(
          isDeleted: currentDeal.isDeleted,
          isActive: currentDeal.isActive,
          startDateTime: currentDeal.startDateTime,
          endDateTime: currentDeal.endDateTime,
          effectiveEndDateTime: currentDeal.effectiveEndDateTime,
          now: now,
        ),
        isPublicCurrentVenueDeal(currentDeal, now: now),
      );

      expect(
        ExperienceDealVisibility.isPublicUpcoming(
          isDeleted: upcomingDeal.isDeleted,
          isActive: upcomingDeal.isActive,
          startDateTime: upcomingDeal.startDateTime,
          endDateTime: upcomingDeal.endDateTime,
          effectiveEndDateTime: upcomingDeal.effectiveEndDateTime,
          now: now,
        ),
        isPublicUpcomingVenueDeal(upcomingDeal, now: now),
      );
    });

    test('hides paused and expired deals', () {
      expect(
        ExperienceDealVisibility.isPublicVisible(
          isDeleted: false,
          isActive: false,
          startDateTime: now.subtract(const Duration(hours: 1)),
          endDateTime: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isFalse,
      );
      expect(
        ExperienceDealVisibility.isPublicVisible(
          isDeleted: false,
          isActive: true,
          startDateTime: now.subtract(const Duration(days: 2)),
          endDateTime: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('ExperienceEventVisibility parity with VexCore', () {
    test('matches current and upcoming event windows', () {
      final currentStart = now.subtract(const Duration(hours: 1));
      final currentEnd = now.add(const Duration(hours: 2));
      final upcomingStart = now.add(const Duration(days: 1));
      final upcomingEnd = now.add(const Duration(days: 1, hours: 3));
      final currentEvent = _venueEvent(
        startDateTime: currentStart,
        endDateTime: currentEnd,
      );
      final upcomingEvent = _venueEvent(
        startDateTime: upcomingStart,
        endDateTime: upcomingEnd,
      );

      expect(
        ExperienceEventVisibility.isPublicCurrent(
          isDeleted: currentEvent.isDeleted,
          isActive: currentEvent.isActive,
          startDateTime: currentEvent.startDateTime,
          endDateTime: currentEvent.endDateTime,
          now: now,
        ),
        isPublicCurrentVenueEvent(currentEvent, now: now),
      );

      expect(
        ExperienceEventVisibility.isPublicUpcoming(
          isDeleted: upcomingEvent.isDeleted,
          isActive: upcomingEvent.isActive,
          startDateTime: upcomingEvent.startDateTime,
          endDateTime: upcomingEvent.endDateTime,
          now: now,
        ),
        isPublicUpcomingVenueEvent(upcomingEvent, now: now),
      );
    });
  });

  group('ExperienceFeaturedLimit', () {
    test('enforces drink featured cap', () {
      const limit = ExperienceFeaturedLimit.drinks;
      final drinks = List.generate(
        5,
        (index) => _DrinkStub(id: '$index', featured: true),
      );

      expect(
        limit.validateAdd(
          wantsFeatured: true,
          venueItems: drinks,
          isFeatured: (drink) => drink.featured,
        ),
        limit.limitMessage,
      );
    });

    test('allows bulk edit when within cap', () {
      const limit = ExperienceFeaturedLimit.deals;
      final deals = [
        _DealStub(id: '1', featured: true),
        _DealStub(id: '2', featured: false),
      ];

      expect(
        limit.validateBulkEdit(
          selectedItems: [deals[1]],
          venueItems: deals,
          proposedFeaturedValues: const [true],
          isFeatured: (deal) => deal.featured,
          isSelected: (deal) => deal.id == '2',
        ),
        isNull,
      );
    });
  });

  group('ExperienceSearchTermBuilder', () {
    test('prefix indexes trimmed lowercase values', () {
      final terms = ExperienceSearchTermBuilder.buildFromValues([
        'Espresso Martini',
      ]);

      expect(terms, contains('espresso martini'));
      expect(terms, contains('e'));
      expect(terms, contains('espresso'));
      expect(terms.length, lessThanOrEqualTo(100));
    });
  });

  group('ExperienceUpdatePreparation', () {
    test('prepares search term field map', () {
      final field = ExperienceUpdatePreparation.searchTermsField(['Neon Room']);
      expect(field['searchTerms'], isA<List<String>>());
      expect(field['searchTerms'], contains('neon room'));
    });
  });

  group('ExperienceSchedulingUtils', () {
    test('combines date and HH:mm time', () {
      final combined = ExperienceSchedulingUtils.combineDateAndTime(
        DateTime(2026, 7, 10),
        '18:30',
      );
      expect(combined, DateTime(2026, 7, 10, 18, 30));
    });

    test('merges event date and time without changing unrelated fields', () {
      final existing = DateTime(2026, 7, 10, 20, 15);
      final mergedDate = ExperienceSchedulingUtils.mergeEventDate(
        existing,
        DateTime(2026, 8, 1),
      );
      expect(mergedDate, DateTime(2026, 8, 1, 20, 15));

      final mergedTime = ExperienceSchedulingUtils.mergeEventTime(
        existing,
        '22:45',
      );
      expect(mergedTime, DateTime(2026, 7, 10, 22, 45));
    });
  });

  group('ExperienceContentOrchestrator', () {
    test('filters visible deals in memory without extra reads', () {
      final deals = [
        _DealRow(
          id: 'current',
          isDeleted: false,
          isActive: true,
          startDateTime: now.subtract(const Duration(hours: 1)),
          endDateTime: now.add(const Duration(hours: 1)),
        ),
        _DealRow(
          id: 'expired',
          isDeleted: false,
          isActive: true,
          startDateTime: now.subtract(const Duration(days: 2)),
          endDateTime: now.subtract(const Duration(days: 1)),
        ),
      ];

      final visible = orchestrator.filterPublicVisibleDeals(
        deals,
        isDeleted: (deal) => deal.isDeleted,
        isActive: (deal) => deal.isActive,
        startDateTime: (deal) => deal.startDateTime,
        endDateTime: (deal) => deal.endDateTime,
        effectiveEndDateTime: (deal) => deal.effectiveEndDateTime,
        now: now,
      );

      expect(visible.map((deal) => deal.id), ['current']);
    });

    test('sorts featured content first', () {
      final sorted = orchestrator.sortFeaturedFirst(
        [
          _DealRow(
            id: 'b',
            isDeleted: false,
            isActive: true,
            featured: false,
          ),
          _DealRow(
            id: 'a',
            isDeleted: false,
            isActive: true,
            featured: true,
          ),
        ],
        isFeatured: (deal) => deal.featured,
        compare: (a, b) => a.id.compareTo(b.id),
      );

      expect(sorted.map((deal) => deal.id), ['a', 'b']);
    });
  });

  group('ExperienceDrinkValidator', () {
    test('validates name, category, and price', () {
      expect(ExperienceDrinkValidator.validateName('  '), isNotNull);
      expect(
        ExperienceDrinkValidator.validateCategory(
          'Beer',
          isAllowed: (value) => value == 'Beer',
        ),
        isNull,
      );
      expect(ExperienceDrinkValidator.validatePrice('£12.50'), isNull);
      expect(ExperienceDrinkValidator.validatePrice('-1'), isNotNull);
    });
  });

  group('Experience future content structure', () {
    test('marks Version 1 kinds separately from planned kinds', () {
      expect(experienceVersion1ContentKinds, contains(ExperienceContentKind.drink));
      expect(
        ExperienceFutureContent.isPlanned(ExperienceContentKind.menu),
        isTrue,
      );
      expect(
        ExperienceFutureContent.isPlanned(ExperienceContentKind.drink),
        isFalse,
      );
    });
  });

  group('sortExperienceFeaturedFirst', () {
    test('preserves compare order within featured groups', () {
      final sorted = sortExperienceFeaturedFirst(
        ['c', 'a', 'b'],
        (item) => item == 'a',
        (a, b) => a.compareTo(b),
      );
      expect(sorted, ['a', 'b', 'c']);
    });
  });
}

final class _DrinkMenuRow {
  const _DrinkMenuRow({
    required this.name,
    required this.category,
    required this.available,
  });

  final String name;
  final String category;
  final bool available;
}

final class _DrinkStub {
  const _DrinkStub({required this.id, required this.featured});

  final String id;
  final bool featured;
}

final class _DealStub {
  const _DealStub({required this.id, required this.featured});

  final String id;
  final bool featured;
}

VenueDeal _venueDeal({
  required DateTime? startDateTime,
  required DateTime? endDateTime,
  bool isActive = true,
  bool isDeleted = false,
}) {
  return VenueDeal(
    id: 'deal-1',
    venueId: 'venue-1',
    title: 'Happy Hour',
    description: '2-for-1',
    dealType: 'percentage',
    value: '50',
    startTime: '18:00',
    endTime: '20:00',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isActive: isActive,
    featured: false,
    isDeleted: isDeleted,
  );
}

VenueEvent _venueEvent({
  required DateTime startDateTime,
  required DateTime endDateTime,
  bool isActive = true,
  bool isDeleted = false,
}) {
  return VenueEvent(
    id: 'event-1',
    venueId: 'venue-1',
    title: 'Live DJ',
    description: 'House night',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    category: 'Music',
    imageUrl: '',
    artist: '',
    isActive: isActive,
    featured: false,
    isDeleted: isDeleted,
  );
}
