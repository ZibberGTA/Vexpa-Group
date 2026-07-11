import '../domain/venue_dashboard_models.dart';

/// Applies venue-specific labels and icons to aggregated activity entries.
final class VenueActivityInterpreter {
  const VenueActivityInterpreter();

  VenueActivityItem? interpret(VenueActivitySourceEntry entry) {
    if (entry.source == 'content_event') {
      final title = entry.contentTitle?.trim();
      if (title == null || title.isEmpty) return null;
      return VenueActivityItem(
        title: 'Event added: $title',
        timestampLabel: entry.timestampLabel,
        iconKey: 'event_outlined',
      );
    }

    final mapped = switch (entry.eventType) {
      'drink_view' => (
          'Drink viewed: ${entry.payload['drinkName'] ?? 'Menu item'}',
          'local_bar_outlined',
        ),
      'deal_view' => (
          'Deal viewed: ${entry.payload['dealTitle'] ?? 'Promotion'}',
          'local_offer_outlined',
        ),
      'event_view' => (
          'Event viewed: ${entry.payload['eventTitle'] ?? 'Event'}',
          'event_outlined',
        ),
      'favourite_tap' => (
          'Venue saved by a customer',
          'bookmark_outline_rounded',
        ),
      'crowd_update' => ('Crowd level updated', 'groups_outlined'),
      _ => null,
    };

    if (mapped == null) return null;

    return VenueActivityItem(
      title: mapped.$1,
      timestampLabel: entry.timestampLabel,
      iconKey: mapped.$2,
    );
  }
}
