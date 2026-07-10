import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_page_config.dart';
import '../models/venue_page_quick_action.dart';
import 'venue_dashboard_controller.dart';
import 'page/venue_dashboard_page_widgets.dart';

/// Quick action shortcuts for venue management pages.
class VenueDashboardQuickActionsPanel extends StatelessWidget {
  const VenueDashboardQuickActionsPanel({
    super.key,
    this.actions,
    this.onQuickAction,
  });

  /// When null, uses the dashboard home quick actions.
  final List<VenuePageQuickAction>? actions;
  final void Function(VenuePageQuickAction action)? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final selectTab = VenueDashboardController.maybeOf(context)?.selectTab;
    final resolvedActions =
        actions ?? VenueDashboardTab.dashboard.pageConfig.quickActions;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.venueDashboardQuickActionsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < resolvedActions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _QuickActionButton(
              label: resolvedActions[i].label,
              icon: resolvedActions[i].icon,
              onPressed: () {
                final action = resolvedActions[i];
                if (action.actionKey != null && onQuickAction != null) {
                  onQuickAction!(action);
                  return;
                }
                final targetTab = action.targetTab;
                if (targetTab != null && selectTab != null) {
                  selectTab(targetTab);
                  return;
                }
                if (onQuickAction != null) {
                  onQuickAction!(action);
                  return;
                }
                showVenuePagePlaceholderAction(context, action.label);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        transform: Matrix4.identity()..translate(0.0, _hovered && widget.onPressed != null ? -2.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: _hovered && widget.onPressed != null
              ? AppColors.brandGradient
              : null,
          color: _hovered && widget.onPressed != null
              ? null
              : AppColors.surfaceElevated.withValues(alpha: 0.78),
          border: Border.all(
            color: _hovered
                ? Colors.transparent
                : AppColors.primaryPurple.withValues(alpha: 0.18),
          ),
          boxShadow: _hovered && widget.onPressed != null
              ? PremiumEffects.hoverGlow(intensity: 0.55)
              : null,
        ),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _hovered ? AppColors.white : AppColors.primaryPink,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _hovered
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
