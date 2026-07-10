import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Reusable full-viewport background driven by a single asset path.
///
/// Place behind scroll content via [Positioned.fill] so artwork covers the
/// entire browser width on ultra-wide displays while preserving aspect ratio.
class VexdaBackground extends StatelessWidget {
  const VexdaBackground({
    super.key,
    required this.image,
    this.opacity = 1.0,
    this.overlayGradient,
    this.solidOverlay,
    this.blurAmount = 0,
    this.vignette = true,
    this.vignetteIntensity = 1.0,
    this.showGlowOverlays = false,
    this.glowIntensity = 1.0,
    this.imageLift = 0,
    this.brightness = 1.0,
    this.contrast = 1.0,
  });

  final String image;
  final double opacity;
  final Gradient? overlayGradient;
  final Color? solidOverlay;
  final double blurAmount;
  final bool vignette;
  final double vignetteIntensity;
  final bool showGlowOverlays;
  final double glowIntensity;
  final double imageLift;
  /// Uniform RGB scale — 0.6 ≈ 40% brightness reduction, hues preserved.
  final double brightness;
  /// Luminance spread — 0.8 ≈ 20% contrast reduction, no desaturation.
  final double contrast;

  static Gradient get defaultReadabilityOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.38),
          Colors.black.withValues(alpha: 0.48),
          Colors.black.withValues(alpha: 0.58),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  /// Lighter overlay tuned for the homepage artwork (~30% more visible).
  static Gradient get homeReadabilityOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.24),
          Colors.black.withValues(alpha: 0.32),
          Colors.black.withValues(alpha: 0.40),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned.fill(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: _buildImageLayer(),
          ),
        ),
        if (showGlowOverlays)
          _VexdaGlowOverlays(
            size: size,
            intensity: glowIntensity,
          ),
        Positioned.fill(
          child: solidOverlay != null
              ? ColoredBox(color: solidOverlay!)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: overlayGradient ?? defaultReadabilityOverlay,
                  ),
                ),
        ),
        if (vignette)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(
                      alpha: 0.08 * vignetteIntensity,
                    ),
                    AppColors.background.withValues(
                      alpha: 0.22 * vignetteIntensity,
                    ),
                  ],
                  stops: const [0.55, 0.82, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageLayer() {
    final image = Image(
      image: AssetImage(this.image),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: AppColors.background),
    );

    Widget layer = image;

    layer = _applyToneAdjustments(layer);

    if (imageLift != 0) {
      final lift = imageLift.clamp(-1.0, 1.0);
      if (lift > 0) {
        final scale = 1 + (lift * 0.18);
        final offset = lift * 22;
        layer = ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            scale, 0, 0, 0, offset,
            0, scale, 0, 0, offset,
            0, 0, scale, 0, offset,
            0, 0, 0, 1, 0,
          ]),
          child: layer,
        );
      } else {
        final dim = -lift;
        final scale = 1 - (dim * 0.12);
        final offset = -(dim * 14);
        layer = ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            scale, 0, 0, 0, offset,
            0, scale, 0, 0, offset,
            0, 0, scale, 0, offset,
            0, 0, 0, 1, 0,
          ]),
          child: layer,
        );
      }
    }

    if (blurAmount <= 0) {
      return layer;
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
      ),
      child: layer,
    );
  }

  Widget _applyToneAdjustments(Widget layer) {
    var result = layer;

    final b = brightness.clamp(0.0, 1.0);
    if (b != 1.0) {
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          b, 0, 0, 0, 0,
          0, b, 0, 0, 0,
          0, 0, b, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: result,
      );
    }

    final c = contrast.clamp(0.0, 2.0);
    if (c != 1.0) {
      final translate = 127.5 * (1 - c);
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          c, 0, 0, 0, translate,
          0, c, 0, 0, translate,
          0, 0, c, 0, translate,
          0, 0, 0, 1, 0,
        ]),
        child: result,
      );
    }

    return result;
  }
}

class _VexdaGlowOverlays extends StatelessWidget {
  const _VexdaGlowOverlays({
    required this.size,
    this.intensity = 1.0,
  });

  final Size size;
  final double intensity;

  double _glow(double base) => (base * intensity).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final width = size.width;
    final height = size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.14, 0.50, 0.86, 1.0],
                colors: [
                  AppColors.primaryPurple.withValues(alpha: _glow(0.16)),
                  AppColors.deepPurple.withValues(alpha: _glow(0.04)),
                  Colors.transparent,
                  AppColors.primaryPink.withValues(alpha: _glow(0.05)),
                  AppColors.primaryPurple.withValues(alpha: _glow(0.14)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -height * 0.12,
          left: width * 0.5 - width * 0.28,
          child: _GlowOrb(
            size: width * 0.56,
            color: AppColors.primaryPink,
            opacity: _glow(0.18),
          ),
        ),
        Positioned(
          top: height * 0.08,
          right: -width * 0.12,
          child: _GlowOrb(
            size: width * 0.42,
            color: AppColors.primaryPurple,
            opacity: _glow(0.14),
          ),
        ),
        Positioned(
          top: height * 0.42,
          left: -width * 0.14,
          child: _GlowOrb(
            size: width * 0.38,
            color: AppColors.trailGold,
            opacity: _glow(0.07),
          ),
        ),
        Positioned(
          top: height * 0.62,
          right: -width * 0.10,
          child: _GlowOrb(
            size: width * 0.34,
            color: AppColors.primaryPink,
            opacity: _glow(0.10),
          ),
        ),
        Positioned(
          bottom: -height * 0.08,
          left: width * 0.25,
          child: _GlowOrb(
            size: width * 0.50,
            color: AppColors.primaryPurple,
            opacity: _glow(0.11),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Global background preset — single asset, subtle readability overlay.
class VexdaGlobalBackground extends StatelessWidget {
  const VexdaGlobalBackground({super.key});

  static const _overlayOpacity = 0.12;

  @override
  Widget build(BuildContext context) {
    return VexdaBackground(
      image: AppAssets.globalBackground,
      solidOverlay: Colors.black.withValues(alpha: _overlayOpacity),
      vignette: false,
      showGlowOverlays: false,
    );
  }
}

/// Standard application canvas — solid Vexda dark, no artwork.
class VexdaAppBackground extends StatelessWidget {
  const VexdaAppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.background);
  }
}

/// Legacy homepage preset — prefer [HomePageBackground] on [HomeScreen].
class VexdaHomeBackground extends StatelessWidget {
  const VexdaHomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return VexdaBackground(
      image: AppAssets.homeBackground,
      showGlowOverlays: true,
      overlayGradient: VexdaBackground.homeReadabilityOverlay,
      imageLift: 0.30,
      glowIntensity: 1.32,
      vignetteIntensity: 0.55,
    );
  }
}
