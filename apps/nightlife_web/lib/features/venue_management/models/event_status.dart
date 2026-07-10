import '../../venue/data/models/event_model.dart';

enum EventStatus {
  draft,
  upcoming,
  live,
  ended,
}

extension EventStatusX on EventStatus {
  String get label => switch (this) {
        EventStatus.draft => 'Draft',
        EventStatus.upcoming => 'Upcoming',
        EventStatus.live => 'Live',
        EventStatus.ended => 'Ended',
      };
}

/// Derives management status for an event row badge.
EventStatus computeEventStatus(EventModel event, {DateTime? now}) {
  final clock = now ?? DateTime.now();

  if (!event.isActive) return EventStatus.draft;
  if (!event.endDateTime.isAfter(clock)) return EventStatus.ended;
  if (event.startDateTime.isAfter(clock)) return EventStatus.upcoming;

  return EventStatus.live;
}
