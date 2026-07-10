import '../../venue/data/models/event_model.dart';
import 'package:vex_engines/experience/application/experience_featured_limit.dart';

/// Configurable limit for featured events on the public venue profile.
class FeaturedEventsLimit {
  FeaturedEventsLimit._();

  static const _limit = ExperienceFeaturedLimit.events;

  static int get maxFeaturedEvents => _limit.maxFeatured;

  static String get limitMessage => _limit.limitMessage;

  static String? validateEdit({
    required EventModel event,
    required bool wantsFeatured,
    required Iterable<EventModel> venueEvents,
  }) =>
      _limit.validateEdit(
        item: event,
        currentlyFeatured: event.featured,
        wantsFeatured: wantsFeatured,
        venueItems: venueEvents,
        isFeatured: (item) => item.featured,
        isSameItem: (item) => item.id == event.id,
      );

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<EventModel> venueEvents,
  }) =>
      _limit.validateAdd(
        wantsFeatured: wantsFeatured,
        venueItems: venueEvents,
        isFeatured: (event) => event.featured,
      );
}
