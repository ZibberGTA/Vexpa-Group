import 'trail.dart';
import 'trail_result.dart';
import 'trail_stop.dart';

/// Route order validation and index/order conversion.
final class TrailRouteValidation {
  const TrailRouteValidation({
    required this.sortedStops,
    required this.hasDuplicateOrders,
    required this.hasMissingOrders,
    required this.isContiguousFromOne,
  });

  final List<TrailStop> sortedStops;
  final bool hasDuplicateOrders;
  final bool hasMissingOrders;
  final bool isContiguousFromOne;
}

abstract final class TrailStopOrderPolicy {
  static List<TrailStop> sortRoute(List<TrailStop> stops) {
    final copy = List<TrailStop>.from(stops)
      ..sort((a, b) => a.order.compareTo(b.order));
    return copy;
  }

  static TrailRouteValidation validateRoute(List<TrailStop> stops) {
    final sorted = sortRoute(stops);
    final seenOrders = <int>{};
    var hasDuplicateOrders = false;
    var hasMissingOrders = false;

    for (final stop in sorted) {
      if (stop.order <= 0) {
        hasMissingOrders = true;
      }
      if (!seenOrders.add(stop.order)) {
        hasDuplicateOrders = true;
      }
    }

    final isContiguousFromOne = sorted.isEmpty
        ? true
        : List.generate(
            sorted.length,
            (index) => index + 1,
          ).every((order) => sorted.any((stop) => stop.order == order));

    return TrailRouteValidation(
      sortedStops: sorted,
      hasDuplicateOrders: hasDuplicateOrders,
      hasMissingOrders: hasMissingOrders,
      isContiguousFromOne: isContiguousFromOne,
    );
  }

  static List<TrailStop> renumberContiguous(List<TrailStop> stops) {
    final sorted = sortRoute(stops);
    return [
      for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(order: i + 1),
    ];
  }

  static TrailResult<int> resolveOrderToIndex({
    required Trail trail,
    required int stopOrder,
  }) {
    final sorted = sortRoute(trail.stops);
    for (var index = 0; index < sorted.length; index++) {
      if (sorted[index].order == stopOrder) {
        return TrailSuccess(index);
      }
    }
    return const TrailFailure(
      TrailFailureCodes.stopNotFound,
      'Stop order not found in route.',
    );
  }

  static TrailResult<TrailStop> stopAtIndex({
    required Trail trail,
    required int stopIndex,
  }) {
    final sorted = sortRoute(trail.stops);
    if (stopIndex < 0 || stopIndex >= sorted.length) {
      return const TrailFailure(
        TrailFailureCodes.stopNotFound,
        'Stop index out of range.',
      );
    }
    return TrailSuccess(sorted[stopIndex]);
  }

  static bool isFinalStopIndex({required Trail trail, required int stopIndex}) {
    final sorted = sortRoute(trail.stops);
    return sorted.isNotEmpty && stopIndex >= sorted.length - 1;
  }
}
