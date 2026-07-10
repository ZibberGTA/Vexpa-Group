/// Provider-independent public deal visibility rules.

import 'venue_deal.dart';

/// Whether a deal should appear under Current Deals on the public venue page.
bool isPublicCurrentVenueDeal(VenueDeal deal, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (deal.isDeleted || !deal.isActive) return false;

  final start = deal.startDateTime;
  final end = deal.endDateTime ?? deal.effectiveEndDateTime;
  if (end != null && !end.isAfter(clock)) return false;
  if (start != null && start.isAfter(clock)) return false;

  return true;
}

/// Whether a deal should appear under Upcoming Deals on the public venue page.
bool isPublicUpcomingVenueDeal(VenueDeal deal, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (deal.isDeleted || !deal.isActive) return false;

  final start = deal.startDateTime;
  if (start == null || !start.isAfter(clock)) return false;

  final end = deal.endDateTime ?? deal.effectiveEndDateTime;
  if (end != null && !end.isAfter(clock)) return false;

  return true;
}

/// Whether a deal is visible to customers at all on the public venue page.
bool isPublicVisibleVenueDeal(VenueDeal deal, {DateTime? now}) =>
    isPublicCurrentVenueDeal(deal, now: now) ||
    isPublicUpcomingVenueDeal(deal, now: now);
