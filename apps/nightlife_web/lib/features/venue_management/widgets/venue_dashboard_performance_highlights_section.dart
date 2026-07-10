import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_performance_highlight.dart';
import 'venue_dashboard_controller.dart';

/// Full-width performance highlights panel for the venue dashboard home tab.
class VenueDashboardPerformanceHighlightsSection extends StatelessWidget {
  const VenueDashboardPerformanceHighlightsSection({
    super.key,
    this.highlights = const [],
  });

  final List<VenueDashboardPerformanceHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }

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
            Text(
              AppStrings.venueDashboardPerformanceHighlightsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpacing.md;
                const minCardWidth = 220.0;
                final available = constraints.maxWidth;
                final cardsPerRow =
                    (available / (minCardWidth + gap)).floor().clamp(1, 4);

                final rows = <List<VenueDashboardPerformanceHighlight>>[];
                for (var i = 0; i < highlights.length; i += cardsPerRow) {
                  final end = (i + cardsPerRow).clamp(0, highlights.length);
                  rows.add(highlights.sublist(i, end));
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
                                child: _PerformanceHighlightCard(
                                  highlight: rows[r][i],
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

class _PerformanceHighlightCard extends StatefulWidget {
  const _PerformanceHighlightCard({required this.highlight});

  final VenueDashboardPerformanceHighlight highlight;

  @override
  State<_PerformanceHighlightCard> createState() =>
      _PerformanceHighlightCardState();
}

class _PerformanceHighlightCardState extends State<_PerformanceHighlightCard> {
  static const _iconContainerSize = 51.0;
  static const _iconSize = 27.0;

  bool _hovered = false;

  void _onPressed() {
    final tab = widget.highlight.targetTab;
    if (tab == null) return;

    final selectTab = VenueDashboardController.maybeOf(context)?.selectTab;
    if (selectTab != null) {
      selectTab(tab);
      return;
    }

    _showPlaceholder(context, widget.highlight.buttonLabel);
  }

  void _showPlaceholder(BuildContext context, String actionLabel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionLabel — coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlight;
    final accent = highlight.accent.color;

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: _hovered ? 0.14 : 0.08),
                AppColors.surface.withValues(alpha: 0.94),
              ],
            ),
            border: Border.all(
              color: _hovered
                  ? accent.withValues(alpha: 0.34)
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
                      color: accent.withValues(alpha: _hovered ? 0.22 : 0.14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      highlight.icon,
                      size: _iconSize,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      highlight.message,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Spacer(),
              Center(
                child: _HighlightActionButton(
                  label: highlight.buttonLabel,
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

class _HighlightActionButton extends StatefulWidget {
  const _HighlightActionButton({
    required this.label,
    required this.hovered,
    required this.onPressed,
  });

  final String label;
  final bool hovered;
  final VoidCallback onPressed;

  @override
  State<_HighlightActionButton> createState() => _HighlightActionButtonState();
}

class _HighlightActionButtonState extends State<_HighlightActionButton> {
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
