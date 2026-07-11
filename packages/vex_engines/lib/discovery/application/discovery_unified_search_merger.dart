import '../domain/discovery_rankable_match.dart';
import '../domain/discovery_venue_searchable.dart';
import '../domain/search_match_models.dart';

/// Factory callbacks for venue-grouped unified search matches.
abstract interface class DiscoveryUnifiedSearchMatchFactory<
    T extends DiscoveryRankableMatch> {
  T buildBase({
    required int catalogIndex,
    required DiscoveryVenueMatchable venue,
    bool directVenueMatch = false,
  });

  T merge(
    T existing, {
    bool directVenueMatch = false,
    MatchedDrink? drink,
    MatchedDeal? deal,
    MatchedEvent? event,
    MatchedTrail? trail,
  });
}

/// Merges venue matches and deduplicates matched entities per venue.
final class DiscoveryUnifiedSearchMerger {
  const DiscoveryUnifiedSearchMerger();

  Map<String, T> upsertDirectVenue<T extends DiscoveryRankableMatch>({
    required Map<String, T> grouped,
    required String venueId,
    required T match,
    required DiscoveryUnifiedSearchMatchFactory<T> factory,
  }) {
    final updated = Map<String, T>.from(grouped);
    final existing = updated[venueId];
    updated[venueId] = existing == null
        ? match
        : factory.merge(existing, directVenueMatch: true);
    return updated;
  }

  Map<String, T> upsertEntity<T extends DiscoveryRankableMatch>({
    required Map<String, T> grouped,
    required String venueId,
    required T baseMatch,
    MatchedDrink? drink,
    MatchedDeal? deal,
    MatchedEvent? event,
    MatchedTrail? trail,
    required DiscoveryUnifiedSearchMatchFactory<T> factory,
  }) {
    final updated = Map<String, T>.from(grouped);
    final existing = updated[venueId];
    final seed = existing ?? baseMatch;
    updated[venueId] = factory.merge(
      seed,
      drink: drink,
      deal: deal,
      event: event,
      trail: trail,
    );
    return updated;
  }
}
