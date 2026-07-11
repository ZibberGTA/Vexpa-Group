/// Legacy VexCore event visibility helpers.
///
/// Canonical rules live in `ExperienceEventVisibility` inside the Experience Engine.
/// Public web reads filter through Experience Engine at the repository boundary.
library;

import 'venue_event.dart';

/// Whether an event should appear under Current Events on the public venue page.
bool isPublicCurrentVenueEvent(VenueEvent event, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (event.isDeleted || !event.isActive) return false;
  if (!event.endDateTime.isAfter(clock)) return false;
  if (event.startDateTime.isAfter(clock)) return false;

  return true;
}

/// Whether an event should appear under Upcoming Events on the public venue page.
bool isPublicUpcomingVenueEvent(VenueEvent event, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (event.isDeleted || !event.isActive) return false;
  if (!event.endDateTime.isAfter(clock)) return false;

  return event.startDateTime.isAfter(clock);
}

/// Whether an event is visible to customers at all on the public venue page.
bool isPublicVisibleVenueEvent(VenueEvent event, {DateTime? now}) =>
    isPublicCurrentVenueEvent(event, now: now) ||
    isPublicUpcomingVenueEvent(event, now: now);
