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
    this.showLeftEdge = true,
    this.showRightEdge = true,
    this.surfaceTintColor,
  });

  final Widget child;

  /// Optional override for fade zone width in logical pixels.
  final double? edgeWidth;

  /// When false, the left edge stays fully visible (carousel at start).
  final bool showLeftEdge;

  /// When false, the right edge stays fully visible (carousel at end).
  final bool showRightEdge;

  /// Optional ambient tint blended into edge fades (defaults to purple/pink).
  final Color? surfaceTintColor;

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
    const opaque = Color(0xFFFFFFFF);
    const softOpaque = Color(0xFFFFFFFF);
    const softFade = Color(0x40FFFFFF);

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
              colors: [
                showLeftEdge ? Colors.transparent : opaque,
                showLeftEdge ? softFade : softOpaque,
                opaque,
                opaque,
                showRightEdge ? softFade : softOpaque,
                showRightEdge ? Colors.transparent : opaque,
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
          child: _AmbientEdgeTint(
            key: const Key('carousel-edge-fade-left'),
            width: fadeWidth,
            isLeft: true,
            visible: showLeftEdge,
            surfaceTintColor: surfaceTintColor,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: _AmbientEdgeTint(
            key: const Key('carousel-edge-fade-right'),
            width: fadeWidth,
            isLeft: false,
            visible: showRightEdge,
            surfaceTintColor: surfaceTintColor,
          ),
        ),
      ],
    );
  }
}

class _AmbientEdgeTint extends StatelessWidget {
  const _AmbientEdgeTint({
    super.key,
    required this.width,
    required this.isLeft,
    required this.visible,
    this.surfaceTintColor,
  });

  final double width;
  final bool isLeft;
  final bool visible;
  final Color? surfaceTintColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: SizedBox(
          width: width * 0.7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                stops: const [0.0, 0.45, 1.0],
                colors: surfaceTintColor == null
                    ? [
                        AppColors.primaryPurple.withValues(alpha: 0.11),
                        AppColors.primaryPink.withValues(alpha: 0.04),
                        Colors.transparent,
                      ]
                    : [
                        surfaceTintColor!.withValues(alpha: 0.92),
                        surfaceTintColor!.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
