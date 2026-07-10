import 'venue_search_result.dart';

/// A drink matched during unified search.
class MatchedDrink {
  const MatchedDrink({
    required this.id,
    required this.name,
    this.category = '',
    this.price = '',
    this.available = false,
  });

  final String id;
  final String name;
  final String category;
  final String price;
  final bool available;
}

/// A deal matched during unified search.
class MatchedDeal {
  const MatchedDeal({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

/// An event matched during unified search.
class MatchedEvent {
  const MatchedEvent({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

/// A trail matched during unified search.
class MatchedTrail {
  const MatchedTrail({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

/// Counts of matched items by source type for grouped result headers.
class SearchGroupCounts {
  const SearchGroupCounts({
    this.venues = 0,
    this.drinks = 0,
    this.deals = 0,
    this.events = 0,
    this.trails = 0,
  });

  final int venues;
  final int drinks;
  final int deals;
  final int events;
  final int trails;

  bool get isEmpty =>
      venues == 0 && drinks == 0 && deals == 0 && events == 0 && trails == 0;

  Iterable<({String label, int count})> get nonEmptyGroups sync* {
    if (venues > 0) yield (label: 'Venues', count: venues);
    if (drinks > 0) yield (label: 'Drinks', count: drinks);
    if (deals > 0) yield (label: 'Deals', count: deals);
    if (events > 0) yield (label: 'Events', count: events);
    if (trails > 0) yield (label: 'Trails', count: trails);
  }
}

/// Unified venue search result with matched entity context.
class SearchVenueMatch {
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

  final int catalogIndex;
  final VenueSearchResult venue;
  final bool directVenueMatch;
  final List<MatchedDrink> matchedDrinks;
  final List<MatchedDeal> matchedDeals;
  final List<MatchedEvent> matchedEvents;
  final List<MatchedTrail> matchedTrails;
  final int rankScore;

  bool get hasDrinkMatches => matchedDrinks.isNotEmpty;
  bool get hasDealMatches => matchedDeals.isNotEmpty;
  bool get hasEventMatches => matchedEvents.isNotEmpty;
  bool get hasTrailMatches => matchedTrails.isNotEmpty;

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
