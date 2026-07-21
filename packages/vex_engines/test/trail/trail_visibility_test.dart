import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'trail_test_helpers.dart';

void main() {
  group('TrailVisibilityPolicy', () {
    final now = DateTime(2026, 7, 18, 20);

    test('hides draft trails publicly', () {
      final trail = buildTrail(status: TrailStatus.draft, published: false);
      final decision = TrailVisibilityPolicy.evaluate(trail: trail, now: now);
      expect(decision.isVisible, isFalse);
      expect(decision.reasonCode, 'notPublished');
    });

    test('shows published trail within availability window', () {
      final trail = buildTrail();
      expect(TrailVisibilityPolicy.isVisible(trail: trail, now: now), isTrue);
    });

    test('shows trail before start on same local day', () {
      final start = DateTime(2026, 7, 18, 22);
      final trail = buildTrail(
        availabilityStart: start,
        availabilityEnd: DateTime(2026, 7, 18, 23, 59),
      );
      expect(
        TrailVisibilityPolicy.isVisible(
          trail: trail,
          now: DateTime(2026, 7, 18, 20),
        ),
        isTrue,
      );
    });

    test('hides upcoming trail before start on different day', () {
      final trail = buildTrail(
        availabilityStart: DateTime(2026, 7, 20, 19),
        availabilityEnd: DateTime(2026, 7, 20, 23),
      );
      final decision = TrailVisibilityPolicy.evaluate(
        trail: trail,
        now: DateTime(2026, 7, 18, 20),
      );
      expect(decision.isVisible, isFalse);
      expect(decision.reasonCode, 'upcoming');
    });

    test('hides archived trails', () {
      final trail = buildTrail(status: TrailStatus.archived, published: false);
      final decision = TrailVisibilityPolicy.evaluate(trail: trail, now: now);
      expect(decision.isVisible, isFalse);
    });

    test('admin audience bypasses public checks', () {
      final trail = buildTrail(status: TrailStatus.draft, published: false);
      expect(
        TrailVisibilityPolicy.isVisible(
          trail: trail,
          now: now,
          audience: TrailVisibilityAudience.admin,
        ),
        isTrue,
      );
    });

    test('hides published trail with no stops', () {
      final trail = buildTrail(stops: const [], venueCount: 0);
      final decision = TrailVisibilityPolicy.evaluate(trail: trail, now: now);
      expect(decision.reasonCode, 'noStops');
    });
  });

  group('TrailAvailabilityPolicy', () {
    test('reports invalid configuration when end before start', () {
      final decision = TrailAvailabilityPolicy.evaluate(
        trail: buildTrail(
          availabilityStart: DateTime(2026, 7, 18, 23),
          availabilityEnd: DateTime(2026, 7, 18, 19),
        ),
        now: DateTime(2026, 7, 18, 20),
      );
      expect(decision.state, TrailAvailabilityState.invalidConfiguration);
    });

    test('reports ended after availability end', () {
      final decision = TrailAvailabilityPolicy.evaluate(
        trail: buildTrail(
          availabilityStart: DateTime(2026, 7, 18, 17),
          availabilityEnd: DateTime(2026, 7, 18, 18),
        ),
        now: DateTime(2026, 7, 18, 20),
      );
      expect(decision.state, TrailAvailabilityState.ended);
    });
  });
}
