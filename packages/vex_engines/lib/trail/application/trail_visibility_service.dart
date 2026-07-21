import '../domain/trail.dart';
import '../domain/trail_availability.dart';
import '../domain/trail_availability_policy.dart';
import '../domain/trail_visibility.dart';
import '../domain/trail_visibility_policy.dart';

/// Visibility and availability assessments for trails.
final class TrailVisibilityService {
  const TrailVisibilityService();

  TrailVisibilityDecision assessVisibility({
    required Trail trail,
    required DateTime now,
    TrailVisibilityAudience audience = TrailVisibilityAudience.publicMobile,
  }) {
    return TrailVisibilityPolicy.evaluate(
      trail: trail,
      now: now,
      audience: audience,
    );
  }

  TrailAvailabilityDecision assessAvailability({
    required Trail trail,
    required DateTime now,
  }) {
    return TrailAvailabilityPolicy.evaluate(trail: trail, now: now);
  }
}
