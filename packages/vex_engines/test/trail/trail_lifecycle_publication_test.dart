import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'trail_test_helpers.dart';

void main() {
  group('TrailPublicationPolicy', () {
    test('blocks publish when name missing', () {
      final readiness = TrailPublicationPolicy.evaluate(buildTrail(name: '  '));
      expect(readiness.isReady, isFalse);
      expect(
        readiness.checks
            .firstWhere((c) => c.id == TrailPublicationCheckId.name)
            .passed,
        isFalse,
      );
    });

    test('blocks publish when banner missing', () {
      final readiness = TrailPublicationPolicy.evaluate(
        buildTrail(bannerImageUrl: ''),
      );
      expect(readiness.isReady, isFalse);
    });

    test('blocks publish when no venues', () {
      final readiness = TrailPublicationPolicy.evaluate(
        buildTrail(stops: const [], venueCount: 0),
      );
      expect(readiness.isReady, isFalse);
    });

    test('passes valid publishable trail', () {
      final readiness = TrailPublicationPolicy.evaluate(buildTrail());
      expect(readiness.isReady, isTrue);
    });

    test('blocks archived status', () {
      final readiness = TrailPublicationPolicy.evaluate(
        buildTrail(status: TrailStatus.archived, published: false),
      );
      expect(
        readiness.checks
            .firstWhere((c) => c.id == TrailPublicationCheckId.status)
            .passed,
        isFalse,
      );
    });
  });

  group('TrailLifecyclePolicy', () {
    test('allows publish from draft', () {
      final result = TrailLifecyclePolicy.validateTransition(
        trail: buildTrail(status: TrailStatus.draft, published: false),
        action: TrailLifecycleAction.publish,
      );
      expect(result, isA<TrailSuccess<TrailLifecycleAction>>());
    });

    test('blocks publish from archived', () {
      final result = TrailLifecyclePolicy.validateTransition(
        trail: buildTrail(status: TrailStatus.archived, published: false),
        action: TrailLifecycleAction.publish,
      );
      expect(result, isA<TrailFailure<TrailLifecycleAction>>());
    });

    test('disable maps to archived state', () {
      final proposed = TrailLifecyclePolicy.applyTransition(
        trail: buildTrail(status: TrailStatus.published),
        action: TrailLifecycleAction.disable,
      );
      expect(proposed.status, TrailStatus.archived);
      expect(proposed.published, isFalse);
    });

    test('duplicate creates draft copy name', () {
      final proposed = TrailLifecyclePolicy.applyTransition(
        trail: buildTrail(name: 'Original'),
        action: TrailLifecycleAction.duplicate,
      );
      expect(proposed.name, 'Original Copy');
      expect(proposed.status, TrailStatus.draft);
    });

    test('saveStops forces draft unpublished', () {
      final proposed = TrailLifecyclePolicy.applyTransition(
        trail: buildTrail(),
        action: TrailLifecycleAction.saveStops,
      );
      expect(proposed.status, TrailStatus.draft);
      expect(proposed.published, isFalse);
    });
  });

  group('TrailLifecycleService', () {
    test('requires publication readiness when configured', () {
      const service = TrailLifecycleService();
      final result = service.plan(
        trail: buildTrail(name: '', bannerImageUrl: ''),
        action: TrailLifecycleAction.publish,
        occurredAt: DateTime(2026, 7, 18, 20),
        eventId: 'evt-1',
        requirePublicationReadiness: true,
      );
      expect(result, isA<TrailFailure<TrailLifecycleTransitionPlan>>());
    });
  });
}
