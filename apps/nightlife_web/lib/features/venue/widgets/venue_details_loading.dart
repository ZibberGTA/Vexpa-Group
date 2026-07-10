import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Premium skeleton loader while the venue details page loads.
class VenueDetailsLoading extends StatefulWidget {
  const VenueDetailsLoading({super.key});

  @override
  State<VenueDetailsLoading> createState() => _VenueDetailsLoadingState();
}

class _VenueDetailsLoadingState extends State<VenueDetailsLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = Breakpoints.horizontalPadding(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final bannerHeight = isDesktop ? 400.0 : 280.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final opacity = 0.35 + (_pulse.value * 0.25);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.lg,
            inset,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MainSkeleton(
                            bannerHeight: bannerHeight,
                            opacity: opacity,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        SizedBox(
                          width: 360,
                          child: _PanelSkeleton(opacity: opacity),
                        ),
                      ],
                    )
                  : _MainSkeleton(
                      bannerHeight: bannerHeight,
                      opacity: opacity,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _MainSkeleton extends StatelessWidget {
  const _MainSkeleton({
    required this.bannerHeight,
    required this.opacity,
  });

  final double bannerHeight;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBlock(
          height: bannerHeight,
          opacity: opacity,
          radius: AppSpacing.radiusXl,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SkeletonBlock(height: 160, opacity: opacity),
        const SizedBox(height: AppSpacing.lg),
        _SkeletonBlock(height: 280, opacity: opacity),
        const SizedBox(height: AppSpacing.lg),
        _SkeletonBlock(height: 220, opacity: opacity),
      ],
    );
  }
}

class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBlock(height: 420, opacity: opacity),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.opacity,
    this.radius = AppSpacing.radiusLg,
  });

  final double height;
  final double opacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: opacity),
            AppColors.primaryPurple.withValues(alpha: opacity * 0.45),
            AppColors.surface.withValues(alpha: opacity * 0.8),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}
