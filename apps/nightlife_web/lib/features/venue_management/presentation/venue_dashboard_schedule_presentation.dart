import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/venue_dashboard_schedule.dart';

/// Presentation helpers for the Next 7 Days dashboard schedule widget.
abstract final class VenueDashboardSchedulePresentation {
  VenueDashboardSchedulePresentation._();

  static const bulletAccentColors = <Color>[
    AppColors.primaryPurple,
    AppColors.primaryPink,
    Color(0xFFE91E8C),
    Color(0xFFB832FF),
    Color(0xFFFF4DA6),
  ];

  /// Deterministic bullet colour from a stable activity id.
  static Color bulletColorForItem(VenueDashboardScheduleItem item) {
    final seed = '${item.activityType.name}:${item.id}';
    return bulletAccentColors[seed.hashCode.abs() % bulletAccentColors.length];
  }
}
