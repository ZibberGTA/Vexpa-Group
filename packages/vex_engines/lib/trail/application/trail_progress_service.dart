import 'package:vex_core/events/vex_event.dart';

import 'package:vex_core/trails/trail_paths.dart';

import '../domain/trail.dart';
import '../domain/trail_action.dart';
import '../domain/trail_activity_draft.dart';
import '../domain/trail_check_in_policy.dart';
import '../domain/trail_events.dart';
import '../domain/trail_progress.dart';
import '../domain/trail_stop_order_policy.dart';
import '../domain/trail_progress_state_policy.dart';
import '../domain/trail_result.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_stop_state.dart';
import '../domain/trail_transition_plan.dart';
import '../domain/trail_visibility_policy.dart';
import 'trail_activity_composer.dart';

/// Pure customer progress transition planning.
final class TrailProgressService {
  const TrailProgressService();

  static const legacyActiveTrailId = TrailPaths.activeTrailDocumentId;

  TrailResult<TrailProgressTransitionPlan> planJoin({
    required Trail trail,
    required String userId,
    required DateTime occurredAt,
    required String eventId,
    TrailProgress? existingProgress,
  }) {
    if (!TrailVisibilityPolicy.isVisible(trail: trail, now: occurredAt)) {
      return const TrailFailure(
        TrailFailureCodes.notAvailable,
        'Trail is not visible for joining.',
      );
    }

    if (existingProgress != null &&
        existingProgress.completed &&
        TrailProgressStatePolicy.belongsToTrail(
          progress: existingProgress,
          trail: trail,
        )) {
      return const TrailFailure(
        TrailFailureCodes.trailAlreadyCompleted,
        'Trail already completed.',
      );
    }

    final proposed = TrailProgress(
      trailId: trail.id,
      started: true,
      completed: false,
      currentStopIndex: 0,
      checkedInStopOrders: const {},
      stopStates: TrailProgressStatePolicy.initialStopStates(trail),
      trailGeneratedAt: trail.generatedAt,
      startedAt: occurredAt,
      updatedAt: occurredAt,
    );

    return TrailSuccess(
      _plan(
        action: TrailProgressAction.join,
        previousProgress: existingProgress,
        proposedProgress: proposed,
        trail: trail,
        userId: userId,
        occurredAt: occurredAt,
        eventId: eventId,
      ),
    );
  }

  TrailResult<TrailProgressTransitionPlan> planCheckIn({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
    required String userId,
    required DateTime occurredAt,
    required String eventId,
    double? userLatitude,
    double? userLongitude,
    double? venueLatitude,
    double? venueLongitude,
    double? presenceRadiusMeters,
  }) {
    final assessment = TrailCheckInPolicy.assess(
      trail: trail,
      progress: progress,
      stop: stop,
      stopIndex: stopIndex,
      now: occurredAt,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      venueLatitude: venueLatitude,
      venueLongitude: venueLongitude,
      presenceRadiusMeters: presenceRadiusMeters,
    );

    if (!assessment.eligible) {
      if (assessment.reasonCode == TrailFailureCodes.checkInBlocked) {
        return TrailSuccess(
          TrailProgressTransitionPlan(
            action: TrailProgressAction.checkIn,
            previousProgress: progress,
            proposedProgress: progress,
            activityDrafts: const [],
            updateActiveTrail: false,
            activeTrailId: trail.id,
            mirrorLegacyProgress: false,
            events: const [],
            noOp: true,
            warnings: [assessment.reasonMessage ?? assessment.reasonCode],
          ),
        );
      }
      return TrailFailure(
        assessment.reasonCode,
        assessment.reasonMessage ?? assessment.reasonCode,
      );
    }

    final stopStates = TrailProgressStatePolicy.statesForCheckIn(
      trail: trail,
      stopIndex: stopIndex,
      existing: progress.stopStates,
    );
    final completed = TrailProgressStatePolicy.isComplete(
      trail: trail,
      stopStates: stopStates,
    );
    final checkedInOrders = Set<int>.from(progress.checkedInStopOrders)
      ..add(stop.order);

    final proposed = progress.copyWith(
      started: true,
      completed: completed,
      currentStopIndex: stopIndex,
      checkedInStopOrders: checkedInOrders,
      stopStates: stopStates,
      trailGeneratedAt: trail.generatedAt,
      lastCheckedInVenueId: stop.venueId,
      lastCheckedInStopOrder: stop.order,
      completedAt: completed ? occurredAt : progress.completedAt,
      updatedAt: occurredAt,
    );

    return TrailSuccess(
      _plan(
        action: TrailProgressAction.checkIn,
        previousProgress: progress,
        proposedProgress: proposed,
        trail: trail,
        userId: userId,
        occurredAt: occurredAt,
        eventId: eventId,
        stop: stop,
      ),
    );
  }

