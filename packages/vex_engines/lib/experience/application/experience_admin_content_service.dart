import '../domain/experience_admin_content_summary.dart';

/// Admin CRM content count interpretation and summary assembly.
final class ExperienceAdminContentService {
  const ExperienceAdminContentService();

  ExperienceAdminContentSummary buildSummary({
    required int? drinksCount,
    required int? dealsCount,
    required int? eventsCount,
    required int? liveDealsCount,
    required int? upcomingEventsCount,
    int? galleryImagesCount,
    String? lastContentUpdate,
    bool unavailable = false,
  }) {
    return ExperienceAdminContentSummary(
      drinksCount: drinksCount,
      dealsCount: dealsCount,
      eventsCount: eventsCount,
      liveDealsCount: liveDealsCount,
      upcomingEventsCount: upcomingEventsCount,
      galleryImagesCount: galleryImagesCount,
      lastContentUpdate: lastContentUpdate,
      unavailable: unavailable,
    );
  }

  /// Counts upcoming events using admin CRM semantics.
  ///
  /// When [startDateTime] is null the event is treated as upcoming (legacy
  /// admin behaviour when Firestore start fields are missing or unparseable).
  int countUpcomingEvents({
    required Iterable<DateTime?> startDateTimes,
    required DateTime now,
  }) {
    return startDateTimes.where((start) {
      if (start == null) return true;
      return start.isAfter(now);
    }).length;
  }

  bool hasDrinks(int? drinksCount) => (drinksCount ?? 0) > 0;

  bool hasDeals(int? dealsCount) => (dealsCount ?? 0) > 0;

  bool hasEvents(int? eventsCount) => (eventsCount ?? 0) > 0;
}
