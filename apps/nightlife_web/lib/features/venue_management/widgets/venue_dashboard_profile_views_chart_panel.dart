import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_views_chart_data.dart';
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
                : _ProfileViewsLineChart(points: points),
          ),
        ],
      ),
    );
  }
}

class _ProfileViewsLineChart extends StatefulWidget {
  const _ProfileViewsLineChart({required this.points});

  final List<VenueProfileViewsDataPoint> points;

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

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final geometry = _ProfileViewsChartGeometry.compute(
                points: widget.points,
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _YAxisLabels(ticks: geometry.yTicks),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedBuilder(
                          animation: _drawAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _ProfileViewsChartPainter(
                                geometry: geometry,
                                drawProgress: _drawAnimation.value,
                                highlightIndex: widget.points.length - 1,
                              ),
                              size: Size(geometry.plotSize.width, constraints.maxHeight),
                            );
                          },
                        ),
                        for (var i = 0; i < geometry.coords.length; i++)
                          _ChartPointHitTarget(
                            center: geometry.coords[i],
                            active: _hoveredIndex == i,
                            onEnter: () => setState(() => _hoveredIndex = i),
                            onExit: () => setState(() {
                              if (_hoveredIndex == i) _hoveredIndex = null;
                            }),
                          ),
                        if (_hoveredIndex != null)
                          _ChartPointTooltip(
                            point: widget.points[_hoveredIndex!],
                            anchor: geometry.coords[_hoveredIndex!],
                            plotWidth: geometry.plotSize.width,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            SizedBox(width: _ProfileViewsChartGeometry.yAxisWidth + AppSpacing.sm),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < widget.points.length; i++)
                    Expanded(
                      child: Text(
                        widget.points[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.ticks});

  final List<double> ticks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ProfileViewsChartGeometry.yAxisWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ticks
            .map(
              (value) => Text(
                _ProfileViewsChartGeometry.formatAxisValue(value),
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

class _ProfileViewsChartGeometry {
  _ProfileViewsChartGeometry({
    required this.plotSize,
    required this.chartRect,
    required this.coords,
    required this.yTicks,
    required this.maxValue,
  });

  static const yAxisWidth = 36.0;

  final Size plotSize;
  final Rect chartRect;
  final List<Offset> coords;
  final List<double> yTicks;
  final double maxValue;

  static _ProfileViewsChartGeometry compute({
    required List<VenueProfileViewsDataPoint> points,
    required Size size,
  }) {
    const horizontalPad = 4.0;
    const verticalPad = 6.0;

    final chartRect = Rect.fromLTWH(
      horizontalPad,
      verticalPad,
      size.width - (horizontalPad * 2),
      size.height - (verticalPad * 2),
    );

    final maxValue = _niceMaxValue(points.map((p) => p.value).reduce(math.max));
    final yTicks = <double>[
      maxValue,
      maxValue * 2 / 3,
      maxValue / 3,
      0,
    ];

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = chartRect.left +
          (chartRect.width * i / math.max(points.length - 1, 1));
      final normalized = maxValue == 0 ? 0.0 : points[i].value / maxValue;
      final y = chartRect.bottom - (chartRect.height * normalized);
      coords.add(Offset(x, y));
    }

    return _ProfileViewsChartGeometry(
      plotSize: size,
      chartRect: chartRect,
      coords: coords,
      yTicks: yTicks,
      maxValue: maxValue,
    );
  }

  static double _niceMaxValue(double rawMax) {
    if (rawMax <= 0) return 1;
    if (rawMax <= 10) return 10;
    if (rawMax <= 50) return 50;
    if (rawMax <= 100) return 100;
    if (rawMax <= 250) return 250;
    if (rawMax <= 500) return 500;
    if (rawMax <= 1000) return 1000;
    if (rawMax <= 2500) return 2500;
    if (rawMax <= 5000) return 5000;
    return (rawMax / 1000).ceil() * 1000;
  }

  static String formatAxisValue(double value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      if (value % 1000 == 0) {
        return '${thousands.toStringAsFixed(0)}k';
      }
      return '${thousands.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }
}

class _ProfileViewsChartPainter extends CustomPainter {
  _ProfileViewsChartPainter({
    required this.geometry,
    required this.drawProgress,
    this.highlightIndex,
  });

  final _ProfileViewsChartGeometry geometry;
  final double drawProgress;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = geometry.chartRect;
    final coords = geometry.coords;

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
    return oldDelegate.geometry != geometry ||
        oldDelegate.drawProgress != drawProgress ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
