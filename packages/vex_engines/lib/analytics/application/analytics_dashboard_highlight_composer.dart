import '../domain/analytics_dashboard_models.dart';
import '../domain/analytics_venue_metrics.dart';
import 'analytics_percent_change.dart';

/// Builds analytics-driven dashboard highlights from period comparisons.
final class AnalyticsDashboardHighlightComposer {
  const AnalyticsDashboardHighlightComposer();

  List<AnalyticsDashboardHighlight> compose({
    required AnalyticsVenueMetrics current,
    AnalyticsVenueMetrics? previous,
    int maxHighlights = 4,
  }) {
    if (previous == null) return const [];

    final highlights = <AnalyticsDashboardHighlight>[];

    final profileChange = AnalyticsPercentChange.calculate(
      current.profileViews,
      previous.profileViews,
    );
    if (profileChange != null && current.profileViews > 0) {
      highlights.add(
        AnalyticsDashboardHighlight(
          message:
              'Your profile views are ${profileChange.abs().toStringAsFixed(0)}% ${profileChange >= 0 ? 'higher' : 'lower'} than the previous period.',
          buttonLabel: 'View Analytics',
          targetTabKey: 'analytics',
          accentKey: 'blue',
        ),
      );
    }

    final savesChange = AnalyticsPercentChange.calculate(
      current.saves,
      previous.saves,
    );
    if (savesChange != null && current.saves > 0) {
      highlights.add(
        AnalyticsDashboardHighlight(
          message:
              'Customers saved your venue ${savesChange >= 0 ? '$savesChange% more' : '${savesChange.abs()}% less'} than the previous period.',
          buttonLabel: 'View Analytics',
          targetTabKey: 'analytics',
          accentKey: 'pink',
        ),
      );
    }

    return highlights.take(maxHighlights).toList();
  }
}
