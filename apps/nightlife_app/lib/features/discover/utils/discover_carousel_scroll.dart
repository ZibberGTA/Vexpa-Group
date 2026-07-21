import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/discover_models.dart';

/// Pure helpers for synchronising the Discover results carousel with map markers.
class DiscoverCarouselScroll {
  DiscoverCarouselScroll._();

  /// Horizontal gutter shared by the results header, carousel, and footer.
  static const double panelContentPadding = AppSpacing.lg;

  /// Alias retained for existing call sites and tests.
  static const double listPadding = panelContentPadding;

  static const double cardSpacing = 12;

  /// Inner clip radius for the carousel viewport inside the hero-card panel.
  static double get carouselInnerClipRadius =>
      AppDecorations.heroCardBorderRadius - AppSpacing.xs;

  static int? indexForVenueId(
    List<DiscoverVenueResult> results,
    String venueId,
  ) {
    final index = results.indexWhere((result) => result.venueId == venueId);
    return index >= 0 ? index : null;
  }

  static int clampIndex(int index, int resultCount) {
    if (resultCount <= 0) return 0;
    return index.clamp(0, resultCount - 1);
  }

  /// Scroll offset for [index] inside the inset carousel viewport.
  ///
  /// The viewport gutter is applied outside the ListView, so logical offset 0
  /// aligns the first card at the left clip edge; later indices advance by one
  /// card stride without adding the outer inset.
  static double scrollOffsetForIndex({
    required int index,
    required double cardWidth,
    double spacing = cardSpacing,
  }) {
    if (index <= 0) return 0;
    return index * (cardWidth + spacing);
  }

  static double clampScrollOffset({
    required double offset,
    required double maxScrollExtent,
  }) {
    if (maxScrollExtent <= 0) return 0;
    return offset.clamp(0, maxScrollExtent);
  }
}
