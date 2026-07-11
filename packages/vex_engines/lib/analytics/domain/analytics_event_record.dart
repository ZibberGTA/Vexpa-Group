/// Neutral analytics event record for in-memory aggregation.
final class AnalyticsEventRecord {
  const AnalyticsEventRecord({
    required this.type,
    this.payload = const {},
    this.createdAt,
  });

  final String type;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
}
