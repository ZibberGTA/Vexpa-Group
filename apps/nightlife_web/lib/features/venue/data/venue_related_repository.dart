import 'dart:math' as math;

import '../../search/data/search_venue_catalog.dart';
import '../../search/data/search_venue_repository.dart';
import '../../search/models/venue_search_result.dart';
import '../models/venue_details_view.dart';

/// Related venue suggestions for the venue details discovery section.
class VenueRelatedRepository {
  VenueRelatedRepository({
    SearchVenueRepository? searchRepository,
    this._catalogOverride,
  }) : _searchRepository = searchRepository ?? SearchVenueRepository();

  VenueRelatedRepository.withCatalog(this._catalogOverride)
      : _searchRepository = SearchVenueRepository();

  final SearchVenueRepository _searchRepository;
  final SearchVenueCatalog? _catalogOverride;

  Future<VenueRelatedSuggestions> loadSuggestions(VenueDetailsView venue) async {
    final catalog =
        _catalogOverride ?? await _searchRepository.loadVenues();
    final candidates =
        catalog.venues.where((item) => item.id != venue.id).toList();

    final similar = _similarVenues(venue, candidates);
    final nearby = _nearbyVenues(venue, candidates);

    return VenueRelatedSuggestions(
      similarVenues: similar,
      nearbyVenues: nearby,
    );
  }

  List<VenueSearchResult> _similarVenues(
    VenueDetailsView venue,
    List<VenueSearchResult> candidates,
  ) {
    final category = venue.displayCategory.toLowerCase();
    final city = venue.city.toLowerCase();

    final scored = candidates.map((candidate) {
      var score = 0;
      if (candidate.venueType.toLowerCase() == category) score += 3;
      if (candidate.city.toLowerCase() == city && city.isNotEmpty) score += 2;
      for (final tag in venue.tags) {
        if (candidate.tags.any(
          (candidateTag) =>
              candidateTag.toLowerCase() == tag.toLowerCase(),
        )) {
          score += 1;
        }
      }
      return (candidate: candidate, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .where((entry) => entry.score > 0)
        .map((entry) => entry.candidate)
        .take(4)
        .toList();
  }

  List<VenueSearchResult> _nearbyVenues(
    VenueDetailsView venue,
    List<VenueSearchResult> candidates,
  ) {
    if (!venue.hasCoordinates) {
      return candidates
          .where(
            (candidate) =>
                venue.city.isNotEmpty &&
                candidate.city.toLowerCase() == venue.city.toLowerCase(),
          )
          .take(4)
          .toList();
    }

    final scored = candidates.map((candidate) {
      final distance = _distanceKm(
        venue.latitude!,
        venue.longitude!,
        candidate.latitude,
        candidate.longitude,
      );
      return (candidate: candidate, distance: distance);
    }).toList();

    scored.sort((a, b) => a.distance.compareTo(b.distance));
    return scored.map((entry) => entry.candidate).take(4).toList();
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double value) => value * math.pi / 180;
}

class VenueRelatedSuggestions {
  const VenueRelatedSuggestions({
    required this.similarVenues,
    required this.nearbyVenues,
  });

  final List<VenueSearchResult> similarVenues;
  final List<VenueSearchResult> nearbyVenues;

  bool get hasSuggestions =>
      similarVenues.isNotEmpty || nearbyVenues.isNotEmpty;
}