  TrailResult<TrailProgressTransitionPlan> planContinue({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
    required String userId,
    required DateTime occurredAt,
    required String eventId,
  }) {
    if (!TrailCheckInPolicy.continueAllowed(progress: progress, stop: stop)) {
      return const TrailFailure(
        TrailFailureCodes.continueNotAllowed,
        'Continue requires a checked-in current stop.',
      );
    }

    final stopStates = Map<int, TrailStopState>.from(progress.stopStates);
    stopStates[stop.order] = TrailStopState.completed;

    final nextStopIndex = TrailProgressStatePolicy.nextUpcomingStopIndex(
      trail: trail,
      afterIndex: stopIndex,
      states: stopStates,
    );
    final sortedStops = TrailStopOrderPolicy.sortRoute(trail.stops);
    if (nextStopIndex != null) {
      stopStates[sortedStops[nextStopIndex].order] = TrailStopState.current;
    }

    final completed =
        nextStopIndex == null ||
        TrailProgressStatePolicy.isComplete(
          trail: trail,
          stopStates: stopStates,
        );

    final proposed = progress.copyWith(
      started: true,
      completed: completed,
      currentStopIndex: nextStopIndex ?? stopIndex,
      stopStates: stopStates,
      trailGeneratedAt: trail.generatedAt,
      completedAt: completed ? occurredAt : progress.completedAt,
      updatedAt: occurredAt,
    );

    return TrailSuccess(
      _plan(
        action: TrailProgressAction.continueStop,
        previousProgress: progress,
        proposedProgress: proposed,
        trail: trail,
        userId: userId,
        occurredAt: occurredAt,
        eventId: eventId,
        stop: stop,
        completedOverride: completed,
        includeAdvancedEvent: true,
        fromStopIndex: stopIndex,
        toStopIndex: nextStopIndex,
      ),
    );
  }

  TrailResult<TrailProgressTransitionPlan> planSkip({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
    required String userId,
    required DateTime occurredAt,
    required String eventId,
  }) {
    if (!TrailCheckInPolicy.skipAllowed(
      trail: trail,
      progress: progress,
      stop: stop,
      stopIndex: stopIndex,
    )) {
      return const TrailFailure(
        TrailFailureCodes.skipNotAllowed,
        'Skip is not allowed for this stop.',
      );
    }

    final stopStates = Map<int, TrailStopState>.from(progress.stopStates);
    stopStates[stop.order] = TrailStopState.skipped;

    final nextStopIndex = TrailProgressStatePolicy.nextUpcomingStopIndex(
      trail: trail,
      afterIndex: stopIndex,
      states: stopStates,
    );
    final sortedStops = TrailStopOrderPolicy.sortRoute(trail.stops);
    if (nextStopIndex != null) {
      stopStates[sortedStops[nextStopIndex].order] = TrailStopState.current;
    }

    final completed =
        nextStopIndex == null ||
        TrailProgressStatePolicy.isComplete(
          trail: trail,
          stopStates: stopStates,
        );

    final proposed = progress.copyWith(
      started: true,
      completed: completed,
      currentStopIndex: nextStopIndex ?? stopIndex,
      stopStates: stopStates,
      trailGeneratedAt: trail.generatedAt,
      completedAt: completed ? occurredAt : progress.completedAt,
      updatedAt: occurredAt,
    );

    return TrailSuccess(
      _plan(
        action: TrailProgressAction.skipStop,
        previousProgress: progress,
        proposedProgress: proposed,
        trail: trail,
        userId: userId,
        occurredAt: occurredAt,
        eventId: eventId,
        stop: stop,
        completedOverride: completed,
        includeSkippedEvent: true,
      ),
    );
  }

  TrailProgressTransitionPlan _plan({
    required TrailProgressAction action,
    required TrailProgress? previousProgress,
    required TrailProgress proposedProgress,
    required Trail trail,
    required String userId,
    required DateTime occurredAt,
    required String eventId,
    TrailStop? stop,
    bool? completedOverride,
    bool includeAdvancedEvent = false,
    bool includeSkippedEvent = false,
    int? fromStopIndex,
    int? toStopIndex,
  }) {
    final completed = completedOverride ?? proposedProgress.completed;
    final activityDrafts = <TrailActivityDraft>[
      if (action == TrailProgressAction.join)
        TrailActivityComposer.started(trailId: trail.id, userId: userId)
      else if (stop != null)
        TrailActivityComposer.forProgressAction(
          action: action,
          trailId: trail.id,
          venueId: stop.venueId,
          stopOrder: stop.order,
          completed: completed,
          userId: userId,
        ),
    ];

    final events = <VexEvent>[
      if (action == TrailProgressAction.join)
        TrailJoinedEvent(
          id: eventId,
          occurredAt: occurredAt,
          trailId: trail.id,
          userId: userId,
        ),
      if (action == TrailProgressAction.checkIn && stop != null)
        TrailStopCheckedInEvent(
          id: eventId,
          occurredAt: occurredAt,
          trailId: trail.id,
          userId: userId,
          stopOrder: stop.order,
          venueId: stop.venueId,
        ),
      if (includeSkippedEvent && stop != null)
        TrailStopSkippedEvent(
          id: eventId,
          occurredAt: occurredAt,
          trailId: trail.id,
          userId: userId,
          stopOrder: stop.order,
        ),
      if (includeAdvancedEvent)
        TrailAdvancedEvent(
          id: eventId,
          occurredAt: occurredAt,
          trailId: trail.id,
          userId: userId,
          fromStopIndex: fromStopIndex ?? proposedProgress.currentStopIndex,
          toStopIndex: toStopIndex,
        ),
      if (completed)
        TrailCompletedEvent(
          id: eventId,
          occurredAt: occurredAt,
          trailId: trail.id,
          userId: userId,
        ),
    ];

    return TrailProgressTransitionPlan(
      action: action,
      previousProgress: previousProgress,
      proposedProgress: proposedProgress,
      activityDrafts: activityDrafts,
      updateActiveTrail:
          action == TrailProgressAction.join ||
          action == TrailProgressAction.checkIn,
      activeTrailId: trail.id,
      mirrorLegacyProgress: trail.id == legacyActiveTrailId,
      events: events,
    );
  }
}
