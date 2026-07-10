import 'package:flutter/material.dart';

import 'venue_dashboard_date_range.dart';

/// A single analytics metric shown on the venue dashboard home screen.
class VenueDashboardStat {
  const VenueDashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    this.changePercent,
  });

  final String label;
  final int value;
  final IconData icon;

  /// Null when no real comparison data is available.
  final double? changePercent;

  bool get hasComparison => changePercent != null;
  bool get isPositive => (changePercent ?? 0) >= 0;

  String get formattedValue {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String subtitleLabel(VenueDashboardDateRange range) {
    if (!hasComparison) {
      return value == 0 ? 'No data yet' : 'Total for ${range.label.toLowerCase()}';
    }

    final sign = changePercent! >= 0 ? '+' : '';
    final rounded = changePercent! == changePercent!.roundToDouble()
        ? changePercent!.toInt()
        : changePercent!.toStringAsFixed(1);
    return '$sign$rounded% ${range.comparisonLabel}';
  }

  @Deprecated('Use subtitleLabel')
  String changeLabel(VenueDashboardDateRange range) => subtitleLabel(range);
}

/// Analytics stat builders for the venue dashboard home screen.
class VenueDashboardStatsData {
  VenueDashboardStatsData._();

  static List<VenueDashboardStat> empty() {
    return const [
      VenueDashboardStat(
        label: 'Profile Views',
        value: 0,
        icon: Icons.visibility_outlined,
      ),
      VenueDashboardStat(
        label: 'Saves',
        value: 0,
        icon: Icons.bookmark_outline_rounded,
      ),
      VenueDashboardStat(
        label: 'Drink Views',
        value: 0,
        icon: Icons.local_bar_outlined,
      ),
      VenueDashboardStat(
        label: 'Deal Views',
        value: 0,
        icon: Icons.local_offer_outlined,
      ),
      VenueDashboardStat(
        label: 'Event Views',
        value: 0,
        icon: Icons.event_outlined,
      ),
    ];
  }

  static List<VenueDashboardStat> fromAnalytics({
    required int profileViews,
    required int saves,
    required int drinkViews,
    required int dealViews,
    required int eventViews,
    double? profileViewsChange,
    double? savesChange,
    double? drinkViewsChange,
    double? dealViewsChange,
    double? eventViewsChange,
  }) {
    return [
      VenueDashboardStat(
        label: 'Profile Views',
        value: profileViews,
        changePercent: profileViewsChange,
        icon: Icons.visibility_outlined,
      ),
      VenueDashboardStat(
        label: 'Saves',
        value: saves,
        changePercent: savesChange,
        icon: Icons.bookmark_outline_rounded,
      ),
      VenueDashboardStat(
        label: 'Drink Views',
        value: drinkViews,
        changePercent: drinkViewsChange,
        icon: Icons.local_bar_outlined,
      ),
      VenueDashboardStat(
        label: 'Deal Views',
        value: dealViews,
        changePercent: dealViewsChange,
        icon: Icons.local_offer_outlined,
      ),
      VenueDashboardStat(
        label: 'Event Views',
        value: eventViews,
        changePercent: eventViewsChange,
        icon: Icons.event_outlined,
      ),
    ];
  }

  /// Placeholder analytics values keyed by date range — tests only.
  @Deprecated('Use VenueDashboardRepository for real analytics')
  static List<VenueDashboardStat> mockFor(VenueDashboardDateRange range) {
    return fromAnalytics(
      profileViews: switch (range) {
        VenueDashboardDateRange.today => 86,
        VenueDashboardDateRange.last3Days => 412,
        VenueDashboardDateRange.last7Days => 1248,
        VenueDashboardDateRange.lastMonth => 4820,
        VenueDashboardDateRange.allTime => 28400,
        VenueDashboardDateRange.custom => 980,
      },
      saves: switch (range) {
        VenueDashboardDateRange.today => 14,
        VenueDashboardDateRange.last3Days => 58,
        VenueDashboardDateRange.last7Days => 186,
        VenueDashboardDateRange.lastMonth => 712,
        VenueDashboardDateRange.allTime => 4210,
        VenueDashboardDateRange.custom => 142,
      },
      drinkViews: switch (range) {
        VenueDashboardDateRange.today => 52,
        VenueDashboardDateRange.last3Days => 286,
        VenueDashboardDateRange.last7Days => 892,
        VenueDashboardDateRange.lastMonth => 3410,
        VenueDashboardDateRange.allTime => 19680,
        VenueDashboardDateRange.custom => 710,
      },
      dealViews: switch (range) {
        VenueDashboardDateRange.today => 31,
        VenueDashboardDateRange.last3Days => 174,
        VenueDashboardDateRange.last7Days => 534,
        VenueDashboardDateRange.lastMonth => 1988,
        VenueDashboardDateRange.allTime => 11240,
        VenueDashboardDateRange.custom => 428,
      },
      eventViews: switch (range) {
        VenueDashboardDateRange.today => 44,
        VenueDashboardDateRange.last3Days => 203,
        VenueDashboardDateRange.last7Days => 671,
        VenueDashboardDateRange.lastMonth => 2564,
        VenueDashboardDateRange.allTime => 14820,
        VenueDashboardDateRange.custom => 512,
      },
      profileViewsChange: range == VenueDashboardDateRange.allTime ? null : 12,
      savesChange: range == VenueDashboardDateRange.allTime ? null : 8,
      drinkViewsChange: range == VenueDashboardDateRange.allTime ? null : -4,
      dealViewsChange: range == VenueDashboardDateRange.allTime ? null : 15,
      eventViewsChange: range == VenueDashboardDateRange.allTime ? null : 9,
    );
  }
}
