import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum ScreenSize { mobile, tablet, desktop }

class Breakpoints {
  Breakpoints._();

  static const double tablet = 768;
  static const double desktop = 1024;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) => of(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) => of(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) => of(context) == ScreenSize.desktop;

  static double horizontalPadding(BuildContext context) {
    return switch (of(context)) {
      ScreenSize.desktop => AppSpacing.screenPaddingDesktop,
      ScreenSize.tablet => AppSpacing.screenPaddingTablet,
      ScreenSize.mobile => AppSpacing.screenPaddingMobile,
    };
  }

  /// Display height for the Vexda logo in the navigation bar.
  static double logoHeight(BuildContext context) {
    return switch (of(context)) {
      ScreenSize.desktop => 60,
      ScreenSize.tablet => 52,
      ScreenSize.mobile => 44,
    };
  }

  /// Approximate vertical space reserved below the safe area for the fixed nav.
  static double reservedNavHeight(BuildContext context) {
    final logo = logoHeight(context);
    return logo +
        (AppSpacing.navBarInnerPadding * 2) +
        (AppSpacing.navBarOuterPadding * 2);
  }
}
