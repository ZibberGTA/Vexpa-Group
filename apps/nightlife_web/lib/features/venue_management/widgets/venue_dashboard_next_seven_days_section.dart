import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_schedule.dart';
import '../models/venue_dashboard_tab.dart';
import '../presentation/venue_dashboard_schedule_presentation.dart';
import 'venue_dashboard_controller.dart';

/// Rolling seven-day schedule panel for the venue dashboard home tab.
class VenueDashboardNextSevenDaysSection extends StatelessWidget {
  const VenueDashboardNextSevenDaysSection({
    super.key,
    required this.schedule,
    this.loading = false,
  });

  final VenueDashboardSchedule schedule;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final resolvedSchedule = schedule.days.length == 7
        ? schedule
        : (controller?.homeData?.nextSevenDaysSchedule ?? schedule);

    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg + 2),
        borderRadius: AppSpacing.radiusLg,
        elevation: GlassElevation.soft,
        innerHighlight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NextSevenDaysHeader(controller: controller),
            const SizedBox(height: AppSpacing.lg),
            if (loading)
              const _NextSevenDaysLoadingRow()
            else
              _NextSevenDaysCards(days: resolvedSchedule.days),
          ],
        ),
      ),
    );
  }
}

class _NextSevenDaysHeader extends StatelessWidget {
  const _NextSevenDaysHeader({required this.controller});

  final VenueDashboardController? controller;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.white.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
          height: 1.35,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.venueDashboardNextSevenDaysTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.venueDashboardNextSevenDaysSubtitle,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _ViewFullCalendarButton(controller: controller),
      ],
    );
  }
}

class _ViewFullCalendarButton extends StatelessWidget {
  const _ViewFullCalendarButton({required this.controller});

  final VenueDashboardController? controller;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: controller == null
          ? null
          : () => controller!.selectTab(VenueDashboardTab.events),
      icon: const Icon(Icons.calendar_month_outlined, size: 16),
      label: const Text(AppStrings.venueDashboardViewFullCalendar),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.38),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

class _NextSevenDaysCards extends StatelessWidget {
  const _NextSevenDaysCards({required this.days});

  final List<VenueDashboardScheduleDay> days;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        const minCardWidth = 132.0;
        final available = constraints.maxWidth;
        final cardsPerRow =
            (available / (minCardWidth + gap)).floor().clamp(1, 7);

        final rows = <List<VenueDashboardScheduleDay>>[];
        for (var i = 0; i < days.length; i += cardsPerRow) {
          final end = (i + cardsPerRow).clamp(0, days.length);
          rows.add(days.sublist(i, end));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(
                        child: _NextSevenDaysDayCard(day: rows[r][i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NextSevenDaysDayCard extends StatelessWidget {
  const _NextSevenDaysDayCard({required this.day});

  final VenueDashboardScheduleDay day;

  @override
  Widget build(BuildContext context) {
    final cardBody = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        day.isToday ? AppSpacing.lg + 4 : AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: AppColors.surfaceGradient,
        border: Border.all(
          color: day.isToday
              ? Colors.transparent
              : AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
        boxShadow: day.isToday ? null : PremiumEffects.softCardShadow(intensity: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            day.dayName.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryPink.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.15,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            day.dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.55),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!day.hasActivity)
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  VenueDashboardSchedule.emptyDayMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                ),
              ),
            )
          else
            for (final item in day.items) ...[
              _ScheduleItemRow(item: item),
              if (item != day.items.last) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );

    final semanticsLabel = day.isToday
        ? 'Today, ${day.dayName}, ${day.dateLabel}'
        : '${day.dayName}, ${day.dateLabel}';

    if (!day.isToday) {
      return Semantics(
        label: semanticsLabel,
        child: cardBody,
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PremiumGradientBorder(
            borderRadius: AppSpacing.radiusMd,
            glow: true,
            child: cardBody,
          ),
          Positioned(
            top: -11,
            left: 0,
            right: 0,
            child: Center(
              child: _TodayBadge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: PremiumEffects.activeNavGlow(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'TODAY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 10,
              ),
        ),
      ),
    );
  }
}

class _ScheduleItemRow extends StatelessWidget {
  const _ScheduleItemRow({required this.item});

  final VenueDashboardScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final bulletColor =
        VenueDashboardSchedulePresentation.bulletColorForItem(item);
    final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.88),
          fontWeight: FontWeight.w500,
          height: 1.35,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bulletColor.withValues(alpha: 0.45),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
              ),
              if (item.timeLabel != null) ...[
                const SizedBox(height: 2),
                Text(item.timeLabel!, style: timeStyle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextSevenDaysLoadingRow extends StatelessWidget {
  const _NextSevenDaysLoadingRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        const minCardWidth = 132.0;
        final cardsPerRow =
            (constraints.maxWidth / (minCardWidth + gap)).floor().clamp(1, 7);

        return Row(
          children: [
            for (var i = 0; i < cardsPerRow; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: Container(
                  height: 188,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
