/// Confidence scoring signal for automated claim review.
final class ClaimConfidenceSignal {
  const ClaimConfidenceSignal({
    required this.key,
    required this.label,
    required this.points,
    required this.matched,
  });

  final String key;
  final String label;
  final int points;
  final bool matched;

  Map<String, dynamic> toMap() {
    return {'key': key, 'label': label, 'points': points, 'matched': matched};
  }

  factory ClaimConfidenceSignal.fromMap(Map<String, dynamic> map) {
    return ClaimConfidenceSignal(
      key: (map['key'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      points: map['points'] is num ? (map['points'] as num).round() : 0,
      matched: map['matched'] == true,
    );
  }
}

/// Confidence score used for auto-approval thresholds.
final class ClaimConfidenceScore {
  const ClaimConfidenceScore({
    required this.score,
    required this.threshold,
    required this.signals,
  });

  final int score;
  final int threshold;
  final List<ClaimConfidenceSignal> signals;

  bool get autoApproved => score >= threshold;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'threshold': threshold,
      'autoApproved': autoApproved,
      'signals': signals.map((signal) => signal.toMap()).toList(),
    };
  }
}
