import '../domain/trail.dart';
import '../domain/trail_check_in_policy.dart';
import '../domain/trail_progress.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_transition_plan.dart';
import 'ports/trail_clock.dart';
import 'ports/trail_venue_lookup_port.dart';
import 'trail_application_result.dart';
import 'trail_progress_application_service.dart';

/// Venue lookup + geofence assessment wrapper for check-in operations.
final class TrailCheckInApplicationService {
  const TrailCheckInApplicationService({
    required this.venueLookup,
    required this.progressService,
    this.clock,
  });

  final TrailVenueLookupPort venueLookup;
  final TrailProgressApplicationService progressService;
  final TrailClock? clock;

  Future<TrailApplicationResult<TrailCheckInAssessment>> assessEligibility({
    required Trail trail,
    required TrailProgress progress,
    required TrailStop stop,
    required int stopIndex,
    double? userLatitude,
    double? userLongitude,
    DateTime? now,
  }) async {
    final presence = await venueLookup.lookup(stop.venueId);
    if (presence == null) {
      return TrailApplicationSuccess(
        TrailCheckInPolicy.assess(
          trail: trail,
          progress: progress,
          stop: stop,
          stopIndex: stopIndex,
          now: now ?? clock?.now() ?? DateTime.now(),
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        ),
      );
    }

    return TrailApplicationSuccess(
      TrailCheckInPolicy.assess(
        trail: trail,
        progress: progress,
        stop: stop,
        stopIndex: stopIndex,
        now: now ?? clock?.now() ?? DateTime.now(),
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        venueLatitude: presence.latitude,
        venueLongitude: presence.longitude,
        presenceRadiusMeters: presence.presenceRadiusMeters,
      ),
    );
  }

  Future<TrailApplicationResult<TrailProgress>> checkInAtStop({
    required Trail trail,
    required TrailStop stop,
    required int stopIndex,
    required TrailProgress progress,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final presence = await venueLookup.lookup(stop.venueId);
    return progressService.checkIn(
      trail: trail,
      stop: stop,
      stopIndex: stopIndex,
      progress: progress,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      venueLatitude: presence?.latitude,
      venueLongitude: presence?.longitude,
      presenceRadiusMeters: presence?.presenceRadiusMeters,
    );
  }
}
