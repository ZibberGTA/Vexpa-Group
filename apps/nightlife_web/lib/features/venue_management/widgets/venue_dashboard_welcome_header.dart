import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/services/auth_service.dart';
import '../models/venue_dashboard_date_range.dart';
import '../utils/venue_dashboard_welcome_name.dart';
import 'venue_dashboard_controller.dart';
import 'venue_dashboard_date_range_dropdown.dart';

/// Welcome header row with greeting and date range filter.
class VenueDashboardWelcomeHeader extends StatelessWidget {
  const VenueDashboardWelcomeHeader({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final VenueDashboardDateRange selectedRange;
  final ValueChanged<VenueDashboardDateRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final contextData = VenueDashboardController.maybeOf(context)?.contextData;
    final stackOnNarrow = Breakpoints.isMobile(context);

    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data ?? AuthService.currentUser;
        final title = VenueDashboardWelcomeName.welcomeTitle(
          user: user,
          contextData: contextData,
        );

        final greeting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.venueDashboardWelcomeSubtitle,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.92),
                fontSize: 15,
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),
          ],
        );

        final dropdown = VenueDashboardDateRangeDropdown(
          selectedRange: selectedRange,
          onChanged: onRangeChanged,
        );

        if (stackOnNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              greeting,
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: dropdown,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: AppSpacing.lg),
            dropdown,
          ],
        );
      },
    );
  }
}
