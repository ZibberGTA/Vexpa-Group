import 'trail_stop_state.dart';

/// Stop states keyed by persisted stop order.
typedef TrailStopStateMap = Map<int, TrailStopState>;

/// Customer trail progress in normalized domain form.
final class TrailProgress {
  const TrailProgress({
    required this.trailId,
    required this.started,
    required this.completed,
    required this.currentStopIndex,
    required this.checkedInStopOrders,
    required this.stopStates,
    this.trailGeneratedAt,
    this.startedAt,
    this.updatedAt,
    this.completedAt,
    this.lastCheckedInVenueId,
    this.lastCheckedInStopOrder,
  });

  final String trailId;
  final bool started;
  final bool completed;
  final int currentStopIndex;
  final Set<int> checkedInStopOrders;
  final TrailStopStateMap stopStates;
  final DateTime? trailGeneratedAt;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? lastCheckedInVenueId;
  final int? lastCheckedInStopOrder;

  TrailProgress copyWith({
    String? trailId,
    bool? started,
    bool? completed,
    int? currentStopIndex,
    Set<int>? checkedInStopOrders,
    TrailStopStateMap? stopStates,
    DateTime? trailGeneratedAt,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? lastCheckedInVenueId,
    int? lastCheckedInStopOrder,
  }) {
    return TrailProgress(
      trailId: trailId ?? this.trailId,
      started: started ?? this.started,
      completed: completed ?? this.completed,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      checkedInStopOrders: checkedInStopOrders ?? this.checkedInStopOrders,
      stopStates: stopStates ?? this.stopStates,
      trailGeneratedAt: trailGeneratedAt ?? this.trailGeneratedAt,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      lastCheckedInVenueId: lastCheckedInVenueId ?? this.lastCheckedInVenueId,
      lastCheckedInStopOrder:
          lastCheckedInStopOrder ?? this.lastCheckedInStopOrder,
    );
  }
}
