import 'trail.dart';
import 'trail_availability.dart';

/// Pure availability assessment extracted from mobile time-window rules.
abstract final class TrailAvailabilityPolicy {
  static TrailAvailabilityDecision evaluate({
    required Trail trail,
    required DateTime now,
  }) {
    if (trail.availabilityEnd.isBefore(trail.availabilityStart)) {
      return TrailAvailabilityDecision(
        state: TrailAvailabilityState.invalidConfiguration,
        reasonCode: 'invalidAvailability',
        reasonMessage:
            'availabilityEnd before availabilityStart '
            '(${trail.availabilityStart} -> ${trail.availabilityEnd})',
      );
    }

    if (now.isAfter(trail.availabilityEnd)) {
      return TrailAvailabilityDecision(
        state: TrailAvailabilityState.ended,
        reasonCode: 'ended',
        reasonMessage:
            'availabilityEnd in the past (now=$now, end=${trail.availabilityEnd})',
        availableUntil: trail.availabilityEnd,
      );
    }

    if (now.isBefore(trail.availabilityStart)) {
      if (_isSameLocalDay(now, trail.availabilityStart)) {
        return TrailAvailabilityDecision(
          state: TrailAvailabilityState.availableNow,
          reasonCode: 'sameDayBeforeStart',
          reasonMessage: 'before availabilityStart on same local day',
          availableFrom: trail.availabilityStart,
          availableUntil: trail.availabilityEnd,
        );
      }
      return TrailAvailabilityDecision(
        state: TrailAvailabilityState.upcoming,
        reasonCode: 'upcoming',
        reasonMessage:
            'before availabilityStart on a different day '
            '(now=$now, start=${trail.availabilityStart})',
        availableFrom: trail.availabilityStart,
        availableUntil: trail.availabilityEnd,
      );
    }

    return TrailAvailabilityDecision(
      state: TrailAvailabilityState.availableNow,
      reasonCode: 'availableNow',
      availableFrom: trail.availabilityStart,
      availableUntil: trail.availabilityEnd,
    );
  }

  static bool _isSameLocalDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
