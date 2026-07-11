/// Legacy VexCore deal visibility helpers.
///
/// Canonical rules live in `ExperienceDealVisibility` inside the Experience Engine.
/// Public web reads filter through Experience Engine at the repository boundary.
library;

import 'venue_deal.dart';

/// Whether a deal should appear under Current Deals on the public venue page.
@Deprecated(
  'Use ExperienceDealVisibility in the Experience Engine. '
  'Do not add new rules here.',
)
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
@Deprecated(
  'Use ExperienceDealVisibility in the Experience Engine. '
  'Do not add new rules here.',
)
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
@Deprecated(
  'Use ExperienceDealVisibility in the Experience Engine. '
  'Do not add new rules here.',
)
bool isPublicVisibleVenueDeal(VenueDeal deal, {DateTime? now}) =>
    isPublicCurrentVenueDeal(deal, now: now) ||
    isPublicUpcomingVenueDeal(deal, now: now);
