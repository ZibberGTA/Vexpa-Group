import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';

import '../domain/trail.dart';
import '../domain/trail_generation_policy.dart';
import '../domain/trail_result.dart';
import 'ports/trail_clock.dart';
import 'trail_application_result.dart';
import 'trail_generation_service.dart';
import 'trail_persistence_mapper.dart';

/// Generates draft trails and persists them through repository contracts.
final class TrailGenerationApplicationService {
  const TrailGenerationApplicationService({
    required this.trailRepository,
    this.generationService = const TrailGenerationService(),
    this.clock,
  });

  final TrailRepository trailRepository;
  final TrailGenerationService generationService;
  final TrailClock? clock;

  Future<TrailApplicationResult<Trail>> generateAndPersistDraft({
    required List<TrailGenerationCandidate> candidates,
    String trailId = TrailGenerationPolicy.activeTrailDocumentId,
    DateTime? now,
  }) async {
    final planResult = generationService.generateDraft(
      candidates: candidates,
      now: now ?? clock?.now(),
      trailId: trailId,
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }

    final proposal = (planResult as TrailSuccess).value;
    final snapshot = TrailPersistenceMapper.toSnapshot(proposal.trail);
    final result = await trailRepository.replaceDocument(
      ReplaceTrailDocumentCommand(trailId: trailId, snapshot: snapshot),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }

    return _mapSnapshot((result as DataSuccess).value);
  }

  Future<TrailApplicationResult<Trail>> _mapSnapshot(
    TrailSnapshot snapshot,
  ) async {
    final trail = TrailPersistenceMapper.mapTrailOrNull(snapshot);
    if (trail == null) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        'Failed to map generated trail snapshot.',
      );
    }
    return TrailApplicationSuccess(trail);
  }
}
