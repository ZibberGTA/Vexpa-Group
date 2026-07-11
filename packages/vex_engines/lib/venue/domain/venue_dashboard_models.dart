/// Semantic dashboard tab keys used by venue orchestration rules.
abstract final class VenueDashboardTabKey {
  static const dashboard = 'dashboard';
  static const analytics = 'analytics';
  static const gallery = 'gallery';
  static const drinks = 'drinks';
  static const deals = 'deals';
  static const events = 'events';
  static const venueProfile = 'venue_profile';
}

/// Venue-specific dashboard highlight before UI mapping.
final class VenueDashboardHighlight {
  const VenueDashboardHighlight({
    required this.message,
    required this.buttonLabel,
    required this.targetTabKey,
    required this.accentKey,
    required this.iconKey,
  });

  final String message;
  final String buttonLabel;
  final String targetTabKey;
  final String accentKey;
  final String iconKey;
}

/// Suggested next step before UI mapping.
final class VenueWhatsNextAction {
  const VenueWhatsNextAction({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.targetTabKey,
    required this.iconKey,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final String targetTabKey;
  final String iconKey;
}

/// Venue dashboard content snapshot inputs.
final class VenueDashboardVenueSnapshot {
  const VenueDashboardVenueSnapshot({
    required this.venueId,
    required this.galleryImageCount,
  });

  final String venueId;
  final int galleryImageCount;

  bool get hasGalleryImages => galleryImageCount > 0;
}

/// Counts and flags used for dashboard guidance rules.
final class VenueDashboardContentCounts {
  const VenueDashboardContentCounts({
    this.drinkCount = 0,
    this.dealCount = 0,
    this.eventCount = 0,
    this.hasUpcomingEvent = false,
  });

  final int drinkCount;
  final int dealCount;
  final int eventCount;
  final bool hasUpcomingEvent;
}

/// Raw activity row before venue-specific interpretation.
final class VenueActivitySourceEntry {
  const VenueActivitySourceEntry({
    required this.occurredAt,
    required this.source,
    required this.timestampLabel,
    this.eventType,
    this.payload = const {},
    this.contentTitle,
  });

  final DateTime occurredAt;
  final String source;
  final String timestampLabel;
  final String? eventType;
  final Map<String, dynamic> payload;
  final String? contentTitle;
}

/// Interpreted venue activity row before UI mapping.
final class VenueActivityItem {
  const VenueActivityItem({
    required this.title,
    required this.timestampLabel,
    required this.iconKey,
  });

  final String title;
  final String timestampLabel;
  final String iconKey;
}
