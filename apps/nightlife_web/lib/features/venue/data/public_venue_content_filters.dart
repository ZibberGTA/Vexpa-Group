import 'models/deal_model.dart';
import 'models/event_model.dart';

/// Whether a deal should appear under Current Deals on the public venue page.
bool isPublicCurrentDeal(DealModel deal, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (deal.isDeleted || !deal.isActive) return false;

  final start = deal.startDateTime;
  final end = deal.endDateTime ?? deal.effectiveEndDateTime;
  if (end != null && !end.isAfter(clock)) return false;
  if (start != null && start.isAfter(clock)) return false;

  return true;
}

/// Whether a deal should appear under Upcoming Deals on the public venue page.
bool isPublicUpcomingDeal(DealModel deal, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (deal.isDeleted || !deal.isActive) return false;

  final start = deal.startDateTime;
  if (start == null || !start.isAfter(clock)) return false;

  final end = deal.endDateTime ?? deal.effectiveEndDateTime;
  if (end != null && !end.isAfter(clock)) return false;

  return true;
}

/// Whether an event should appear under Current Events on the public venue page.
bool isPublicCurrentEvent(EventModel event, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (event.isDeleted || !event.isActive) return false;
  if (!event.endDateTime.isAfter(clock)) return false;
  if (event.startDateTime.isAfter(clock)) return false;

  return true;
}

/// Whether an event should appear under Upcoming Events on the public venue page.
bool isPublicUpcomingEvent(EventModel event, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (event.isDeleted || !event.isActive) return false;
  if (!event.endDateTime.isAfter(clock)) return false;

  return event.startDateTime.isAfter(clock);
}

/// Whether a deal/event is visible to customers at all on the public venue page.
bool isPublicVisibleDeal(DealModel deal, {DateTime? now}) =>
    isPublicCurrentDeal(deal, now: now) || isPublicUpcomingDeal(deal, now: now);

bool isPublicVisibleEvent(EventModel event, {DateTime? now}) =>
    isPublicCurrentEvent(event, now: now) || isPublicUpcomingEvent(event, now: now);
