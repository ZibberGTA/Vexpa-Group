import 'package:test/test.dart';
import 'package:vex_core/discovery/searchable_content_records.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_candidate_matcher.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_merger.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_orchestrator.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_query.dart';
import 'package:vex_engines/discovery/domain/discovery_rankable_match.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_searchable.dart';
import 'package:vex_engines/discovery/domain/search_filter_category.dart';
import 'package:vex_engines/discovery/domain/search_match_models.dart';

void main() {
  const queryRules = DiscoveryUnifiedSearchQuery();
  const candidateMatcher = DiscoveryUnifiedSearchCandidateMatcher();
  final orchestrator = DiscoveryUnifiedSearchOrchestrator();
  final merger = DiscoveryUnifiedSearchMerger();

  group('DiscoveryUnifiedSearchQuery', () {
    test('returns empty for short non-venue queries', () {
      expect(
        queryRules.shouldReturnEmptyForShortQuery(
          cleanQuery: 'a',
          category: SearchFilterCategory.drinks,
        ),
        isTrue,
      );
    });
  });

  group('DiscoveryUnifiedSearchCandidateMatcher', () {
    test('excludes deleted drinks', () {
      expect(
        candidateMatcher.matchesDrink(
          const SearchableDrinkRecord(
            id: 'd1',
            venueId: 'v1',
            name: 'Martini',
            isDeleted: true,
            available: true,
          ),
          'martini',
        ),
        isFalse,
      );
    });

    test('excludes expired events', () {
      expect(
        candidateMatcher.matchesEvent(
          SearchableEventRecord(
            id: 'e1',
            venueId: 'v1',
            title: 'Past Night',
            endDateTime: DateTime(2020, 1, 1),
          ),
          'night',
          now: DateTime(2026, 7, 11),
        ),
        isFalse,
      );
    });
  });

  group('DiscoveryUnifiedSearchMerger', () {
    test('deduplicates drinks per venue', () {
      const factory = _TestMatchFactory();
      var grouped = <String, _TestMatch>{};
      const base = _TestMatch(
        catalogIndex: 0,
        venue: _TestVenue(id: 'v1', name: 'Neon Room'),
      );

      grouped = merger.upsertEntity(
        grouped: grouped,
        venueId: 'v1',
        baseMatch: base,
        drink: const MatchedDrink(id: 'd1', name: 'Martini'),
        factory: factory,
      );
      grouped = merger.upsertEntity(
        grouped: grouped,
        venueId: 'v1',
        baseMatch: base,
        drink: const MatchedDrink(id: 'd1', name: 'Martini'),
        factory: factory,
      );

      expect(grouped['v1']!.matchedDrinks, hasLength(1));
    });
  });

  group('DiscoveryUnifiedSearchOrchestrator', () {
    const factory = _TestMatchFactory();

    test('returns all venues for empty query', () {
      final result = orchestrator.search(
        query: '   ',
        category: SearchFilterCategory.venues,
        catalog: const [
          _TestVenue(id: 'v1', name: 'Neon Room'),
          _TestVenue(id: 'v2', name: 'Pulse Bar', isOpen: false),
        ],
        catalogById: const {'v1': 0, 'v2': 1},
        usingFallback: false,
        matchFactory: factory,
        withRankScore: (match, score) => match.copyWith(rankScore: score),
      );

      expect(result.matches, hasLength(2));
      expect(result.groupCounts.venues, 2);
    });

    test('combines venue and drink matches deterministically', () {
      final result = orchestrator.search(
        query: 'martini',
        category: SearchFilterCategory.venues,
        catalog: const [_TestVenue(id: 'v1', name: 'Neon Room')],
        catalogById: const {'v1': 0},
        usingFallback: false,
        matchFactory: factory,
        withRankScore: (match, score) => match.copyWith(rankScore: score),
        directVenueMatches: const <_TestVenue>[],
        candidates: const UnifiedSearchCandidateBatch(
          drinks: [
            SearchableDrinkRecord(
              id: 'd1',
              venueId: 'v1',
              name: 'Espresso Martini',
              available: true,
            ),
          ],
        ),
      );

      expect(result.matches, hasLength(1));
      expect(result.matches.first.matchedDrinks.first.name, 'Espresso Martini');
    });

    test('returns empty for short drink-only query', () {
      final result = orchestrator.search(
        query: 'a',
        category: SearchFilterCategory.drinks,
        catalog: const [_TestVenue(id: 'v1', name: 'Neon Room')],
        catalogById: const {'v1': 0},
        usingFallback: false,
        matchFactory: factory,
        withRankScore: (match, score) => match.copyWith(rankScore: score),
      );

      expect(result.matches, isEmpty);
    });
  });
}

