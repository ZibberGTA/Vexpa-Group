import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/venue_dashboard_activity.dart';

/// Recent venue activity feed with a placeholder View All action.
class VenueDashboardRecentActivityPanel extends StatelessWidget {
  const VenueDashboardRecentActivityPanel({
    super.key,
    this.activities = const [],
  });

  final List<VenueDashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    final items = activities.take(5).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.venueDashboardRecentActivityTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (items.isNotEmpty)
                _ViewAllLink(onPressed: () => _showActivityPlaceholder(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const Text(
              'No activity yet.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _ActivityRow(activity: items[i]),
              if (i < items.length - 1)
                Divider(
                  height: AppSpacing.lg,
                  color: AppColors.primaryPurple.withValues(alpha: 0.14),
                ),
            ],
        ],
      ),
    );
  }

  void _showActivityPlaceholder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.28)),
        ),
        title: Text(
          AppStrings.venueDashboardRecentActivityTitle,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          AppStrings.venueDashboardRecentActivityPlaceholder,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ViewAllLink extends StatefulWidget {
  const _ViewAllLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ViewAllLink> createState() => _ViewAllLinkState();
}

class _ViewAllLinkState extends State<_ViewAllLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Text(
          AppStrings.venueDashboardViewAll,
          style: TextStyle(
            color: _hovered ? AppColors.primaryPink : AppColors.primaryPurple,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: _hovered
                ? AppColors.primaryPink.withValues(alpha: 0.75)
                : AppColors.primaryPurple.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final VenueDashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPink.withValues(alpha: 0.18),
                AppColors.primaryPurple.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            activity.icon,
            size: 16,
            color: AppColors.primaryPink,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                activity.timestampLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
