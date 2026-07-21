/// Publication checklist item identifiers (mobile admin parity).
enum TrailPublicationCheckId { name, banner, venues, availability, status }

/// Single publication readiness check.
final class TrailPublicationCheck {
  const TrailPublicationCheck({
    required this.id,
    required this.label,
    required this.passed,
    this.failureMessage,
  });

  final TrailPublicationCheckId id;
  final String label;
  final bool passed;
  final String? failureMessage;
}

/// Publication readiness assessment.
final class TrailPublicationReadiness {
  const TrailPublicationReadiness({
    required this.checks,
    required this.isReady,
    this.warnings = const [],
    this.normalisedStopOrders = const [],
  });

  final List<TrailPublicationCheck> checks;
  final bool isReady;
  final List<String> warnings;
  final List<int> normalisedStopOrders;
}
