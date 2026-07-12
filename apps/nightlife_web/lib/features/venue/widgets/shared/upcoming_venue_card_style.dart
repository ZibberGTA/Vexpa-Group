import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

const _presentation = VenuePresentationSupport();

/// Customer-facing start label for upcoming deals/events.
String formatUpcomingStartLabel(DateTime start, {DateTime? now}) =>
    _presentation.formatUpcomingStartLabel(start, now: now);

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
