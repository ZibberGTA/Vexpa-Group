import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/premium_effects.dart';

/// Standard page header with title, subtitle and optional primary action.
class VenueDashboardPageHeader extends StatelessWidget {
  const VenueDashboardPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
  });

  final String title;
  final String subtitle;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final stackOnNarrow = Breakpoints.isMobile(context) || Breakpoints.isTablet(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ],
    );

    final action = primaryActionLabel == null
        ? null
        : _PrimaryActionButton(
            label: primaryActionLabel!,
            icon: primaryActionIcon ?? Icons.add_rounded,
            onPressed: onPrimaryAction,
          );

    if (stackOnNarrow || action == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(alignment: Alignment.centerLeft, child: action),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: AppSpacing.lg),
        action,
      ],
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: _hovered ? AppColors.brandGradient : null,
            color: _hovered ? null : AppColors.primaryPurple.withValues(alpha: 0.16),
            border: Border.all(
              color: _hovered
                  ? Colors.transparent
                  : AppColors.primaryPurple.withValues(alpha: 0.24),
            ),
            boxShadow: _hovered ? PremiumEffects.hoverGlow(intensity: 0.7) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showVenuePagePlaceholderAction(BuildContext context, String actionLabel) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$actionLabel — coming soon.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showVenueStyledComingSoonMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.35),
        ),
      ),
    ),
  );
}

/// Glass section panel used across venue management pages.
class VenuePageSection extends StatelessWidget {
  const VenuePageSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.fillHeight = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final section = GlassContainer(
      padding: padding,
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (fillHeight) Expanded(child: child) else child,
        ],
      ),
    );

    if (!fillHeight) return section;

    return SizedBox(
      width: double.infinity,
      child: section,
    );
  }
}

/// Compact metric card for page-level statistics.
class VenuePageMetricCard extends StatefulWidget {
  const VenuePageMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  State<VenuePageMetricCard> createState() => _VenuePageMetricCardState();
}

class _VenuePageMetricCardState extends State<VenuePageMetricCard> {
  bool _hovered = false;

  int? _parseNumericValue() => int.tryParse(widget.value.replaceAll(',', ''));

  @override
  Widget build(BuildContext context) {
    final numericValue = _parseNumericValue();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        child: PremiumGradientBorder(
          subtle: true,
          glow: _hovered,
          borderRadius: AppSpacing.radiusLg,
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.lg + 2),
            borderRadius: AppSpacing.radiusLg - 1,
            opacity: _hovered ? 0.86 : 0.78,
            elevation: _hovered ? GlassElevation.soft : GlassElevation.none,
            innerHighlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    PremiumIconBadge(
                      icon: widget.icon,
                      highlighted: _hovered,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (numericValue != null)
                  AnimatedStatValue(
                    value: numericValue,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.05,
                      letterSpacing: -0.4,
                    ),
                  )
                else
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.05,
                      letterSpacing: -0.4,
                    ),
                  ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.88),
                      fontSize: 11.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive row of metric cards.
class VenuePageMetricRow extends StatelessWidget {
  const VenuePageMetricRow({super.key, required this.metrics});

  final List<VenuePageMetricCard> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final minWidth = 160.0;
        final count = metrics.length;
        final fitsOneRow = constraints.maxWidth >= (minWidth * count) + (gap * (count - 1));

        if (fitsOneRow) {
          return Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: metrics[i]),
              ],
            ],
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: Breakpoints.isMobile(context)
                      ? constraints.maxWidth
                      : (constraints.maxWidth - gap) / 2,
                  child: metric,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Filter chip row for list pages.
class VenuePageFilterChips extends StatelessWidget {
  const VenuePageFilterChips({
    super.key,
    required this.labels,
    this.selectedIndex = 0,
    this.selectedLabel,
    this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final String? selectedLabel;
  final ValueChanged<String>? onSelected;

  int get _resolvedSelectedIndex {
    if (selectedLabel != null) {
      final index = labels.indexOf(selectedLabel!);
      if (index >= 0) return index;
    }
    return selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _resolvedSelectedIndex;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < labels.length; i++)
          _FilterChip(
            label: labels[i],
            selected: i == activeIndex,
            onTap: onSelected == null ? null : () => onSelected!(labels[i]),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: selected ? AppColors.brandGradient : null,
        color: selected ? null : AppColors.surfaceElevated.withValues(alpha: 0.72),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.primaryPurple.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );

    if (onTap == null) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

/// Simple mock data table for management pages.
class VenuePageDataTable extends StatelessWidget {
  const VenuePageDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  Expanded(
                    flex: i == 0 ? 2 : 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        columns[i],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Divider(color: AppColors.primaryPurple.withValues(alpha: 0.16)),
            for (var i = 0; i < rows.length; i++) ...[
              Row(
                children: [
                  for (var j = 0; j < rows[i].length; j++)
                    Expanded(
                      flex: j == 0 ? 2 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          rows[i][j],
                          style: TextStyle(
                            color: j == 0 ? AppColors.white : AppColors.textSecondary,
                            fontWeight: j == 0 ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (i < rows.length - 1)
                Divider(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
            ],
          ],
        );
      },
    );
  }
}

/// Key/value summary row for profile-style pages.
class VenuePageSummaryTile extends StatelessWidget {
  const VenuePageSummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.55),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              color: AppColors.primaryPurple.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryPink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder chart block for analytics pages.
class VenuePageChartPlaceholder extends StatelessWidget {
  const VenuePageChartPlaceholder({
    super.key,
    required this.title,
    this.height = 180,
  });

  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.16)),
      ),
      child: CustomPaint(
        painter: _MiniChartPainter(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primaryPink.withValues(alpha: 0.55);

    final path = Path();
    const points = [0.72, 0.58, 0.81, 0.64, 0.92, 0.78, 0.86];
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
