import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_whats_next_action.dart';
import 'venue_dashboard_controller.dart';

/// Full-width suggested actions panel for the venue dashboard home tab.
class VenueDashboardWhatsNextSection extends StatelessWidget {
  const VenueDashboardWhatsNextSection({
    super.key,
    this.actions = const [],
  });

  final List<VenueDashboardWhatsNextAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.white.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
          height: 1.35,
        );

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppStrings.venueDashboardWhatsNextTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.venueDashboardWhatsNextSubtitle,
                    textAlign: TextAlign.end,
                    style: subtitleStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpacing.md;
                const minCardWidth = 220.0;
                final available = constraints.maxWidth;
                final cardsPerRow =
                    (available / (minCardWidth + gap)).floor().clamp(1, 4);

                final rows = <List<VenueDashboardWhatsNextAction>>[];
                for (var i = 0; i < actions.length; i += cardsPerRow) {
                  final end = (i + cardsPerRow).clamp(0, actions.length);
                  rows.add(actions.sublist(i, end));
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
                                child: _WhatsNextActionCard(
                                  action: rows[r][i],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNextActionCard extends StatefulWidget {
  const _WhatsNextActionCard({required this.action});

  final VenueDashboardWhatsNextAction action;

  @override
  State<_WhatsNextActionCard> createState() => _WhatsNextActionCardState();
}

class _WhatsNextActionCardState extends State<_WhatsNextActionCard> {
  static const _iconContainerSize = 51.0;
  static const _iconSize = 27.0;

  bool _hovered = false;

  void _onPressed() {
    final selectTab = VenueDashboardController.maybeOf(context)?.selectTab;
    if (selectTab != null) {
      selectTab(widget.action.targetTab);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.action.buttonLabel} — coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PremiumHoverLift(
        borderRadius: AppSpacing.radiusMd,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          padding: const EdgeInsets.all(AppSpacing.lg + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: AppColors.surfaceGradient,
            border: Border.all(
              color: _hovered
                  ? AppColors.primaryPink.withValues(alpha: 0.32)
                  : AppColors.primaryPurple.withValues(alpha: 0.16),
            ),
            boxShadow: _hovered ? PremiumEffects.softCardShadow(intensity: 0.55) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: _iconContainerSize,
                    height: _iconContainerSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryPink.withValues(alpha: _hovered ? 0.24 : 0.14),
                          AppColors.primaryPurple.withValues(alpha: _hovered ? 0.28 : 0.18),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      action.icon,
                      size: _iconSize,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          action.message,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Spacer(),
              Center(
                child: _WhatsNextActionButton(
                  label: action.buttonLabel,
                  hovered: _hovered,
                  onPressed: _onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsNextActionButton extends StatefulWidget {
  const _WhatsNextActionButton({
    required this.label,
    required this.hovered,
    required this.onPressed,
  });

  final String label;
  final bool hovered;
  final VoidCallback onPressed;

  @override
  State<_WhatsNextActionButton> createState() => _WhatsNextActionButtonState();
}

class _WhatsNextActionButtonState extends State<_WhatsNextActionButton> {
  bool _buttonHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.hovered || _buttonHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _buttonHovered = true),
      onExit: (_) => setState(() => _buttonHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: highlighted ? AppColors.brandGradient : null,
            color: highlighted ? null : AppColors.primaryPurple.withValues(alpha: 0.14),
            border: Border.all(
              color: highlighted
                  ? Colors.transparent
                  : AppColors.primaryPurple.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
