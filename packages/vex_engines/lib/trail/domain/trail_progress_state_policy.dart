import 'trail.dart';
import 'trail_progress.dart';
import 'trail_stop.dart';
import 'trail_stop_state.dart';
import 'trail_completion_policy.dart';
import 'trail_stop_order_policy.dart';

/// Progress state helpers matching mobile `TrailService` private methods.
abstract final class TrailProgressStatePolicy {
  static Map<int, TrailStopState> initialStopStates(Trail trail) {
    return {
      for (final entry in TrailStopOrderPolicy.sortRoute(
        trail.stops,
      ).asMap().entries)
        entry.value.order: entry.key == 0
            ? TrailStopState.current
            : TrailStopState.upcoming,
    };
  }

  static Map<int, TrailStopState> statesForCheckIn({
    required Trail trail,
    required int stopIndex,
    Map<int, TrailStopState>? existing,
  }) {
    final states = Map<int, TrailStopState>.from(
      existing ?? const <int, TrailStopState>{},
    );
    final sorted = TrailStopOrderPolicy.sortRoute(trail.stops);

    for (final entry in sorted.asMap().entries) {
      final index = entry.key;
      final order = entry.value.order;
      final current = states[order];
      if (current == TrailStopState.skipped ||
          current == TrailStopState.completed) {
        continue;
      }
      if (index < stopIndex) {
        states[order] = current == TrailStopState.checkedIn
            ? TrailStopState.completed
            : TrailStopState.missed;
      } else if (index == stopIndex) {
        states[order] = TrailStopState.checkedIn;
      } else {
        states.putIfAbsent(order, () => TrailStopState.upcoming);
      }
    }
    return states;
  }

  static int? nextUpcomingStopIndex({
    required Trail trail,
    required int afterIndex,
    required Map<int, TrailStopState> states,
  }) {
    final sorted = TrailStopOrderPolicy.sortRoute(trail.stops);
    for (var index = afterIndex + 1; index < sorted.length; index++) {
      final state = states[sorted[index].order];
      if (state == null ||
          state == TrailStopState.upcoming ||
          state == TrailStopState.current) {
        return index;
      }
    }
    return null;
  }

  static TrailStopState displayStateForStop({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
  }) {
    final explicit = progress.stopStates[stop.order];
    if (explicit != null) return explicit;
    if (progress.checkedInStopOrders.contains(stop.order)) {
      return TrailStopState.checkedIn;
    }
    if (progress.completed || stopIndex < progress.currentStopIndex) {
      return TrailStopState.completed;
    }
    if (progress.started && stopIndex == progress.currentStopIndex) {
      return TrailStopState.current;
    }
    return TrailStopState.upcoming;
  }

  static bool belongsToTrail({
    required TrailProgress progress,
    required Trail trail,
  }) {
    if (progress.trailId != trail.id) return false;
    if (progress.trailGeneratedAt == null) return true;
    return progress.trailGeneratedAt!.millisecondsSinceEpoch ==
        trail.generatedAt.millisecondsSinceEpoch;
  }

  static bool isComplete({
    required Trail trail,
    required Map<int, TrailStopState> stopStates,
  }) {
    return TrailCompletionPolicy.isRouteComplete(
      trail: trail,
      stopStates: stopStates,
    );
  }
}
