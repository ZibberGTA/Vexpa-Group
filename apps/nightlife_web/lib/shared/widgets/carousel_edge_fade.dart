import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';

/// Soft left/right fade for horizontal carousels.
///
/// Cards dissolve into the page background instead of hitting a hard clip edge.
/// Wrap any horizontal scroll view; navigation controls should sit above this
/// widget in a [Stack] so they remain fully visible.
class CarouselEdgeFade extends StatelessWidget {
  const CarouselEdgeFade({
    super.key,
    required this.child,
    this.edgeWidth,
  });

  final Widget child;

  /// Optional override for fade zone width in logical pixels.
  final double? edgeWidth;

  static double edgeFadeWidth(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      ScreenSize.mobile => 44,
      ScreenSize.tablet => 60,
      ScreenSize.desktop => 76,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fadeWidth = edgeWidth ?? edgeFadeWidth(context);

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            final fadeStop = (fadeWidth / bounds.width).clamp(0.045, 0.14);
            final softStop = fadeStop * 0.42;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0.0,
                softStop,
                fadeStop,
                1.0 - fadeStop,
                1.0 - softStop,
                1.0,
              ],
              colors: const [
                Colors.transparent,
                Color(0x40FFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x40FFFFFF),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: child,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: _AmbientEdgeTint(width: fadeWidth, isLeft: true),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: _AmbientEdgeTint(width: fadeWidth, isLeft: false),
        ),
      ],
    );
  }
}

class _AmbientEdgeTint extends StatelessWidget {
  const _AmbientEdgeTint({
    required this.width,
    required this.isLeft,
  });

  final double width;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width * 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              stops: const [0.0, 0.45, 1.0],
              colors: [
                AppColors.primaryPurple.withValues(alpha: 0.11),
                AppColors.primaryPink.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
