import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_profile_completion.dart';
import 'venue_dashboard_controller.dart';

/// Profile completion progress card with CTA to improve the venue profile.
class VenueDashboardProfileCompletionCard extends StatelessWidget {
  const VenueDashboardProfileCompletionCard({
    super.key,
    this.completion = VenueProfileCompletion.empty,
    this.stretchContent = true,
  });

  final VenueProfileCompletion completion;
  final bool stretchContent;

  @override
  Widget build(BuildContext context) {
    final selectTab = VenueDashboardController.maybeOf(context)?.selectTab;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GradientProgressRing(
          progress: completion.progressFraction,
          percentageLabel: '${completion.percentage}%',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          completion.progressLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DrinkSpotButton(
              label: AppStrings.venueDashboardImproveProfile,
              icon: Icons.auto_fix_high_rounded,
              compact: true,
              onPressed: selectTab == null
                  ? null
                  : () => selectTab(VenueDashboardTab.venueProfile),
            ),
          ),
        ),
      ],
    );

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.venueDashboardProfileCompletionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (stretchContent) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [body],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xl),
            body,
          ],
        ],
      ),
    );
  }
}

class _GradientProgressRing extends StatelessWidget {
  const _GradientProgressRing({
    required this.progress,
    required this.percentageLabel,
  });

  final double progress;
  final String percentageLabel;

  @override
  Widget build(BuildContext context) {
    const size = 132.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: PremiumEffects.easeOut,
            builder: (context, animatedProgress, _) {
              return CustomPaint(
                size: const Size(size, size),
                painter: _GradientRingPainter(progress: animatedProgress),
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: PremiumEffects.easeOut,
            builder: (context, _, __) {
              return ShaderMask(
                shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                child: Text(
                  percentageLabel,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: progress >= 1 ? 30 : 28,
                    letterSpacing: -0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    const stroke = 10.0;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.primaryPurple.withValues(alpha: 0.18);

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          AppColors.primaryPink,
          AppColors.primaryPurple,
          AppColors.primaryPink,
        ],
      ).createShader(arcRect);

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
