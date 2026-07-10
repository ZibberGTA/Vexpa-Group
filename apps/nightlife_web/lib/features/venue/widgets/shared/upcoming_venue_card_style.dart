import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

const _weekdayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _monthLabels = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Customer-facing start label for upcoming deals/events.
String formatUpcomingStartLabel(DateTime start, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final weekday = _weekdayLabels[start.weekday - 1];
  final hour = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final minute = start.minute.toString().padLeft(2, '0');
  final period = start.hour >= 12 ? 'PM' : 'AM';
  final timeLabel = '$hour:$minute $period';

  final daysUntil = DateTime(start.year, start.month, start.day)
      .difference(DateTime(clock.year, clock.month, clock.day))
      .inDays;

  if (daysUntil >= 0 && daysUntil <= 6) {
    return 'Starts $weekday at $timeLabel';
  }

  return 'Available from ${start.day} ${_monthLabels[start.month - 1]}';
}

/// Small badge used on upcoming public cards.
class UpcomingVenueBadge extends StatelessWidget {
  const UpcomingVenueBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.55),
            AppColors.trailGold.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.trailGold.withValues(alpha: 0.55),
        ),
      ),
      child: const Text(
        'Upcoming',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Shared glass-card decoration for upcoming public deals/events.
BoxDecoration upcomingVenueCardDecoration({bool hovered = false}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryPurple.withValues(alpha: hovered ? 0.42 : 0.28),
        AppColors.trailGold.withValues(alpha: hovered ? 0.24 : 0.14),
      ],
    ),
    boxShadow: hovered
        ? [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
        : null,
  );
}
