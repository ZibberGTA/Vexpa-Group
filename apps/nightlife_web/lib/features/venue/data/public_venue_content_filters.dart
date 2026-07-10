import 'models/deal_model.dart';
import 'models/event_model.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

/// Whether a deal should appear under Current Deals on the public venue page.
bool isPublicCurrentDeal(DealModel deal, {DateTime? now}) =>
    ExperienceDealVisibility.isPublicCurrent(
      isDeleted: deal.isDeleted,
      isActive: deal.isActive,
      startDateTime: deal.startDateTime,
      endDateTime: deal.endDateTime,
      effectiveEndDateTime: deal.effectiveEndDateTime,
      now: now,
    );

/// Whether a deal should appear under Upcoming Deals on the public venue page.
bool isPublicUpcomingDeal(DealModel deal, {DateTime? now}) =>
    ExperienceDealVisibility.isPublicUpcoming(
      isDeleted: deal.isDeleted,
      isActive: deal.isActive,
      startDateTime: deal.startDateTime,
      endDateTime: deal.endDateTime,
      effectiveEndDateTime: deal.effectiveEndDateTime,
      now: now,
    );

/// Whether an event should appear under Current Events on the public venue page.
bool isPublicCurrentEvent(EventModel event, {DateTime? now}) =>
    ExperienceEventVisibility.isPublicCurrent(
      isDeleted: event.isDeleted,
      isActive: event.isActive,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      now: now,
    );

/// Whether an event should appear under Upcoming Events on the public venue page.
bool isPublicUpcomingEvent(EventModel event, {DateTime? now}) =>
    ExperienceEventVisibility.isPublicUpcoming(
      isDeleted: event.isDeleted,
      isActive: event.isActive,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      now: now,
    );

/// Whether a deal/event is visible to customers at all on the public venue page.
bool isPublicVisibleDeal(DealModel deal, {DateTime? now}) =>
    ExperienceDealVisibility.isPublicVisible(
      isDeleted: deal.isDeleted,
      isActive: deal.isActive,
      startDateTime: deal.startDateTime,
      endDateTime: deal.endDateTime,
      effectiveEndDateTime: deal.effectiveEndDateTime,
      now: now,
    );

bool isPublicVisibleEvent(EventModel event, {DateTime? now}) =>
    ExperienceEventVisibility.isPublicVisible(
      isDeleted: event.isDeleted,
      isActive: event.isActive,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      now: now,
    );
