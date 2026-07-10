import '../domain/discovery_related_venue.dart';
import '../shared/discovery_geo_utils.dart';

/// Ranks similar and nearby venues from an already-loaded candidate list.
final class DiscoveryRelatedVenueService {
  const DiscoveryRelatedVenueService();

  List<T> rankSimilar<T extends DiscoveryRelatedVenueCandidate>({
    required DiscoveryRelatedVenueSubject subject,
    required Iterable<T> candidates,
    int limit = 4,
  }) {
    final category = subject.category.toLowerCase();
    final city = subject.city.toLowerCase();

    final scored = candidates
        .where((candidate) => candidate.id != subject.id)
        .map((candidate) {
          var score = 0;
          if (candidate.venueType.toLowerCase() == category) score += 3;
          if (candidate.city.toLowerCase() == city && city.isNotEmpty)
            score += 2;
          for (final tag in subject.tags) {
            if (candidate.tags.any(
              (candidateTag) => candidateTag.toLowerCase() == tag.toLowerCase(),
            )) {
              score += 1;
            }
          }
          return (candidate: candidate, score: score);
        })
        .toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .where((entry) => entry.score > 0)
        .map((entry) => entry.candidate)
        .take(limit)
        .toList();
  }

  List<T> rankNearby<T extends DiscoveryRelatedVenueCandidate>({
    required DiscoveryRelatedVenueSubject subject,
    required Iterable<T> candidates,
    int limit = 4,
  }) {
    final filtered = candidates.where(
      (candidate) => candidate.id != subject.id,
    );

    if (!subject.hasCoordinates) {
      return filtered
          .where(
            (candidate) =>
                subject.city.isNotEmpty &&
                candidate.city.toLowerCase() == subject.city.toLowerCase(),
          )
          .take(limit)
          .toList();
    }

    final scored = filtered.map((candidate) {
      final distance = DiscoveryGeoUtils.distanceKm(
        lat1: subject.latitude!,
        lng1: subject.longitude!,
        lat2: candidate.latitude,
        lng2: candidate.longitude,
      );
      return (candidate: candidate, distance: distance);
    }).toList();

    scored.sort((a, b) => a.distance.compareTo(b.distance));
    return scored.map((entry) => entry.candidate).take(limit).toList();
  }
}
