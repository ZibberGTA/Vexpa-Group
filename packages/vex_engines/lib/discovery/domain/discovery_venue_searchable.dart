/// Engine-neutral venue fields used for text matching and ranking.
abstract interface class DiscoveryVenueSearchable {
  String get name;

  String get city;

  String get area;

  String get postcode;

  String get venueType;

  List<String> get tags;
}

/// Venue fields required for catalog filtering during discovery search.
abstract interface class DiscoveryVenueMatchable
    implements DiscoveryVenueSearchable {
  String get id;

  bool get isOpen;
}
