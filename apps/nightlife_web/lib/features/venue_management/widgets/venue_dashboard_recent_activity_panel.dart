import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../presentation/venue_management_activity_presentation.dart';
import 'venue_dashboard_controller.dart';

/// Recent venue management activity feed for the dashboard sidebar.
class VenueDashboardRecentActivityPanel extends StatelessWidget {
  const VenueDashboardRecentActivityPanel({
    super.key,
    this.useControllerFeed = false,
    this.pageRecentActivity,
    this.isLoadingPageRecentActivity = false,
    this.pageRecentActivityError,
    this.onRetryPageRecentActivity,
  });

  /// When true, reads loading/content/error state from [VenueDashboardController].
  final bool useControllerFeed;

  /// Canonical page-scoped activity supplied by [VenueDashboardPageScaffold].
  final List<VenueManagementActivityPresentation>? pageRecentActivity;
  final bool isLoadingPageRecentActivity;
  final Object? pageRecentActivityError;
  final Future<void> Function()? onRetryPageRecentActivity;

  static const int maxItems = 10;

  @override
  Widget build(BuildContext context) {
    if (useControllerFeed) {
      final controller = VenueDashboardController.maybeOf(context);
      return _RecentActivityCard(
        loading: controller?.isLoadingRecentActivity ?? false,
        error: controller?.recentActivityError,
        onRetry: controller?.onRetryRecentActivity,
        items: controller?.recentManagementActivity ?? const [],
      );
    }

    return _RecentActivityCard(
      loading: isLoadingPageRecentActivity,
      error: pageRecentActivityError,
      onRetry: onRetryPageRecentActivity,
      items: pageRecentActivity ?? const [],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    this.items = const [],
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<VenueManagementActivityPresentation> items;
  final bool loading;
  final Object? error;
  final Future<void> Function()? onRetry;

  List<VenueManagementActivityPresentation> get _visibleItems =>
      items.take(VenueDashboardRecentActivityPanel.maxItems).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.venueDashboardRecentActivityTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (loading)
            const _RecentActivityLoadingList(key: Key('recent-activity-loading'))
          else if (error != null)
            _RecentActivityErrorState(onRetry: onRetry)
          else if (items.isEmpty)
            const _RecentActivityEmptyState()
          else
            for (var i = 0; i < _visibleItems.length; i++) ...[
              _ActivityRow(activity: _visibleItems[i]),
              if (i < _visibleItems.length - 1)
                Divider(
                  height: AppSpacing.lg,
                  color: AppColors.primaryPurple.withValues(alpha: 0.14),
                ),
            ],
        ],
      ),
    );
  }
}

class _RecentActivityLoadingList extends StatelessWidget {
  const _RecentActivityLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index == 2 ? 0 : AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityEmptyState extends StatelessWidget {
  const _RecentActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.venueDashboardRecentActivityEmptyTitle,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.venueDashboardRecentActivityEmptyBody,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityErrorState extends StatelessWidget {
  const _RecentActivityErrorState({this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.venueDashboardRecentActivityError,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => onRetry!.call(),
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final VenueManagementActivityPresentation activity;

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
            semanticLabel: activity.title,
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
              if (activity.description != null &&
                  activity.description!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  activity.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                activity.metadataLine,
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
