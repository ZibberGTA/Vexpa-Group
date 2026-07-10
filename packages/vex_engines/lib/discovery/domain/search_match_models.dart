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
  const MatchedDeal({required this.id, required this.title});

  final String id;
  final String title;
}

/// An event matched during unified search.
class MatchedEvent {
  const MatchedEvent({required this.id, required this.title});

  final String id;
  final String title;
}

/// A trail matched during unified search.
class MatchedTrail {
  const MatchedTrail({required this.id, required this.name});

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
