import 'package:vex_engines/experience/application/experience_content_orchestrator.dart';

import 'models/deal_model.dart';
import 'models/event_model.dart';

const _orchestrator = ExperienceContentOrchestrator();

/// Whether a deal should appear under Current Deals on the public venue page.
bool isPublicCurrentDeal(DealModel deal, {DateTime? now}) =>
    _orchestrator
        .filterPublicCurrentDeals(
          [deal],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          effectiveEndDateTime: (item) => item.effectiveEndDateTime,
          now: now,
        )
        .isNotEmpty;

/// Whether a deal should appear under Upcoming Deals on the public venue page.
bool isPublicUpcomingDeal(DealModel deal, {DateTime? now}) =>
    _orchestrator
        .filterPublicUpcomingDeals(
          [deal],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          effectiveEndDateTime: (item) => item.effectiveEndDateTime,
          now: now,
        )
        .isNotEmpty;

/// Whether an event should appear under Current Events on the public venue page.
bool isPublicCurrentEvent(EventModel event, {DateTime? now}) =>
    _orchestrator
        .filterPublicCurrentEvents(
          [event],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          now: now,
        )
        .isNotEmpty;

/// Whether an event should appear under Upcoming Events on the public venue page.
bool isPublicUpcomingEvent(EventModel event, {DateTime? now}) =>
    _orchestrator
        .filterPublicUpcomingEvents(
          [event],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          now: now,
        )
        .isNotEmpty;

/// Whether a deal/event is visible to customers at all on the public venue page.
bool isPublicVisibleDeal(DealModel deal, {DateTime? now}) =>
    _orchestrator
        .filterPublicVisibleDeals(
          [deal],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          effectiveEndDateTime: (item) => item.effectiveEndDateTime,
          now: now,
        )
        .isNotEmpty;

bool isPublicVisibleEvent(EventModel event, {DateTime? now}) =>
    _orchestrator
        .filterPublicVisibleEvents(
          [event],
          isDeleted: (item) => item.isDeleted,
          isActive: (item) => item.isActive,
          startDateTime: (item) => item.startDateTime,
          endDateTime: (item) => item.endDateTime,
          now: now,
        )
        .isNotEmpty;
