import '../domain/trail_generation_policy.dart';
import '../domain/trail_result.dart';
import 'ports/trail_clock.dart';

/// Generated trail proposal service.
final class TrailGenerationService {
  const TrailGenerationService({this.clock});

  final TrailClock? clock;

  TrailResult<TrailGenerationProposal> generateDraft({
    required List<TrailGenerationCandidate> candidates,
    DateTime? now,
    String trailId = TrailGenerationPolicy.activeTrailDocumentId,
  }) {
    final evaluationTime = now ?? clock?.now() ?? DateTime.now();
    return TrailGenerationPolicy.generateDraft(
      candidates: candidates,
      now: evaluationTime,
      trailId: trailId,
    );
  }
}
