/// Persisted activity action strings (exact mobile compatibility).
abstract final class TrailActivityType {
  static const started = 'started';
  static const arrived = 'arrived';
  static const continueNext = 'continue_next';
  static const completed = 'completed';
  static const skippedStop = 'skipped_stop';
  static const completedAfterSkip = 'completed_after_skip';
  static const directionsRequested = 'directions_requested';
}

/// Immutable activity write draft for repository adapters.
final class TrailActivityDraft {
  const TrailActivityDraft({
    required this.trailId,
    required this.action,
    this.userId,
    this.isAnonymous = false,
    this.venueId,
    this.stopOrder,
  });

  final String trailId;
  final String action;
  final String? userId;
  final bool isAnonymous;
  final String? venueId;
  final int? stopOrder;
}
