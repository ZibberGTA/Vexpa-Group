import 'package:test/test.dart';
import 'package:vex_core/trails/trail_paths.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'trail_test_helpers.dart';

void main() {
  const service = TrailProgressService();
  final now = DateTime(2026, 7, 18, 20);

  group('TrailProgressService join', () {
    test('plans join with started activity and legacy mirror intent', () {
      final trail = buildTrail(id: TrailPaths.activeTrailDocumentId);
      final result = service.planJoin(
        trail: trail,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-join',
      );

      expect(result, isA<TrailSuccess<TrailProgressTransitionPlan>>());
      final plan =
          (result as TrailSuccess).value as TrailProgressTransitionPlan;
      expect(plan.proposedProgress.started, isTrue);
      expect(plan.proposedProgress.currentStopIndex, 0);
      expect(plan.activityDrafts.single.action, TrailActivityType.started);
      expect(plan.mirrorLegacyProgress, isTrue);
      expect(plan.events.whereType<TrailJoinedEvent>(), isNotEmpty);
    });

    test('rejects join when trail not visible', () {
      final result = service.planJoin(
        trail: buildTrail(status: TrailStatus.draft, published: false),
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-join',
      );
      expect(result, isA<TrailFailure>());
    });
  });

  group('TrailProgressService check-in', () {
    test('plans check-in without advancing current index', () {
      final trail = buildTrail();
      final progress = buildProgress();
      final stop = trail.stops.first;
      final result = service.planCheckIn(
        trail: trail,
        progress: progress,
        stop: stop,
        stopIndex: 0,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-checkin',
        userLatitude: 51.5,
        userLongitude: -0.12,
        venueLatitude: 51.5,
        venueLongitude: -0.12,
        presenceRadiusMeters: 75,
      );

      final plan =
          (result as TrailSuccess).value as TrailProgressTransitionPlan;
      expect(plan.proposedProgress.currentStopIndex, 0);
      expect(plan.proposedProgress.stopStates[1], TrailStopState.checkedIn);
      expect(plan.activityDrafts.single.action, TrailActivityType.arrived);
    });

    test('returns no-op plan for backward check-in regression', () {
      final trail = buildTrail();
      final progress = buildProgress(currentStopIndex: 1);
      final stop = trail.stops.first;
      final result = service.planCheckIn(
        trail: trail,
        progress: progress,
        stop: stop,
        stopIndex: 0,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-checkin',
      );

      final plan =
          (result as TrailSuccess).value as TrailProgressTransitionPlan;
      expect(plan.noOp, isTrue);
    });

    test(
      'can complete trail on final stop check-in because checkedIn is terminal',
      () {
        final trail = buildTrail(
          stops: [
            TrailStop(
              venueId: 'v1',
              venueName: 'Only',
              address: '',
              bannerImageUrl: '',
              logoUrl: '',
              order: 1,
              score: 0,
              arriveAt: now,
              leaveAt: now.add(const Duration(hours: 1)),
            ),
          ],
        );
        final progress = buildProgress(stopStates: {1: TrailStopState.current});
        final result = service.planCheckIn(
          trail: trail,
          progress: progress,
          stop: trail.stops.first,
          stopIndex: 0,
          userId: 'user-1',
          occurredAt: now,
          eventId: 'evt-checkin',
        );
        final plan =
            (result as TrailSuccess).value as TrailProgressTransitionPlan;
        expect(plan.proposedProgress.completed, isTrue);
      },
    );
  });

  group('TrailProgressService continue', () {
    test('requires checked-in stop before continue', () {
      final trail = buildTrail();
      final progress = buildProgress();
      final result = service.planContinue(
        trail: trail,
        progress: progress,
        stop: trail.stops.first,
        stopIndex: 0,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-continue',
      );
      expect(result, isA<TrailFailure>());
    });

    test('advances to next stop after continue', () {
      final trail = buildTrail();
      final progress = buildProgress(
        stopStates: {1: TrailStopState.checkedIn, 2: TrailStopState.upcoming},
      );
      final result = service.planContinue(
        trail: trail,
        progress: progress,
        stop: trail.stops.first,
        stopIndex: 0,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-continue',
      );
      final plan =
          (result as TrailSuccess).value as TrailProgressTransitionPlan;
      expect(plan.proposedProgress.currentStopIndex, 1);
      expect(plan.proposedProgress.stopStates[1], TrailStopState.completed);
      expect(plan.proposedProgress.stopStates[2], TrailStopState.current);
      expect(plan.activityDrafts.single.action, TrailActivityType.continueNext);
    });
  });

  group('TrailProgressService skip', () {
    test('marks stop skipped and advances', () {
      final trail = buildTrail();
      final progress = buildProgress();
      final result = service.planSkip(
        trail: trail,
        progress: progress,
        stop: trail.stops.first,
        stopIndex: 0,
        userId: 'user-1',
        occurredAt: now,
        eventId: 'evt-skip',
      );
      final plan =
          (result as TrailSuccess).value as TrailProgressTransitionPlan;
      expect(plan.proposedProgress.stopStates[1], TrailStopState.skipped);
      expect(plan.activityDrafts.single.action, TrailActivityType.skippedStop);
    });
  });
}
