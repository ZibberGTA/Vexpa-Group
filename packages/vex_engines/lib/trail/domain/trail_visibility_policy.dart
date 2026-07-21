import 'trail.dart';
import 'trail_availability.dart';
import 'trail_status.dart';
import 'trail_visibility.dart';
import 'trail_availability_policy.dart';

/// Pure visibility rules matching mobile `DrinkSpotTrailModel.isVisible`.
abstract final class TrailVisibilityPolicy {
  static TrailVisibilityDecision evaluate({
    required Trail trail,
    required DateTime now,
    TrailVisibilityAudience audience = TrailVisibilityAudience.publicMobile,
  }) {
    if (audience == TrailVisibilityAudience.admin ||
        audience == TrailVisibilityAudience.preview) {
      return const TrailVisibilityDecision.visible();
    }

    if (!_isPublishedLike(trail)) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: 'notPublished',
        reasonMessage:
            'not published (status=${trail.status.name}, published=${trail.published})',
      );
    }

    if (trail.status == TrailStatus.archived ||
        trail.status == TrailStatus.disabled) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: 'archivedOrDisabled',
        reasonMessage: 'status=${trail.status.name}',
      );
    }

    final hasStops = trail.stops.isNotEmpty || trail.venueCount > 0;
    if (!hasStops) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: 'noStops',
        reasonMessage:
            'no stops (stops=${trail.stops.length}, venueCount=${trail.venueCount})',
      );
    }

    final availability = TrailAvailabilityPolicy.evaluate(
      trail: trail,
      now: now,
    );
    if (availability.state == TrailAvailabilityState.invalidConfiguration) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: availability.reasonCode,
        reasonMessage: availability.reasonMessage,
      );
    }

    if (availability.state == TrailAvailabilityState.ended) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: 'ended',
        reasonMessage: availability.reasonMessage,
        expiresAt: availability.availableUntil,
      );
    }

    if (availability.state == TrailAvailabilityState.upcoming) {
      return TrailVisibilityDecision(
        isVisible: false,
        reasonCode: 'upcoming',
        reasonMessage: availability.reasonMessage,
        nextVisibleAt: availability.availableFrom,
      );
    }

    return TrailVisibilityDecision.visible(
      nextVisibleAt: availability.availableFrom,
      expiresAt: availability.availableUntil,
    );
  }

  static bool isVisible({
    required Trail trail,
    required DateTime now,
    TrailVisibilityAudience audience = TrailVisibilityAudience.publicMobile,
  }) {
    return evaluate(trail: trail, now: now, audience: audience).isVisible;
  }

  static bool _isPublishedLike(Trail trail) {
    return trail.status == TrailStatus.published || trail.published;
  }
}
