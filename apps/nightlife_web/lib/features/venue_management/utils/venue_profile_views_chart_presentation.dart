import 'dart:math' as math;
import 'dart:ui';

import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_views_chart_data.dart';

/// Display-only chart series normalisation for the profile views graph.
///
/// Does not change analytics queries or calculations. Pads sparse buckets so
/// fixed-width ranges (for example Last 7 Days) always show one label per day.
class VenueProfileViewsChartPresentation {
  VenueProfileViewsChartPresentation._();

  static const yAxisWidth = 36.0;
  static const yAxisGap = 8.0;
  static const horizontalPad = ProfileViewsChartPlotLayout.horizontalPad;
  static const verticalPad = ProfileViewsChartPlotLayout.verticalPad;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static List<VenueProfileViewsDataPoint> normalizeForDisplay({
    required List<VenueProfileViewsDataPoint> points,
    required VenueDashboardDateRange range,
    DateTime? now,
  }) {
    if (points.isEmpty) return const [];

    return switch (range) {
      VenueDashboardDateRange.last7Days ||
      VenueDashboardDateRange.custom =>
        _fillDailyBuckets(points: points, dayCount: 7, now: now),
      VenueDashboardDateRange.last3Days =>
        _fillDailyBuckets(points: points, dayCount: 3, now: now),
      VenueDashboardDateRange.lastMonth => _fillOrderedLabels(
          points: points,
          labels: const ['W1', 'W2', 'W3', 'W4', 'W5'],
        ),
      VenueDashboardDateRange.today ||
      VenueDashboardDateRange.allTime =>
        List<VenueProfileViewsDataPoint>.from(points),
    };
  }

  /// Label indices to render for [points] at [plotWidth].
  ///
  /// Every point is still plotted. Longer ranges skip crowded axis labels while
  /// keeping the first and last labels visible.
  static List<int> visibleLabelIndices({
    required int pointCount,
    required double plotWidth,
  }) {
    if (pointCount <= 0) return const [];
    if (pointCount == 1) return const [0];

    const minLabelWidth = 28.0;
    final maxLabels = math.max(2, (plotWidth / minLabelWidth).floor());
    if (pointCount <= maxLabels) {
      return List.generate(pointCount, (index) => index);
    }

    final step = ((pointCount - 1) / (maxLabels - 1)).ceil().clamp(1, pointCount);
    final indices = <int>{0, pointCount - 1};
    for (var index = step; index < pointCount - 1; index += step) {
      indices.add(index);
    }
    return indices.toList()..sort();
  }

  static double plotAreaWidth({required double totalWidth}) {
    return totalWidth - yAxisWidth - yAxisGap;
  }

  static List<VenueProfileViewsDataPoint> _fillDailyBuckets({
    required List<VenueProfileViewsDataPoint> points,
    required int dayCount,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final endDay = DateTime(anchor.year, anchor.month, anchor.day);
    final valuesByWeekday = {
      for (final point in points) point.label: point.value,
    };

    return List.generate(dayCount, (index) {
      final day = endDay.subtract(Duration(days: dayCount - 1 - index));
      final label = _weekdayLabels[day.weekday - DateTime.monday];
      return VenueProfileViewsDataPoint(
        label: label,
        value: valuesByWeekday[label] ?? 0,
      );
    });
  }

  static List<VenueProfileViewsDataPoint> _fillOrderedLabels({
    required List<VenueProfileViewsDataPoint> points,
    required List<String> labels,
  }) {
    final valuesByLabel = {for (final point in points) point.label: point.value};

    return labels
        .map(
          (label) => VenueProfileViewsDataPoint(
            label: label,
            value: valuesByLabel[label] ?? 0,
          ),
        )
        .toList();
  }
}

/// Shared horizontal plot bounds for the profile views chart.
class ProfileViewsChartPlotLayout {
  const ProfileViewsChartPlotLayout({
    required this.plotWidth,
    required this.plotHeight,
    required this.plotLeft,
    required this.plotRight,
    required this.chartRect,
    required this.xPositions,
    required this.coords,
    required this.yTicks,
    required this.maxValue,
  });

  static const horizontalPad = 4.0;
  static const verticalPad = 6.0;

  final double plotWidth;
  final double plotHeight;
  final double plotLeft;
  final double plotRight;
  final Rect chartRect;
  final List<double> xPositions;
  final List<Offset> coords;
  final List<double> yTicks;
  final double maxValue;

  double xForIndex(int index) => xPositions[index];

  double labelCenterX(int index) => xPositions[index];

  double pointX(int index) => coords[index].dx;

  static ProfileViewsChartPlotLayout compute({
    required List<VenueProfileViewsDataPoint> points,
    required double plotWidth,
    required double plotHeight,
  }) {
    final chartRect = Rect.fromLTWH(
      horizontalPad,
      verticalPad,
      plotWidth - (horizontalPad * 2),
      plotHeight - (verticalPad * 2),
    );
    final plotLeft = horizontalPad;
    final plotRight = plotWidth - horizontalPad;

    final maxValue = _niceMaxValue(points.map((point) => point.value).reduce(math.max));
    final yTicks = <double>[
      maxValue,
      maxValue * 2 / 3,
      maxValue / 3,
      0,
    ];

    final xPositions = _xPositionsFor(
      pointCount: points.length,
      plotLeft: plotLeft,
      plotRight: plotRight,
    );

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final normalized = maxValue == 0 ? 0.0 : points[i].value / maxValue;
      final y = chartRect.bottom - (chartRect.height * normalized);
      coords.add(Offset(xPositions[i], y));
    }

    return ProfileViewsChartPlotLayout(
      plotWidth: plotWidth,
      plotHeight: plotHeight,
      plotLeft: plotLeft,
      plotRight: plotRight,
      chartRect: chartRect,
      xPositions: xPositions,
      coords: coords,
      yTicks: yTicks,
      maxValue: maxValue,
    );
  }

  static List<double> _xPositionsFor({
    required int pointCount,
    required double plotLeft,
    required double plotRight,
  }) {
    if (pointCount <= 0) return const [];

    final plotWidth = plotRight - plotLeft;
    return List.generate(pointCount, (index) {
      return plotLeft + (plotWidth * index / math.max(pointCount - 1, 1));
    });
  }

  static double _niceMaxValue(double rawMax) {
    if (rawMax <= 0) return 1;
    if (rawMax <= 10) return 10;
    if (rawMax <= 50) return 50;
    if (rawMax <= 100) return 100;
    if (rawMax <= 250) return 250;
    if (rawMax <= 500) return 500;
    if (rawMax <= 1000) return 1000;
    if (rawMax <= 2500) return 2500;
    if (rawMax <= 5000) return 5000;
    return (rawMax / 1000).ceil() * 1000;
  }

  static String formatAxisValue(double value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      if (value % 1000 == 0) {
        return '${thousands.toStringAsFixed(0)}k';
      }
      return '${thousands.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }
}
