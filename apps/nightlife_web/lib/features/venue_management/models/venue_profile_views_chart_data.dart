import 'venue_dashboard_date_range.dart';

/// A single point on the profile views over time chart.
class VenueProfileViewsDataPoint {
  const VenueProfileViewsDataPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

/// Placeholder profile view time-series keyed by chart timeframe.
class VenueProfileViewsChartData {
  VenueProfileViewsChartData._();

  static List<VenueProfileViewsDataPoint> mockFor(VenueDashboardDateRange range) {
    return switch (range) {
      VenueDashboardDateRange.today => const [
          VenueProfileViewsDataPoint(label: '8am', value: 6),
          VenueProfileViewsDataPoint(label: '10am', value: 14),
          VenueProfileViewsDataPoint(label: '12pm', value: 22),
          VenueProfileViewsDataPoint(label: '2pm', value: 18),
          VenueProfileViewsDataPoint(label: '4pm', value: 26),
          VenueProfileViewsDataPoint(label: '6pm', value: 32),
        ],
      VenueDashboardDateRange.last3Days => const [
          VenueProfileViewsDataPoint(label: 'Fri', value: 142),
          VenueProfileViewsDataPoint(label: 'Sat', value: 198),
          VenueProfileViewsDataPoint(label: 'Sun', value: 176),
        ],
      VenueDashboardDateRange.last7Days => const [
          VenueProfileViewsDataPoint(label: 'Mon', value: 120),
          VenueProfileViewsDataPoint(label: 'Tue', value: 145),
          VenueProfileViewsDataPoint(label: 'Wed', value: 132),
          VenueProfileViewsDataPoint(label: 'Thu', value: 168),
          VenueProfileViewsDataPoint(label: 'Fri', value: 190),
          VenueProfileViewsDataPoint(label: 'Sat', value: 210),
          VenueProfileViewsDataPoint(label: 'Sun', value: 183),
        ],
      VenueDashboardDateRange.lastMonth => const [
          VenueProfileViewsDataPoint(label: 'W1', value: 820),
          VenueProfileViewsDataPoint(label: 'W2', value: 940),
          VenueProfileViewsDataPoint(label: 'W3', value: 1010),
          VenueProfileViewsDataPoint(label: 'W4', value: 1120),
        ],
      VenueDashboardDateRange.allTime => const [
          VenueProfileViewsDataPoint(label: 'Jan', value: 2100),
          VenueProfileViewsDataPoint(label: 'Feb', value: 2450),
          VenueProfileViewsDataPoint(label: 'Mar', value: 2680),
          VenueProfileViewsDataPoint(label: 'Apr', value: 2920),
          VenueProfileViewsDataPoint(label: 'May', value: 3180),
          VenueProfileViewsDataPoint(label: 'Jun', value: 3410),
        ],
      VenueDashboardDateRange.custom => mockFor(VenueDashboardDateRange.last7Days),
    };
  }
}
