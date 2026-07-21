/// Structured availability state for a trail at evaluation time.
enum TrailAvailabilityState {
  availableNow,
  upcoming,
  ended,
  unavailable,
  invalidConfiguration,
}

/// Structured availability assessment.
final class TrailAvailabilityDecision {
  const TrailAvailabilityDecision({
    required this.state,
    required this.reasonCode,
    this.reasonMessage,
    this.availableFrom,
    this.availableUntil,
  });

  final TrailAvailabilityState state;
  final String reasonCode;
  final String? reasonMessage;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
}
