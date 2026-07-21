import 'trail.dart';
import 'trail_result.dart';
import 'trail_status.dart';
import 'trail_stop.dart';
import 'trail_type.dart';

/// Candidate venue input for generated trail proposals.
final class TrailGenerationCandidate {
  const TrailGenerationCandidate({
    required this.venueId,
    required this.name,
    required this.address,
    required this.bannerImageUrl,
    required this.logoUrl,
    required this.crowdLevel,
    required this.category,
    required this.hasDeals,
    required this.featureTags,
  });

  final String venueId;
  final String name;
  final String address;
  final String bannerImageUrl;
  final String logoUrl;
  final String crowdLevel;
  final String category;
  final bool hasDeals;
  final List<String> featureTags;
}

/// Generated trail proposal (not persisted).
final class TrailGenerationProposal {
  const TrailGenerationProposal({
    required this.trail,
    required this.scoredCandidates,
  });

  final Trail trail;
  final List<({TrailGenerationCandidate candidate, int score})>
  scoredCandidates;
}

/// Pure generation/scoring matching mobile `generateDraftTrail`.
abstract final class TrailGenerationPolicy {
  static const activeTrailDocumentId = 'activeTrail';
  static const maxStops = 4;
  static const defaultTrailName = "Tonight's Trail";
  static const defaultDescription =
      'Auto-generated from lively and buzzing venues';

  static int scoreCandidate(TrailGenerationCandidate candidate) {
    var score = 0;
    switch (candidate.crowdLevel.trim().toLowerCase()) {
      case 'packed':
        score += 45;
        break;
      case 'busy':
        score += 35;
        break;
      case 'medium':
      case 'steady':
        score += 22;
        break;
      case 'quiet':
        score += 8;
        break;
      default:
        score += 10;
    }

    if (candidate.hasDeals) score += 10;
    final category = candidate.category.toLowerCase();
    if (category.contains('cocktail')) score += 8;
    if (category.contains('bar')) score += 6;
    if (category.contains('club')) score += 6;
    if (candidate.bannerImageUrl.trim().isNotEmpty) score += 4;
    if (candidate.featureTags.isNotEmpty) score += 4;
    return score;
  }

  static TrailResult<TrailGenerationProposal> generateDraft({
    required List<TrailGenerationCandidate> candidates,
    required DateTime now,
    String trailId = activeTrailDocumentId,
  }) {
    if (candidates.isEmpty) {
      return const TrailFailure(
        TrailFailureCodes.noCandidateVenues,
        'No candidate venues supplied.',
      );
    }

    final scored = [
      for (final candidate in candidates)
        (candidate: candidate, score: scoreCandidate(candidate)),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final selected = scored.take(maxStops).toList();
    final startOfDay = DateTime(now.year, now.month, now.day, 19);
    final trailStart = now.isAfter(startOfDay)
        ? now.add(const Duration(minutes: 30))
        : startOfDay;

    final stops = <TrailStop>[];
    for (var i = 0; i < selected.length; i++) {
      final candidate = selected[i].candidate;
      final arriveAt = trailStart.add(Duration(minutes: i * 85));
      final leaveAt = arriveAt.add(const Duration(minutes: 75));
      stops.add(
        TrailStop(
          venueId: candidate.venueId,
          venueName: candidate.name.isEmpty ? 'Venue' : candidate.name,
          address: candidate.address,
          bannerImageUrl: candidate.bannerImageUrl,
          logoUrl: candidate.logoUrl,
          order: i + 1,
          score: selected[i].score,
          arriveAt: arriveAt,
          leaveAt: leaveAt,
        ),
      );
    }

    final end = stops.isEmpty
        ? trailStart.add(const Duration(hours: 5))
        : stops.last.leaveAt;

    final trail = Trail(
      id: trailId,
      name: defaultTrailName,
      description: defaultDescription,
      bannerImageUrl: '',
      status: TrailStatus.draft,
      published: false,
      area: '',
      availabilityStart: trailStart,
      availabilityEnd: end,
      estimatedDurationMinutes: end.difference(trailStart).inMinutes,
      estimatedWalkingDistance: 0,
      averageRating: 0,
      venueCount: stops.length,
      trailType: TrailType.curated,
      generatedAt: now,
      stops: stops,
    );

    return TrailSuccess(
      TrailGenerationProposal(trail: trail, scoredCandidates: selected),
    );
  }
}
