import 'package:vex_engines/experience/application/experience_admin_content_service.dart';
import 'package:vex_engines/experience/domain/experience_admin_content_summary.dart';

import '../models/admin_venue_crm.dart';

/// Admin adapter facade for Experience Engine content summaries.
final class AdminVenueContentSupport {
  AdminVenueContentSupport._();

  static const _engine = ExperienceAdminContentService();

  static AdminVenueContentSummary mapSummary(
    ExperienceAdminContentSummary summary,
  ) {
    return AdminVenueContentSummary(
      drinksCount: summary.drinksCount,
      dealsCount: summary.dealsCount,
      eventsCount: summary.eventsCount,
      liveDealsCount: summary.liveDealsCount,
      upcomingEventsCount: summary.upcomingEventsCount,
      galleryImagesCount: summary.galleryImagesCount,
      lastContentUpdate: summary.lastContentUpdate,
      unavailable: summary.unavailable,
    );
  }

  static ExperienceAdminContentSummary buildSummary({
    required int? drinksCount,
    required int? dealsCount,
    required int? eventsCount,
    required int? liveDealsCount,
    required int? upcomingEventsCount,
    int? galleryImagesCount,
    String? lastContentUpdate,
    bool unavailable = false,
  }) =>
      _engine.buildSummary(
        drinksCount: drinksCount,
        dealsCount: dealsCount,
        eventsCount: eventsCount,
        liveDealsCount: liveDealsCount,
        upcomingEventsCount: upcomingEventsCount,
        galleryImagesCount: galleryImagesCount,
        lastContentUpdate: lastContentUpdate,
        unavailable: unavailable,
      );

  static int countUpcomingEvents({
    required Iterable<DateTime?> startDateTimes,
    required DateTime now,
  }) =>
      _engine.countUpcomingEvents(
        startDateTimes: startDateTimes,
        now: now,
      );
}
