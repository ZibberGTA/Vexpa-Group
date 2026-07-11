import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';

/// Compatibility facade for venue search-term indexing.
class SearchTermBuilder {
  static List<String> build({
    required String venueName,
    required String category,
    String address = '',
    String description = '',
    List<String> drinks = const [],
    List<String> deals = const [],
    List<String> events = const [],
  }) {
    return DiscoveryVenueSearchTermBuilder.buildVenueIndexTerms(
      venueName: venueName,
      category: category,
      address: address,
      description: description,
      drinks: drinks,
      deals: deals,
      events: events,
    );
  }
}
