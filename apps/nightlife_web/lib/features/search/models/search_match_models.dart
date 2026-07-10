import 'package:vex_engines/discovery/domain/discovery_rankable_match.dart';
import 'package:vex_engines/discovery/domain/search_match_models.dart';

export 'package:vex_engines/discovery/domain/search_match_models.dart';

import 'venue_search_result.dart';

/// Unified venue search result with matched entity context.
class SearchVenueMatch implements DiscoveryRankableMatch {
  const SearchVenueMatch({
    required this.catalogIndex,
    required this.venue,
    this.directVenueMatch = false,
    this.matchedDrinks = const [],
    this.matchedDeals = const [],
    this.matchedEvents = const [],
    this.matchedTrails = const [],
    this.rankScore = 0,
  });

  @override
  final int catalogIndex;

  @override
  final VenueSearchResult venue;

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

  /// Primary matched line for the venue card — drinks, events, deals, trails,
  /// then venue name, following mobile search priority with Vexda web emojis.
  String get matchLine {
    if (matchedDrinks.isNotEmpty) {
      return 'Matched:\n🍸 ${_joinLabels(matchedDrinks.map((d) => d.name))}';
    }
    if (matchedEvents.isNotEmpty) {
      return 'Matched:\n🎵 ${_joinLabels(matchedEvents.map((e) => e.title))}';
    }
    if (matchedDeals.isNotEmpty) {
      return 'Matched:\n🔥 ${_joinLabels(matchedDeals.map((d) => d.title))}';
    }
    if (matchedTrails.isNotEmpty) {
      return 'Matched:\n🗺️ ${_joinLabels(matchedTrails.map((t) => t.name))}';
    }
    if (directVenueMatch) {
      return 'Matched:\n📍 ${venue.name}';
    }
    return venue.resultReason;
  }

  SearchVenueMatch copyWith({
    bool? directVenueMatch,
    List<MatchedDrink>? matchedDrinks,
    List<MatchedDeal>? matchedDeals,
    List<MatchedEvent>? matchedEvents,
    List<MatchedTrail>? matchedTrails,
    int? rankScore,
  }) {
    return SearchVenueMatch(
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

  static String _joinLabels(Iterable<String> labels, {int max = 2}) {
    final values = labels.where((value) => value.trim().isNotEmpty).take(max);
    final joined = values.join(', ');
    final total = labels.where((value) => value.trim().isNotEmpty).length;
    if (total > max) {
      return '$joined +${total - max} more';
    }
    return joined;
  }
}

/// Unified search response for the search page.
class UnifiedSearchResponse {
  const UnifiedSearchResponse({
    required this.matches,
    required this.groupCounts,
  });

  final List<SearchVenueMatch> matches;
  final SearchGroupCounts groupCounts;

  List<int> get catalogIndices =>
      matches.map((match) => match.catalogIndex).toList(growable: false);

  static const empty = UnifiedSearchResponse(
    matches: [],
    groupCounts: SearchGroupCounts(),
  );
}
