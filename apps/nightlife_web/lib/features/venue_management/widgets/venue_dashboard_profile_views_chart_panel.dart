import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_views_chart_data.dart';
import '../utils/venue_profile_views_chart_presentation.dart';
import 'venue_dashboard_date_range_dropdown.dart';

/// Profile views line chart panel with an independent timeframe filter.
class VenueDashboardProfileViewsChartPanel extends StatefulWidget {
  const VenueDashboardProfileViewsChartPanel({
    super.key,
    this.loading = false,
    this.points = const [],
    this.selectedRange = VenueDashboardDateRange.defaultRange,
    this.onRangeChanged,
  });

  final bool loading;
  final List<VenueProfileViewsDataPoint> points;
  final VenueDashboardDateRange selectedRange;
  final ValueChanged<VenueDashboardDateRange>? onRangeChanged;

  @override
  State<VenueDashboardProfileViewsChartPanel> createState() =>
      _VenueDashboardProfileViewsChartPanelState();
}

class _VenueDashboardProfileViewsChartPanelState
    extends State<VenueDashboardProfileViewsChartPanel> {
  @override
  Widget build(BuildContext context) {
    final points = widget.loading ? const <VenueProfileViewsDataPoint>[] : widget.points;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppStrings.venueDashboardProfileViewsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              VenueDashboardDateRangeDropdown(
                selectedRange: widget.selectedRange,
                options: VenueDashboardDateRange.chartOptions,
                onChanged: widget.onRangeChanged ?? (_) {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: widget.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPink,
                      strokeWidth: 2,
                    ),
                  )
                : _ProfileViewsLineChart(
                    points: points,
                    selectedRange: widget.selectedRange,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileViewsLineChart extends StatefulWidget {
  const _ProfileViewsLineChart({
    required this.points,
    required this.selectedRange,
  });

  final List<VenueProfileViewsDataPoint> points;
  final VenueDashboardDateRange selectedRange;

  @override
  State<_ProfileViewsLineChart> createState() => _ProfileViewsLineChartState();
}

class _ProfileViewsLineChartState extends State<_ProfileViewsLineChart>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late final AnimationController _drawController;
  late final Animation<double> _drawAnimation;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: PremiumEffects.slow,
    );
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: PremiumEffects.easeOut,
    );
    _drawController.forward();
  }

  @override
  void didUpdateWidget(covariant _ProfileViewsLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _drawController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const Center(
        child: Text(
          'No profile view data yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final displayPoints = VenueProfileViewsChartPresentation.normalizeForDisplay(
      points: widget.points,
      range: widget.selectedRange,
    );

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final plotWidth = VenueProfileViewsChartPresentation.plotAreaWidth(
                totalWidth: constraints.maxWidth,
              );
              final plotHeight = constraints.maxHeight - AppSpacing.sm - 16;
              final layout = ProfileViewsChartPlotLayout.compute(
                points: displayPoints,
                plotWidth: plotWidth,
                plotHeight: plotHeight,
              );
              final visibleLabelIndices =
                  VenueProfileViewsChartPresentation.visibleLabelIndices(
                pointCount: displayPoints.length,
                plotWidth: plotWidth,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _YAxisLabels(ticks: layout.yTicks),
                        const SizedBox(width: VenueProfileViewsChartPresentation.yAxisGap),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              AnimatedBuilder(
                                animation: _drawAnimation,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: _ProfileViewsChartPainter(
                                      layout: layout,
                                      drawProgress: _drawAnimation.value,
                                      highlightIndex: displayPoints.length - 1,
                                    ),
                                    size: Size(plotWidth, plotHeight),
                                  );
                                },
                              ),
                              for (var i = 0; i < layout.coords.length; i++)
                                _ChartPointHitTarget(
                                  center: layout.coords[i],
                                  active: _hoveredIndex == i,
                                  onEnter: () => setState(() => _hoveredIndex = i),
                                  onExit: () => setState(() {
                                    if (_hoveredIndex == i) _hoveredIndex = null;
                                  }),
                                ),
                              if (_hoveredIndex != null)
                                _ChartPointTooltip(
                                  point: displayPoints[_hoveredIndex!],
                                  anchor: layout.coords[_hoveredIndex!],
                                  plotWidth: plotWidth,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: VenueProfileViewsChartPresentation.yAxisWidth +
                            VenueProfileViewsChartPresentation.yAxisGap,
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 16,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final index in visibleLabelIndices)
                                _ChartXAxisLabel(
                                  label: displayPoints[index].label,
                                  centerX: layout.labelCenterX(index),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartXAxisLabel extends StatelessWidget {
  const _ChartXAxisLabel({
    required this.label,
    required this.centerX,
  });

  final String label;
  final double centerX;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centerX,
      top: 0,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.ticks});

  final List<double> ticks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: VenueProfileViewsChartPresentation.yAxisWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ticks
            .map(
              (value) => Text(
                ProfileViewsChartPlotLayout.formatAxisValue(value),
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChartPointHitTarget extends StatelessWidget {
  const _ChartPointHitTarget({
    required this.center,
    required this.active,
    required this.onEnter,
    required this.onExit,
  });

  final Offset center;
  final bool active;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    const hitSize = 28.0;

    return Positioned(
      left: center.dx - hitSize / 2,
      top: center.dy - hitSize / 2,
      child: MouseRegion(
        onEnter: (_) => onEnter(),
        onExit: (_) => onExit(),
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.primaryPink.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: active
                  ? Border.all(
                      color: AppColors.primaryPink.withValues(alpha: 0.45),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPointTooltip extends StatelessWidget {
  const _ChartPointTooltip({
    required this.point,
    required this.anchor,
    required this.plotWidth,
  });

  final VenueProfileViewsDataPoint point;
  final Offset anchor;
  final double plotWidth;

  @override
  Widget build(BuildContext context) {
    const tooltipWidth = 148.0;
    const tooltipHeight = 58.0;
    const gap = 12.0;

    var left = anchor.dx - tooltipWidth / 2;
    left = left.clamp(0.0, plotWidth - tooltipWidth);

    var top = anchor.dy - tooltipHeight - gap;
    if (top < 0) {
      top = anchor.dy + gap;
    }

    final valueLabel = point.value == point.value.roundToDouble()
        ? point.value.round().toString()
        : point.value.toStringAsFixed(1);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                point.label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$valueLabel profile views',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileViewsChartPainter extends CustomPainter {
  _ProfileViewsChartPainter({
    required this.layout,
    required this.drawProgress,
    this.highlightIndex,
  });

  final ProfileViewsChartPlotLayout layout;
  final double drawProgress;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = layout.chartRect;
    final coords = layout.coords;

    final gridPaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (coords.length >= 2) {
      final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (var i = 1; i < coords.length; i++) {
        linePath.lineTo(coords[i].dx, coords[i].dy);
      }

      final metrics = linePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final animatedPath = metric.extractPath(
          0,
          metric.length * drawProgress.clamp(0.0, 1.0),
        );

        final fillPath = Path()
          ..addPath(animatedPath, Offset.zero)
          ..lineTo(
            _pointOnPathAtProgress(coords, drawProgress).dx,
            chartRect.bottom,
          )
          ..lineTo(coords.first.dx, chartRect.bottom)
          ..close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPink.withValues(alpha: 0.22),
              AppColors.primaryPurple.withValues(alpha: 0.06),
              AppColors.primaryPurple.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(chartRect);

        canvas.drawPath(fillPath, fillPaint);

        final linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.75
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = AppColors.brandGradient.createShader(chartRect);

        canvas.drawPath(animatedPath, linePaint);
      }
    }

    final visibleCount = (coords.length * drawProgress).ceil().clamp(0, coords.length);
    for (var i = 0; i < visibleCount; i++) {
      final point = coords[i];
      final isHighlight = highlightIndex != null && i == highlightIndex;

      if (isHighlight) {
        canvas.drawCircle(
          point,
          12,
          Paint()..color = AppColors.primaryPink.withValues(alpha: 0.14),
        );
        canvas.drawCircle(
          point,
          8,
          Paint()..color = AppColors.trailGold.withValues(alpha: 0.22),
        );
      } else {
        canvas.drawCircle(
          point,
          7,
          Paint()..color = AppColors.primaryPink.withValues(alpha: 0.12),
        );
      }

      canvas.drawCircle(
        point,
        isHighlight ? 5 : 4,
        Paint()..color = isHighlight ? AppColors.trailGold : AppColors.primaryPink,
      );
      canvas.drawCircle(
        point,
        isHighlight ? 2 : 1.5,
        Paint()..color = AppColors.white.withValues(alpha: 0.85),
      );
    }
  }

  Offset _pointOnPathAtProgress(List<Offset> coords, double progress) {
    if (coords.length <= 1) return coords.first;
    final index = ((coords.length - 1) * progress)
        .clamp(0.0, (coords.length - 1).toDouble());
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return coords[lower];
    final t = index - lower;
    return Offset.lerp(coords[lower], coords[upper], t)!;
  }

  @override
  bool shouldRepaint(covariant _ProfileViewsChartPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.drawProgress != drawProgress ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
