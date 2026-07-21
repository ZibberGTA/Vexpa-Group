import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';
import '../domain/trail.dart';
import '../domain/trail_action.dart';
import '../domain/trail_activity_draft.dart';
import '../domain/trail_progress.dart';
import '../domain/trail_result.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_transition_plan.dart';
import 'ports/trail_clock.dart';
import 'ports/trail_user_context_port.dart';
import 'trail_application_result.dart';
import 'trail_persistence_coordinator.dart';
import 'trail_persistence_mapper.dart';
import 'trail_progress_service.dart';

/// Repository-backed customer progress orchestration.
final class TrailProgressApplicationService {
  const TrailProgressApplicationService({
    required this.trailRepository,
    required this.progressRepository,
    required this.coordinator,
    required this.userContext,
    this.progressService = const TrailProgressService(),
    this.clock,
  });

  final TrailRepository trailRepository;
  final TrailProgressRepository progressRepository;
  final TrailPersistenceCoordinator coordinator;
  final TrailUserContextPort userContext;
  final TrailProgressService progressService;
  final TrailClock? clock;

  Future<TrailApplicationResult<TrailProgress>> join({
    required String trailId,
    Trail? trail,
  }) async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required to join a trail.',
      );
    }

    final Trail trailModel;
    if (trail != null) {
      trailModel = trail;
    } else {
      final loaded = await _loadTrailModel(trailId);
      if (loaded case TrailApplicationFailure()) {
        return loaded as TrailApplicationFailure<TrailProgress>;
      }
      trailModel = (loaded as TrailApplicationSuccess<Trail>).value;
    }

    final existing = await progressRepository.get(
      userId: user.userId!,
      trailId: trailId,
    );
    TrailProgress? existingProgress;
    if (existing case DataSuccess(value: final progress)) {
      existingProgress = TrailPersistenceMapper.mapProgressOrNull(progress);
    }

    final now = clock?.now() ?? DateTime.now();
    final planResult = progressService.planJoin(
      trail: trailModel,
      userId: user.userId!,
      occurredAt: now,
      eventId: 'join-$trailId',
      existingProgress: existingProgress,
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }
    return _executePlan(
      plan: (planResult as TrailSuccess).value,
      userId: user.userId!,
      isAnonymous: user.isAnonymous,
    );
  }

  Future<TrailApplicationResult<TrailProgress>> checkIn({
    required Trail trail,
    required TrailStop stop,
    required int stopIndex,
    required TrailProgress progress,
    double? userLatitude,
    double? userLongitude,
    double? venueLatitude,
    double? venueLongitude,
    double? presenceRadiusMeters,
  }) async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required.',
      );
    }

    final now = clock?.now() ?? DateTime.now();
    final planResult = progressService.planCheckIn(
      trail: trail,
      progress: progress,
      stop: stop,
      stopIndex: stopIndex,
      userId: user.userId!,
      occurredAt: now,
      eventId: 'checkin-${stop.order}',
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      venueLatitude: venueLatitude,
      venueLongitude: venueLongitude,
      presenceRadiusMeters: presenceRadiusMeters,
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }
    final plan = (planResult as TrailSuccess).value;
    if (plan.noOp) {
      return TrailApplicationSuccess(progress, warnings: plan.warnings);
    }
    return _executePlan(
      plan: plan,
      userId: user.userId!,
      isAnonymous: user.isAnonymous,
    );
  }

  Future<TrailApplicationResult<TrailProgress>> continueStop({
    required Trail trail,
    required TrailStop stop,
    required int stopIndex,
    required TrailProgress progress,
  }) async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required.',
      );
    }

    final now = clock?.now() ?? DateTime.now();
    final planResult = progressService.planContinue(
      trail: trail,
      progress: progress,
      stop: stop,
      stopIndex: stopIndex,
      userId: user.userId!,
      occurredAt: now,
      eventId: 'continue-${stop.order}',
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }
    return _executePlan(
      plan: (planResult as TrailSuccess).value,
      userId: user.userId!,
      isAnonymous: user.isAnonymous,
    );
  }

  Future<TrailApplicationResult<TrailProgress>> skipStop({
    required Trail trail,
    required TrailStop stop,
    required int stopIndex,
    required TrailProgress progress,
  }) async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required.',
      );
    }

    final now = clock?.now() ?? DateTime.now();
    final planResult = progressService.planSkip(
      trail: trail,
      progress: progress,
      stop: stop,
      stopIndex: stopIndex,
      userId: user.userId!,
      occurredAt: now,
      eventId: 'skip-${stop.order}',
    );
    if (planResult case TrailFailure()) {
      return fromTrailFailure(planResult as TrailFailure);
    }
    return _executePlan(
      plan: (planResult as TrailSuccess).value,
      userId: user.userId!,
      isAnonymous: user.isAnonymous,
    );
  }

  Stream<TrailApplicationResult<TrailProgress?>> watchProgress(String trailId) {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return Stream.value(
        const TrailApplicationFailure(
          TrailApplicationFailureCodes.authenticationRequired,
          'Authentication is required.',
        ),
      );
    }
    return progressRepository.watch(userId: user.userId!, trailId: trailId).map(
      (result) {
        if (result case DataFailure(error: final error)) {
          return fromRepositoryFailure<TrailProgress?>(
            error.message,
            code: error.code,
          );
        }
        final snapshot = (result as DataSuccess<TrailProgressSnapshot?>).value;
        if (snapshot == null) {
          return const TrailApplicationSuccess<TrailProgress?>(null);
        }
        final mapped = TrailPersistenceMapper.mapProgressOrNull(snapshot);
        if (mapped == null) {
          return const TrailApplicationFailure(
            TrailApplicationFailureCodes.mappingFailure,
            'Failed to map progress snapshot.',
          );
        }
        return TrailApplicationSuccess<TrailProgress?>(mapped);
      },
    );
  }

  Future<TrailApplicationResult<String?>> resolveActiveTrailId() async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required.',
      );
    }
    final result = await progressRepository.getActiveState(
      userId: user.userId!,
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    final state = (result as DataSuccess<TrailActiveStateSnapshot?>).value;
    return TrailApplicationSuccess(state?.activeTrailId);
  }

  Future<TrailApplicationResult<TrailProgress>> resume(String trailId) async {
    return getProgress(trailId);
  }

  Future<TrailApplicationResult<TrailProgress>> getProgress(
    String trailId,
  ) async {
    final user = userContext.currentUser();
    if (!user.isAuthenticated) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication is required.',
      );
    }
    final result = await progressRepository.get(
      userId: user.userId!,
      trailId: trailId,
    );
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }
    final progress = TrailPersistenceMapper.mapProgressOrNull(
      (result as DataSuccess).value,
    );
    if (progress == null) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        'Failed to map progress snapshot.',
      );
    }
    return TrailApplicationSuccess(progress);
  }

  Future<TrailApplicationResult<Trail>> _loadTrailModel(String trailId) async {
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

  Future<TrailApplicationResult<TrailProgress>> _executePlan({
    required TrailProgressTransitionPlan plan,
    required String userId,
    required bool isAnonymous,
  }) async {
    final proposed = plan.proposedProgress;
    final stopStates = TrailPersistenceMapper.toStopStatesSnapshot(
      proposed.stopStates,
    );

    final DataResult<TrailProgressSnapshot> writeResult = switch (plan.action) {
      TrailProgressAction.join => await progressRepository.createProgress(
        CreateTrailProgressCommand(
          userId: userId,
          trailId: proposed.trailId,
          trailGeneratedAt: proposed.trailGeneratedAt ?? DateTime.now(),
          stopStates: stopStates,
          mirrorLegacyProgress: plan.mirrorLegacyProgress,
        ),
      ),
      TrailProgressAction.checkIn => await progressRepository.checkIn(
        CheckInTrailProgressCommand(
          userId: userId,
          trailId: proposed.trailId,
          trailGeneratedAt: proposed.trailGeneratedAt ?? DateTime.now(),
          currentStop: proposed.currentStopIndex,
          checkedInStopOrder: proposed.checkedInStopOrders.isEmpty
              ? (proposed.lastCheckedInStopOrder ?? 0)
              : proposed.checkedInStopOrders.last,
          stopStates: stopStates,
          completed: proposed.completed,
          lastCheckedInVenueId: proposed.lastCheckedInVenueId ?? '',
          lastCheckedInStopOrder: proposed.lastCheckedInStopOrder ?? 0,
          mirrorLegacyProgress: plan.mirrorLegacyProgress,
        ),
      ),
      TrailProgressAction.continueStop =>
        await progressRepository.continueProgress(
          ContinueTrailProgressCommand(
            userId: userId,
            trailId: proposed.trailId,
            trailGeneratedAt: proposed.trailGeneratedAt ?? DateTime.now(),
            currentStop: proposed.currentStopIndex,
            stopStates: stopStates,
            completed: proposed.completed,
            mirrorLegacyProgress: plan.mirrorLegacyProgress,
          ),
        ),
      TrailProgressAction.skipStop => await progressRepository.skipStop(
        SkipTrailProgressCommand(
          userId: userId,
          trailId: proposed.trailId,
          trailGeneratedAt: proposed.trailGeneratedAt ?? DateTime.now(),
          currentStop: proposed.currentStopIndex,
          stopStates: stopStates,
          completed: proposed.completed,
          mirrorLegacyProgress: plan.mirrorLegacyProgress,
        ),
      ),
      _ => await progressRepository.get(
        userId: userId,
        trailId: proposed.trailId,
      ),
    };

    if (writeResult case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, code: error.code);
    }

    final activityDrafts = [
      for (final draft in plan.activityDrafts)
        TrailActivityDraft(
          trailId: draft.trailId,
          action: draft.action,
          userId: userId,
          isAnonymous: isAnonymous,
          venueId: draft.venueId,
          stopOrder: draft.stopOrder,
        ),
    ];

    final activityResult = await coordinator.appendActivities(activityDrafts);
    final warnings = <String>[];
    if (activityResult case TrailApplicationFailure(message: final message)) {
      warnings.add(message);
    }

    final eventResult = await coordinator.publishEvents(plan.events);
    if (eventResult case TrailApplicationFailure(message: final message)) {
      warnings.add(message);
    }

    final mapped = TrailPersistenceMapper.mapProgressOrNull(
      (writeResult as DataSuccess).value,
    );
    if (mapped == null) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        'Failed to map progress snapshot.',
      );
    }
    return TrailApplicationSuccess(mapped, warnings: warnings);
  }
}
