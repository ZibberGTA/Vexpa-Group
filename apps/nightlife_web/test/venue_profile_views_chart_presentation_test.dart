import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_views_chart_data.dart';
import 'package:nightlife_web/features/venue_management/utils/venue_profile_views_chart_presentation.dart';

void main() {
  group('VenueProfileViewsChartPresentation', () {
    test('last 7 days always returns seven chronological weekday labels', () {
      final normalized = VenueProfileViewsChartPresentation.normalizeForDisplay(
        points: const [
          VenueProfileViewsDataPoint(label: 'Tue', value: 5),
          VenueProfileViewsDataPoint(label: 'Fri', value: 3),
          VenueProfileViewsDataPoint(label: 'Sun', value: 8),
        ],
        range: VenueDashboardDateRange.last7Days,
        now: DateTime(2026, 7, 12),
      );

      expect(normalized, hasLength(7));
      expect(
        normalized.map((point) => point.label).toList(),
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
      expect(normalized[1].value, 5);
      expect(normalized[4].value, 3);
      expect(normalized[6].value, 8);
      expect(normalized.first.value, 0);
      expect(normalized[3].value, 0);
    });

    test('last 3 days returns three chronological weekday labels', () {
      final normalized = VenueProfileViewsChartPresentation.normalizeForDisplay(
        points: const [
          VenueProfileViewsDataPoint(label: 'Sat', value: 2),
        ],
        range: VenueDashboardDateRange.last3Days,
        now: DateTime(2026, 7, 12),
      );

      expect(normalized, hasLength(3));
      expect(
        normalized.map((point) => point.label).toList(),
        ['Fri', 'Sat', 'Sun'],
      );
      expect(normalized.map((point) => point.value).toList(), [0, 2, 0]);
    });

    test('visibleLabelIndices keeps first and last labels for crowded ranges', () {
      final indices = VenueProfileViewsChartPresentation.visibleLabelIndices(
        pointCount: 12,
        plotWidth: 240,
      );

      expect(indices.first, 0);
      expect(indices.last, 11);
      expect(indices.length, greaterThan(2));
      expect(indices.length, lessThan(12));
    });

    test('visibleLabelIndices shows every label when space allows', () {
      final indices = VenueProfileViewsChartPresentation.visibleLabelIndices(
        pointCount: 7,
        plotWidth: 640,
      );

      expect(indices, [0, 1, 2, 3, 4, 5, 6]);
    });

    test('plotAreaWidth subtracts y-axis width and gap from total width', () {
      expect(
        VenueProfileViewsChartPresentation.plotAreaWidth(totalWidth: 700),
        700 -
            VenueProfileViewsChartPresentation.yAxisWidth -
            VenueProfileViewsChartPresentation.yAxisGap,
      );
    });
  });

  group('ProfileViewsChartPlotLayout', () {
    const weekdayPoints = [
      VenueProfileViewsDataPoint(label: 'Mon', value: 1),
      VenueProfileViewsDataPoint(label: 'Tue', value: 2),
      VenueProfileViewsDataPoint(label: 'Wed', value: 3),
      VenueProfileViewsDataPoint(label: 'Thu', value: 4),
      VenueProfileViewsDataPoint(label: 'Fri', value: 5),
      VenueProfileViewsDataPoint(label: 'Sat', value: 6),
      VenueProfileViewsDataPoint(label: 'Sun', value: 7),
    ];

    for (final totalWidth in [480.0, 640.0, 900.0]) {
      test('point and label X coordinates match for width $totalWidth', () {
        final plotWidth = VenueProfileViewsChartPresentation.plotAreaWidth(
          totalWidth: totalWidth,
        );
        final layout = ProfileViewsChartPlotLayout.compute(
          points: weekdayPoints,
          plotWidth: plotWidth,
          plotHeight: 220,
        );

        expect(layout.xPositions, hasLength(7));
        expect(layout.coords, hasLength(7));

        for (var index = 0; index < 7; index++) {
          expect(
            layout.pointX(index),
            layout.labelCenterX(index),
            reason: 'Index $index must share one X coordinate',
          );
          expect(
            layout.coords[index].dx,
            layout.xPositions[index],
            reason: 'Line path must use the same X as the point marker',
          );
        }
      });
    }

    test('first and final coordinates stay inside plot bounds', () {
      final plotWidth = VenueProfileViewsChartPresentation.plotAreaWidth(
        totalWidth: 700,
      );
      final layout = ProfileViewsChartPlotLayout.compute(
        points: weekdayPoints,
        plotWidth: plotWidth,
        plotHeight: 220,
      );

      expect(layout.pointX(0), layout.plotLeft);
      expect(layout.pointX(6), layout.plotRight);
      expect(layout.pointX(0), greaterThanOrEqualTo(0));
      expect(layout.pointX(6), lessThanOrEqualTo(plotWidth));
    });

    test('uses plot area width rather than full container width', () {
      const totalWidth = 700.0;
      final plotWidth = VenueProfileViewsChartPresentation.plotAreaWidth(
        totalWidth: totalWidth,
      );

      final plotLayout = ProfileViewsChartPlotLayout.compute(
        points: weekdayPoints,
        plotWidth: plotWidth,
        plotHeight: 220,
      );
      final fullWidthLayout = ProfileViewsChartPlotLayout.compute(
        points: weekdayPoints,
        plotWidth: totalWidth,
        plotHeight: 220,
      );

      expect(plotLayout.pointX(6), lessThan(fullWidthLayout.pointX(6)));
      expect(
        plotLayout.pointX(6),
        VenueProfileViewsChartPresentation.plotAreaWidth(totalWidth: totalWidth) -
            ProfileViewsChartPlotLayout.horizontalPad,
      );
    });
  });
}
