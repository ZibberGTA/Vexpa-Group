import '../../venue/data/models/event_model.dart';

/// Configurable limit for featured events on the public venue profile.
class FeaturedEventsLimit {
  FeaturedEventsLimit._();

  static const int maxFeaturedEvents = 3;

  static const String limitMessage =
      'You can feature up to 3 events. Unfeature another event first.';

  static String? validateEdit({
    required EventModel event,
    required bool wantsFeatured,
    required Iterable<EventModel> venueEvents,
  }) {
    if (!wantsFeatured || event.featured) return null;

    final otherFeatured = venueEvents
        .where((item) => item.featured && item.id != event.id)
        .length;
    if (otherFeatured >= maxFeaturedEvents) return limitMessage;
    return null;
  }

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<EventModel> venueEvents,
  }) {
    if (!wantsFeatured) return null;

    final featuredCount = venueEvents.where((event) => event.featured).length;
    if (featuredCount >= maxFeaturedEvents) return limitMessage;
    return null;
  }
}
