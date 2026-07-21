import '../shared/trail_geo.dart';
import 'trail.dart';
import 'trail_progress.dart';
import 'trail_result.dart';
import 'trail_stop.dart';
import 'trail_stop_state.dart';
import 'trail_transition_plan.dart';
import 'trail_progress_state_policy.dart';
import 'trail_visibility_policy.dart';

/// Geofence and stop eligibility matching mobile `validateStopCheckIn` semantics.
///
/// Location permission and device service checks remain in the app layer.
abstract final class TrailCheckInPolicy {
  static const defaultPresenceRadiusMeters = 75.0;

  static TrailCheckInAssessment assess({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
    required DateTime now,
    double? userLatitude,
    double? userLongitude,
    double? venueLatitude,
    double? venueLongitude,
    double? presenceRadiusMeters,
  }) {
    if (progress.completed) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.trailAlreadyCompleted,
        reasonMessage: 'Trail already completed.',
      );
    }

    if (!TrailProgressStatePolicy.belongsToTrail(
      progress: progress,
      trail: trail,
    )) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.staleProgress,
        reasonMessage: 'Progress does not belong to current trail generation.',
      );
    }

    if (!TrailVisibilityPolicy.isVisible(trail: trail, now: now)) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.notAvailable,
        reasonMessage: 'Trail is not currently visible.',
      );
    }

    final state = progress.stopStates[stop.order];
    if (state == TrailStopState.skipped) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.alreadySkipped,
        reasonMessage: 'Stop already skipped.',
      );
    }

    if (progress.checkedInStopOrders.contains(stop.order) ||
        state == TrailStopState.checkedIn) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.alreadyCheckedIn,
        reasonMessage: 'Stop already checked in.',
      );
    }

    if (progress.started && stopIndex < progress.currentStopIndex) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.checkInBlocked,
        reasonMessage: 'Check-in blocked for earlier stop index.',
      );
    }

    if (venueLatitude == null || venueLongitude == null) {
      return const TrailCheckInAssessment.allowed();
    }

    if (userLatitude == null || userLongitude == null) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.locationUnavailable,
        reasonMessage: 'User location unavailable.',
      );
    }

    final radius = presenceRadiusMeters ?? defaultPresenceRadiusMeters;
    if (radius <= 0) {
      return const TrailCheckInAssessment(
        eligible: false,
        reasonCode: TrailFailureCodes.invalidPresenceRadius,
        reasonMessage: 'Invalid presence radius.',
      );
    }

    final distanceMeters = TrailGeo.distanceMeters(
      lat1: userLatitude,
      lng1: userLongitude,
      lat2: venueLatitude,
      lng2: venueLongitude,
    );

    if (distanceMeters <= radius) {
      return TrailCheckInAssessment.allowed(distanceMeters: distanceMeters);
    }

    return TrailCheckInAssessment(
      eligible: false,
      reasonCode: TrailFailureCodes.tooFarAway,
      reasonMessage:
          'User is ${distanceMeters.toStringAsFixed(0)}m away; radius is ${radius.toStringAsFixed(0)}m.',
      distanceMeters: distanceMeters,
    );
  }

  static bool continueAllowed({
    required TrailProgress progress,
    required TrailStop stop,
  }) {
    return progress.started &&
        !progress.completed &&
        progress.stopStates[stop.order] == TrailStopState.checkedIn;
  }

  static bool skipAllowed({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
  }) {
    if (!progress.started || progress.completed) return false;
    if (stopIndex < progress.currentStopIndex) return false;
    final state = progress.stopStates[stop.order];
    if (state == TrailStopState.checkedIn ||
        state == TrailStopState.skipped ||
        progress.checkedInStopOrders.contains(stop.order)) {
      return false;
    }
    return true;
  }
}
