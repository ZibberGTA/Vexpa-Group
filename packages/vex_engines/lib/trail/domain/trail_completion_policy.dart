import 'trail.dart';
import 'trail_progress.dart';
import 'trail_stop_state.dart';
import 'trail_transition_plan.dart';
import 'trail_stop_order_policy.dart';

/// Completion rule matching mobile `_trailComplete`.
abstract final class TrailCompletionPolicy {
  static bool isRouteComplete({
    required Trail trail,
    required Map<int, TrailStopState> stopStates,
  }) {
    if (trail.stops.isEmpty) return true;
    return trail.stops.every(
      (stop) => stopStates[stop.order]?.isTerminal == true,
    );
  }

  static TrailCompletionAssessment assess({
    required Trail trail,
    required TrailProgress progress,
  }) {
    final sorted = TrailStopOrderPolicy.sortRoute(trail.stops);
    final unresolved = <int>[];
    var checkedInCount = 0;
    var skippedCount = 0;

    for (final stop in sorted) {
      final state = progress.stopStates[stop.order];
      if (state == TrailStopState.checkedIn) {
        checkedInCount++;
      } else if (state == TrailStopState.skipped) {
        skippedCount++;
      }
      if (state == null || !state.isTerminal) {
        unresolved.add(stop.order);
      }
    }

    final complete = sorted.isEmpty || unresolved.isEmpty;

    return TrailCompletionAssessment(
      isComplete: complete,
      totalStops: sorted.length,
      checkedInCount: checkedInCount,
      skippedCount: skippedCount,
      unresolvedStopOrders: unresolved,
      blockingReason: complete ? null : 'Unresolved stops remain.',
    );
  }
}
