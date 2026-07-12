/// Admin CRM venue content summary — counts supplied by infrastructure adapters.
final class ExperienceAdminContentSummary {
  const ExperienceAdminContentSummary({
    this.drinksCount,
    this.dealsCount,
    this.eventsCount,
    this.liveDealsCount,
    this.upcomingEventsCount,
    this.galleryImagesCount,
    this.lastContentUpdate,
    this.unavailable = false,
  });

  final int? drinksCount;
  final int? dealsCount;
  final int? eventsCount;
  final int? liveDealsCount;
  final int? upcomingEventsCount;
  final int? galleryImagesCount;
  final String? lastContentUpdate;
  final bool unavailable;
}
