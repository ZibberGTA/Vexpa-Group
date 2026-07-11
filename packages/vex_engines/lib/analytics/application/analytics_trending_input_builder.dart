/// Trending score inputs derived from venue analytics metrics.
final class AnalyticsTrendingInput {
  const AnalyticsTrendingInput({
    required this.venueViews,
    required this.favouriteTaps,
    required this.drinkViews,
    required this.dealViews,
    required this.eventViews,
    this.boostScore = 0,
    this.isOpen = false,
    this.distanceKm = 0,
  });

  final int venueViews;
  final int favouriteTaps;
  final int drinkViews;
  final int dealViews;
  final int eventViews;
  final int boostScore;
  final bool isOpen;
  final double distanceKm;
}

/// Maps venue metrics to discovery trending inputs.
final class AnalyticsTrendingInputBuilder {
  const AnalyticsTrendingInputBuilder();

  AnalyticsTrendingInput build({
    required int venueViews,
    required int favouriteTaps,
    required int drinkViews,
    required int dealViews,
    required int eventViews,
    int boostScore = 0,
    bool isOpen = false,
    double distanceKm = 0,
  }) {
    return AnalyticsTrendingInput(
      venueViews: venueViews.clamp(0, 1000000),
      favouriteTaps: favouriteTaps.clamp(0, 1000000),
      drinkViews: drinkViews.clamp(0, 1000000),
      dealViews: dealViews.clamp(0, 1000000),
      eventViews: eventViews.clamp(0, 1000000),
      boostScore: boostScore,
      isOpen: isOpen,
      distanceKm: distanceKm,
    );
  }
}
