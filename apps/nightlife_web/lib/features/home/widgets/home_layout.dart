import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';

/// Desktop-first 12-column grid and vertical rhythm for the homepage.
class HomeLayout {
  HomeLayout._();

  static const int gridColumns = 12;
  static const double gridGutter = 24;
  static const double maxContentWidthDesktop = 1700;

  // Vertical rhythm (desktop)
  static const double gapNavToHero = 24;
  static const double gapHeroToWhy = 24;
  static const double gapWhyHeadingToCards = 24;
  static const double gapCardsToStats = 32;
  static const double gapStatsToDownload = 32;
  static const double gapDownloadToFooter = 40;

  /// Minimum card height for Why Vexda panels (~18% taller than prior implicit height).
  static const double whyPanelMinHeightDesktop = 236;

  static double maxContentWidth(BuildContext context) {
    if (Breakpoints.isMobile(context) || Breakpoints.isTablet(context)) {
      return AppSpacing.maxContentWidth;
    }
    return maxContentWidthDesktop;
  }

  static double horizontalPadding(BuildContext context) {
    if (Breakpoints.isMobile(context)) {
      return AppSpacing.screenPaddingMobile;
    }
    if (Breakpoints.isTablet(context)) {
      return AppSpacing.screenPaddingTablet;
    }

    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth >= 3840) return 64;
    if (viewportWidth >= 2560) return 56;
    return 48;
  }

  /// Usable content width inside the grid container.
  static double contentWidth(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final maxW = maxContentWidth(context);
    final pad = horizontalPadding(context);
    final outer = viewport < maxW + pad * 2 ? viewport : maxW + pad * 2;
    return outer - pad * 2;
  }

  /// Width of a single grid column.
  static double columnWidth(BuildContext context) {
    final width = contentWidth(context);
    return (width - gridGutter * (gridColumns - 1)) / gridColumns;
  }

  /// Width spanning [span] columns including internal gutters.
  static double spanWidth(BuildContext context, int span) {
    assert(span >= 1 && span <= gridColumns);
    return columnWidth(context) * span + gridGutter * (span - 1);
  }

  static EdgeInsets gridPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: horizontalPadding(context));
  }

  static EdgeInsets heroPadding(BuildContext context) {
    if (Breakpoints.isMobile(context)) {
      return const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.xl,
      );
    }
    if (Breakpoints.isTablet(context)) {
      return const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      );
    }
    return const EdgeInsets.only(top: gapNavToHero);
  }

  static double sectionGap(BuildContext context, double desktopGap) {
    if (Breakpoints.isMobile(context) || Breakpoints.isTablet(context)) {
      return AppSpacing.xxxl;
    }
    return desktopGap;
  }

  /// Space below the marketing phrases before the hero container ends.
  static const double heroContentBottomPadding = 50;

  static double heroColumnGap(BuildContext context) {
    if (Breakpoints.isTablet(context)) return AppSpacing.xxl;
    return AppSpacing.xxxl;
  }

  static int heroLeftFlex(BuildContext context) => 9;

  static int heroRightFlex(BuildContext context) => 11;

  /// Gap between the hero debug border and the headline (desktop).
  static const double heroBorderInsetBeforeHeadline = 50;

  /// Space between the hero container right edge and the viewport (desktop).
  static const double heroContentRightMargin = 470;

  /// Horizontal position of hero text — matches [HomeSection] / grid alignment.
  static double heroContentLeft(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final maxW = maxContentWidth(context);
    final pad = horizontalPadding(context);
    final outer = viewport < maxW + pad * 2 ? viewport : maxW + pad * 2;
    return (viewport - outer) / 2 + pad;
  }
}
