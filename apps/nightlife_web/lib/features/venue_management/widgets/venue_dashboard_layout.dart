import '../../../core/theme/app_spacing.dart';

/// Layout constants for the venue management dashboard shell.
class VenueDashboardLayout {
  VenueDashboardLayout._();

  static const double topBarHeight = 90;
  static const double headerLogoHeightMobile = 72;
  static const double headerLogoHeightDesktop = 83;
  static const double sidebarExpandedWidth = 288;
  static const double sidebarCollapsedWidth = 76;
  static const double sidebarToggleSize = 40;
  static const Duration sidebarTransitionDuration = Duration(milliseconds: 280);
  static const double venueAvatarSize = 44;
  static const double navItemHeight = 46;
  static const double contentMaxWidth = 1280;
  static const double rightColumnWidth = 320;
  static const double insightsSectionMinHeight = 380;
  static const int insightsGraphFlex = 65;
  static const int insightsCompletionFlex = 35;

  /// Collapsed venue header: top padding + avatar + bottom padding.
  static const double sidebarHeaderCollapsedHeight =
      AppSpacing.lg + venueAvatarSize + AppSpacing.md;

  /// Expanded venue header: avatar row + profile link + padding.
  static const double sidebarHeaderExpandedHeight =
      AppSpacing.lg +
      venueAvatarSize +
      AppSpacing.md +
      sidebarProfileLinkLineHeight +
      AppSpacing.md;

  /// Matches [_ViewPublicProfileLink] text line height (13.5pt + underline).
  static const double sidebarProfileLinkLineHeight = 19.5;

  /// OVERVIEW section label block height in grouped nav (padding + label + gap).
  static const double sidebarOverviewSectionBlockHeight =
      AppSpacing.sm +
      sidebarSectionLabelTextHeight +
      AppSpacing.xs +
      AppSpacing.xs;

  /// Matches [_SidebarSectionLabel] text line height (10.5pt bold).
  static const double sidebarSectionLabelTextHeight = 13.5;

  /// Top offset aligning the edge toggle centre with the Dashboard nav item.
  static double sidebarToggleTopOffset({required bool expanded}) {
    const toggleHalf = sidebarToggleSize / 2;
    const listPaddingTop = AppSpacing.md;
    const navCentre = navItemHeight / 2;

    final headerHeight =
        expanded ? sidebarHeaderExpandedHeight : sidebarHeaderCollapsedHeight;

    if (expanded) {
      return headerHeight +
          listPaddingTop +
          sidebarOverviewSectionBlockHeight +
          navCentre -
          toggleHalf;
    }

    return headerHeight + listPaddingTop + navCentre - toggleHalf;
  }
}
