import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';

import '../domain/trail.dart';
import 'ports/trail_clock.dart';
import 'trail_application_result.dart';
import 'trail_persistence_mapper.dart';
import 'trail_visibility_service.dart';

/// Repository-backed trail discovery orchestration.
final class TrailDiscoveryApplicationService {
  const TrailDiscoveryApplicationService({
    required this.trailRepository,
    this.visibilityService = const TrailVisibilityService(),
    this.clock,
  });

  final TrailRepository trailRepository;
  final TrailVisibilityService visibilityService;
  final TrailClock? clock;

  Future<TrailApplicationResult<List<Trail>>> listVisibleTrails({
    DateTime? now,
    TrailListQuery? query,
  }) async {
    final evaluationTime = now ?? clock?.now() ?? DateTime.now();
    final listQuery = query ?? TrailListQuery(limit: 100);
    final result = await trailRepository.list(listQuery);
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }

    final trails = <Trail>[];
    for (final snapshot in (result as DataSuccess).value) {
      final trail = TrailPersistenceMapper.mapTrailOrNull(snapshot);
      if (trail == null) {
        return const TrailApplicationFailure(
          TrailApplicationFailureCodes.mappingFailure,
          'Failed to map trail snapshot.',
        );
      }
      final visible = visibilityService.assessVisibility(
        trail: trail,
        now: evaluationTime,
      );
      if (visible.isVisible) {
        trails.add(trail);
      }
    }

    trails.sort((a, b) {
      final typeCompare = a.trailType.index.compareTo(b.trailType.index);
      if (typeCompare != 0) return typeCompare;
      return b.averageRating.compareTo(a.averageRating);
    });

    return TrailApplicationSuccess(trails);
  }

  Stream<TrailApplicationResult<List<Trail>>> watchVisibleTrails({
    DateTime? now,
    TrailListQuery? query,
  }) {
    final listQuery = query ?? TrailListQuery(limit: 100);
    return trailRepository.watchList(listQuery).asyncMap((result) async {
      if (result case DataFailure(error: final error)) {
        return fromRepositoryFailure<List<Trail>>(
          error.message,
          code: error.code,
        );
      }
      final evaluationTime = now ?? clock?.now() ?? DateTime.now();
      final trails = <Trail>[];
      for (final snapshot in (result as DataSuccess).value) {
        final trail = TrailPersistenceMapper.mapTrailOrNull(snapshot);
        if (trail == null) continue;
        if (visibilityService
            .assessVisibility(trail: trail, now: evaluationTime)
            .isVisible) {
          trails.add(trail);
        }
      }
      trails.sort((a, b) {
        final typeCompare = a.trailType.index.compareTo(b.trailType.index);
        if (typeCompare != 0) return typeCompare;
        return b.averageRating.compareTo(a.averageRating);
      });
      return TrailApplicationSuccess(trails);
    });
  }

  Future<TrailApplicationResult<Trail>> getTrail(String trailId) async {
    final result = await trailRepository.get(trailId);
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    final trail = TrailPersistenceMapper.mapTrailOrNull(
      (result as DataSuccess).value,
    );
    if (trail == null) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        'Failed to map trail snapshot.',
      );
    }
    return TrailApplicationSuccess(trail);
  }
}
