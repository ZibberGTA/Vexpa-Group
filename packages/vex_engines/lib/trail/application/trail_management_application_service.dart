import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';

import '../domain/trail.dart';
import '../domain/trail_action.dart';
import '../domain/trail_result.dart';
import '../domain/trail_publication_readiness.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_stop_order_policy.dart';
import '../domain/trail_type.dart';
import 'ports/trail_clock.dart';
import 'trail_application_result.dart';
import 'trail_lifecycle_service.dart';
import 'trail_persistence_coordinator.dart';
import 'trail_persistence_mapper.dart';
import 'trail_publication_service.dart';

/// Repository-backed trail admin/management orchestration.
final class TrailManagementApplicationService {
  const TrailManagementApplicationService({
    required this.trailRepository,
    required this.coordinator,
    this.lifecycleService = const TrailLifecycleService(),
    this.publicationService = const TrailPublicationService(),
    this.clock,
  });

  final TrailRepository trailRepository;
  final TrailPersistenceCoordinator coordinator;
  final TrailLifecycleService lifecycleService;
  final TrailPublicationService publicationService;
  final TrailClock? clock;

  Future<TrailApplicationResult<Trail>> createDraft({
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) async {
    final result = await trailRepository.create(
      CreateTrailCommand(
        name: name,
        description: description,
        bannerImageUrl: bannerImageUrl,
        area: area,
        availabilityStart: availabilityStart,
        availabilityEnd: availabilityEnd,
        trailType: _trailTypeValue(trailType),
      ),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    return _mapSnapshot((result as DataSuccess).value);
  }

  Future<TrailApplicationResult<Trail>> updateMetadata({
    required String trailId,
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) async {
    final result = await trailRepository.updateMetadata(
      UpdateTrailMetadataCommand(
        trailId: trailId,
        name: name,
        description: description,
        bannerImageUrl: bannerImageUrl,
        area: area,
        availabilityStart: availabilityStart,
        availabilityEnd: availabilityEnd,
        trailType: _trailTypeValue(trailType),
      ),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    return _mapSnapshot((result as DataSuccess).value);
  }

  Future<TrailApplicationResult<Trail>> updateStops({
    required String trailId,
    required List<TrailStop> stops,
  }) async {
    final ordered = TrailStopOrderPolicy.renumberContiguous(stops);
    final availabilityStart = ordered.isEmpty
        ? (clock?.now() ?? DateTime.now())
        : ordered.first.arriveAt;
    final availabilityEnd = ordered.isEmpty
        ? (clock?.now() ?? DateTime.now())
        : ordered.last.leaveAt;
    final durationMinutes = availabilityEnd
        .difference(availabilityStart)
        .inMinutes;

    final result = await trailRepository.updateStops(
      UpdateTrailStopsCommand(
        trailId: trailId,
        stops: ordered.map(TrailPersistenceMapper.toStopSnapshot).toList(),
        availabilityStart: availabilityStart,
        availabilityEnd: availabilityEnd,
        estimatedDurationMinutes: durationMinutes,
        venueCount: ordered.length,
      ),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    return _mapSnapshot((result as DataSuccess).value);
  }

  Future<TrailApplicationResult<TrailPublicationReadiness>>
  assessPublicationReadiness(String trailId) async {
    final loaded = await _loadTrail(trailId);
    if (loaded case TrailApplicationFailure(
      code: final code,
      message: final message,
      cause: final cause,
    )) {
      return TrailApplicationFailure(code, message, cause: cause);
    }
    return TrailApplicationSuccess(
      publicationService.assessReadiness(
        (loaded as TrailApplicationSuccess).value,
      ),
    );
  }

  Future<TrailApplicationResult<Trail>> publishValidated(String trailId) async {
    final loaded = await _loadTrail(trailId);
    if (loaded case TrailApplicationFailure(
      code: final code,
      message: final message,
      cause: final cause,
    )) {
      return TrailApplicationFailure(code, message, cause: cause);
    }
    final trail = (loaded as TrailApplicationSuccess).value;
    if (!publicationService.isReady(trail)) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.domainFailure,
        'Trail is not ready to publish.',
      );
    }
    return _applyLifecycle(trail, TrailLifecycleAction.publish);
  }

  Future<TrailApplicationResult<Trail>> publishLegacyCompatible(
    String trailId,
  ) async {
    final loaded = await _loadTrail(trailId);
    if (loaded case TrailApplicationFailure(
      code: final code,
      message: final message,
      cause: final cause,
    )) {
      return TrailApplicationFailure(code, message, cause: cause);
    }
    return _applyLifecycle(
      (loaded as TrailApplicationSuccess).value,
      TrailLifecycleAction.publish,
      requirePublicationReadiness: false,
    );
  }

  Future<TrailApplicationResult<Trail>> unpublish(String trailId) async {
    final loaded = await _loadTrail(trailId);
    if (loaded case TrailApplicationFailure(
      code: final code,
      message: final message,
      cause: final cause,
    )) {
      return TrailApplicationFailure(code, message, cause: cause);
    }
    return _applyLifecycle(
      (loaded as TrailApplicationSuccess).value,
      TrailLifecycleAction.unpublish,
    );
  }

  Future<TrailApplicationResult<Trail>> archive(String trailId) async {
    final loaded = await _loadTrail(trailId);
    if (loaded case TrailApplicationFailure(
      code: final code,
      message: final message,
      cause: final cause,
    )) {
      return TrailApplicationFailure(code, message, cause: cause);
    }
    return _applyLifecycle(
      (loaded as TrailApplicationSuccess).value,
      TrailLifecycleAction.archive,
    );
  }

  Future<TrailApplicationResult<Trail>> duplicate(String sourceTrailId) async {
    final result = await trailRepository.duplicate(
      DuplicateTrailCommand(sourceTrailId: sourceTrailId),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    return _mapSnapshot((result as DataSuccess).value);
  }

  Future<TrailApplicationResult<void>> delete(String trailId) async {
    final result = await trailRepository.delete(
      DeleteTrailCommand(trailId: trailId),
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    return const TrailApplicationSuccess(null);
  }

  Future<TrailApplicationResult<Trail>> _applyLifecycle(
    Trail trail,
    TrailLifecycleAction action, {
    bool requirePublicationReadiness = true,
  }) async {
    final planResult = lifecycleService.plan(
      trail: trail,
      action: action,
      occurredAt: clock?.now() ?? DateTime.now(),
      eventId: '${action.name}-${trail.id}',
      requirePublicationReadiness:
          requirePublicationReadiness && action == TrailLifecycleAction.publish,
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }

    final DataResult<TrailSnapshot> writeResult = switch (action) {
      TrailLifecycleAction.publish => await trailRepository.publish(
        PublishTrailCommand(trailId: trail.id),
      ),
      TrailLifecycleAction.unpublish => await trailRepository.unpublish(
        UnpublishTrailCommand(trailId: trail.id),
      ),
      TrailLifecycleAction.archive || TrailLifecycleAction.disable =>
        await trailRepository.archive(ArchiveTrailCommand(trailId: trail.id)),
      _ => await trailRepository.get(trail.id),
    };

    if (writeResult case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }

    final events = (planResult as TrailSuccess).value.events;
    final publishEvents = await coordinator.publishEvents(events);
    if (publishEvents case TrailApplicationFailure()) {
      return TrailApplicationFailure(
        (publishEvents as TrailApplicationFailure).code,
        (publishEvents as TrailApplicationFailure).message,
        cause: (publishEvents as TrailApplicationFailure).cause,
      );
    }

    return _mapSnapshot((writeResult as DataSuccess).value);
  }

  Future<TrailApplicationResult<Trail>> _loadTrail(String trailId) async {
    final result = await trailRepository.get(trailId);
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
        'Failed to map trail snapshot.',
      );
    }
    return TrailApplicationSuccess(trail);
  }

  static TrailTypeValue _trailTypeValue(TrailType type) => switch (type) {
    TrailType.curated => TrailTypeValue.curated,
    TrailType.generated => TrailTypeValue.generated,
  };
}