final class _TestVenue implements DiscoveryVenueMatchable {
  const _TestVenue({
    required this.id,
    required this.name,
    this.isOpen = true,
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final bool isOpen;

  @override
  String get area => 'Shoreditch';

  @override
  String get city => 'London';

  @override
  String get postcode => '';

  @override
  String get venueType => 'Bar';

  @override
  List<String> get tags => const ['Cocktails'];
}

final class _TestMatch implements DiscoveryRankableMatch {
  const _TestMatch({
    required this.catalogIndex,
    required this.venue,
    this.directVenueMatch = false,
    this.matchedDrinks = const [],
    this.matchedDeals = const [],
    this.matchedEvents = const [],
    this.matchedTrails = const [],
    this.rankScore = 0,
  });

  final int catalogIndex;

  @override
  final _TestVenue venue;

  @override
  final bool directVenueMatch;

  @override
  final List<MatchedDrink> matchedDrinks;

  @override
  final List<MatchedDeal> matchedDeals;

  @override
  final List<MatchedEvent> matchedEvents;

  @override
  final List<MatchedTrail> matchedTrails;

  @override
  final int rankScore;

  _TestMatch copyWith({
    bool? directVenueMatch,
    List<MatchedDrink>? matchedDrinks,
    List<MatchedDeal>? matchedDeals,
    List<MatchedEvent>? matchedEvents,
    List<MatchedTrail>? matchedTrails,
    int? rankScore,
  }) {
    return _TestMatch(
      catalogIndex: catalogIndex,
      venue: venue,
      directVenueMatch: directVenueMatch ?? this.directVenueMatch,
      matchedDrinks: matchedDrinks ?? this.matchedDrinks,
      matchedDeals: matchedDeals ?? this.matchedDeals,
      matchedEvents: matchedEvents ?? this.matchedEvents,
      matchedTrails: matchedTrails ?? this.matchedTrails,
      rankScore: rankScore ?? this.rankScore,
    );
  }
}

final class _TestMatchFactory
    implements DiscoveryUnifiedSearchMatchFactory<_TestMatch> {
  const _TestMatchFactory();

  @override
  _TestMatch buildBase({
    required int catalogIndex,
    required DiscoveryVenueMatchable venue,
    bool directVenueMatch = false,
  }) {
    return _TestMatch(
      catalogIndex: catalogIndex,
      venue: venue as _TestVenue,
      directVenueMatch: directVenueMatch,
    );
  }

  @override
  _TestMatch merge(
    _TestMatch existing, {
    bool directVenueMatch = false,
    MatchedDrink? drink,
    MatchedDeal? deal,
    MatchedEvent? event,
    MatchedTrail? trail,
  }) {
    var drinks = List<MatchedDrink>.from(existing.matchedDrinks);
    var deals = List<MatchedDeal>.from(existing.matchedDeals);
    var events = List<MatchedEvent>.from(existing.matchedEvents);
    var trails = List<MatchedTrail>.from(existing.matchedTrails);

    if (drink != null && !drinks.any((item) => item.id == drink.id)) {
      drinks.add(drink);
    }
    if (deal != null && !deals.any((item) => item.id == deal.id)) {
      deals.add(deal);
    }
    if (event != null && !events.any((item) => item.id == event.id)) {
      events.add(event);
    }
    if (trail != null && !trails.any((item) => item.id == trail.id)) {
      trails.add(trail);
    }

    return existing.copyWith(
      directVenueMatch: directVenueMatch || existing.directVenueMatch,
      matchedDrinks: drinks,
      matchedDeals: deals,
      matchedEvents: events,
      matchedTrails: trails,
    );
  }
}
