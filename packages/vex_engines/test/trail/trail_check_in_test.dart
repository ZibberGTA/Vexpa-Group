import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'trail_test_helpers.dart';

void main() {
  group('TrailCheckInPolicy', () {
    test('allows check-in when venue location missing', () {
      final assessment = TrailCheckInPolicy.assess(
        trail: buildTrail(),
        progress: buildProgress(),
        stop: buildTrail().stops.first,
        stopIndex: 0,
        now: DateTime(2026, 7, 18, 20),
      );
      expect(assessment.eligible, isTrue);
    });

    test('blocks when user too far away', () {
      final assessment = TrailCheckInPolicy.assess(
        trail: buildTrail(),
        progress: buildProgress(),
        stop: buildTrail().stops.first,
        stopIndex: 0,
        now: DateTime(2026, 7, 18, 20),
        userLatitude: 51.5,
        userLongitude: -0.12,
        venueLatitude: 52.0,
        venueLongitude: -0.12,
        presenceRadiusMeters: 75,
      );
      expect(assessment.eligible, isFalse);
      expect(assessment.reasonCode, TrailFailureCodes.tooFarAway);
    });

    test('allows exactly on radius boundary', () {
      final assessment = TrailCheckInPolicy.assess(
        trail: buildTrail(),
        progress: buildProgress(),
        stop: buildTrail().stops.first,
        stopIndex: 0,
        now: DateTime(2026, 7, 18, 20),
        userLatitude: 51.5,
        userLongitude: 0,
        venueLatitude: 51.5,
        venueLongitude: 0,
        presenceRadiusMeters: TrailGeo.distanceMeters(
          lat1: 51.5,
          lng1: 0,
          lat2: 51.5,
          lng2: 0.001,
        ),
      );
      expect(assessment.eligible, isTrue);
    });

    test('rejects completed progress', () {
      final assessment = TrailCheckInPolicy.assess(
        trail: buildTrail(),
        progress: buildProgress(completed: true),
        stop: buildTrail().stops.first,
        stopIndex: 0,
        now: DateTime(2026, 7, 18, 20),
      );
      expect(assessment.reasonCode, TrailFailureCodes.trailAlreadyCompleted);
    });
  });

  group('TrailGeo', () {
    test('distance is deterministic', () {
      final distance = TrailGeo.distanceMeters(
        lat1: 51.5074,
        lng1: -0.1278,
        lat2: 51.5074,
        lng2: -0.1278,
      );
      expect(distance, closeTo(0, 0.001));
    });
  });
}
