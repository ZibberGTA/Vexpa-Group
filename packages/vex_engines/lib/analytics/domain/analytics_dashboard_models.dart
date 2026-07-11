/// Known dashboard metric keys in display order.
abstract final class AnalyticsDashboardMetricKey {
  static const profileViews = 'profile_views';
  static const saves = 'saves';
  static const drinkViews = 'drink_views';
  static const dealViews = 'deal_views';
  static const eventViews = 'event_views';

  static const displayOrder = [
    profileViews,
    saves,
    drinkViews,
    dealViews,
    eventViews,
  ];
}

/// A single dashboard metric with optional period-over-period change.
final class AnalyticsDashboardStat {
  const AnalyticsDashboardStat({
    required this.metricKey,
    required this.value,
    this.changePercent,
  });

  final String metricKey;
  final int value;
  final double? changePercent;

  bool get hasComparison => changePercent != null;
}

/// Analytics-driven performance highlight for the venue dashboard.
final class AnalyticsDashboardHighlight {
  const AnalyticsDashboardHighlight({
    required this.message,
    required this.buttonLabel,
    required this.targetTabKey,
    required this.accentKey,
  });

  final String message;
  final String buttonLabel;

  /// Semantic tab key consumed by app shells (e.g. `analytics`, `gallery`).
  final String targetTabKey;

  /// Semantic accent key (e.g. `blue`, `pink`).
  final String accentKey;
}

/// Raw activity row before venue-specific interpretation.
final class AnalyticsActivityEntry {
  const AnalyticsActivityEntry({
    required this.occurredAt,
    required this.source,
    this.eventType,
    this.payload = const {},
    this.contentTitle,
  });

  final DateTime occurredAt;

  /// `analytics` or `content_event`.
  final String source;
  final String? eventType;
  final Map<String, dynamic> payload;

  /// Title for content-created events (e.g. newly added event name).
  final String? contentTitle;
}

/// Interpreted activity row ready for UI mapping.
final class AnalyticsActivityItem {
  const AnalyticsActivityItem({
    required this.title,
    required this.timestampLabel,
    required this.iconKey,
  });

  final String title;
  final String timestampLabel;

  /// Semantic icon key consumed by app shells.
  final String iconKey;
}
