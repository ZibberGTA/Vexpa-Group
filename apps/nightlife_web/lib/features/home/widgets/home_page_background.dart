import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/vexda_background.dart';
import 'home_layout.dart';

/// Immersive homepage background — owned exclusively by [HomeScreen].
///
/// Restores the original cinematic preset (artwork, glow orbs, gradient overlay,
/// vignette) with content-first refinements: ~40% brightness reduction, slightly
/// lower contrast, and a subtly strengthened dark overlay.
class HomePageBackground extends StatelessWidget {
  const HomePageBackground({super.key});

  /// Original [VexdaBackground.homeReadabilityOverlay] with a slightly
  /// stronger dark tint so the hero content stays in front.
  static Gradient get _refinedOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.34),
          Colors.black.withValues(alpha: 0.42),
          Colors.black.withValues(alpha: 0.50),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  @override
  Widget build(BuildContext context) {
    return VexdaBackground(
      image: AppAssets.homeBackground,
      showGlowOverlays: true,
      overlayGradient: _refinedOverlay,
      imageLift: 0.30,
      glowIntensity: 1.32,
      vignetteIntensity: 0.55,
      brightness: 0.60,
      contrast: 0.88,
    );
  }
}

/// Fixed vertical gap between homepage sections on desktop.
class HomeSectionGap extends StatelessWidget {
  const HomeSectionGap(this.desktopGap, {super.key});

  final double desktopGap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: HomeLayout.sectionGap(context, desktopGap));
  }
}
