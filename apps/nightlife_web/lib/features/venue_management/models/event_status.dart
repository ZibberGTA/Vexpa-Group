import 'package:vex_engines/experience/application/experience_event_status.dart';

import '../../venue/data/models/event_model.dart';

typedef EventStatus = ExperienceEventManagementStatus;

extension EventStatusX on EventStatus {
  String get label => switch (this) {
        EventStatus.draft => 'Draft',
        EventStatus.upcoming => 'Upcoming',
        EventStatus.live => 'Live',
        EventStatus.ended => 'Ended',
      };
}

/// Derives management status for an event row badge.
EventStatus computeEventStatus(EventModel event, {DateTime? now}) =>
    ExperienceEventStatusRules.compute(
      isActive: event.isActive,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      now: now,
    );
