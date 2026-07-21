import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'trail_test_helpers.dart';

void main() {
  group('TrailStopOrderPolicy', () {
    test('sorts route by order', () {
      final stops = [
        TrailStop(
          venueId: 'b',
          venueName: 'B',
          address: '',
          bannerImageUrl: '',
          logoUrl: '',
          order: 2,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 21),
          leaveAt: DateTime(2026, 1, 1, 22),
        ),
        TrailStop(
          venueId: 'a',
          venueName: 'A',
          address: '',
          bannerImageUrl: '',
          logoUrl: '',
          order: 1,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 20),
          leaveAt: DateTime(2026, 1, 1, 21),
        ),
      ];
      final sorted = TrailStopOrderPolicy.sortRoute(stops);
      expect(sorted.first.venueId, 'a');
    });

    test('detects duplicate orders', () {
      final validation = TrailStopOrderPolicy.validateRoute([
        TrailStop(
          venueId: 'a',
          venueName: 'A',
          address: '',
          bannerImageUrl: '',
          logoUrl: '',
          order: 1,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 20),
          leaveAt: DateTime(2026, 1, 1, 21),
        ),
        TrailStop(
          venueId: 'b',
          venueName: 'B',
          address: '',
          bannerImageUrl: '',
          logoUrl: '',
          order: 1,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 21),
          leaveAt: DateTime(2026, 1, 1, 22),
        ),
      ]);
      expect(validation.hasDuplicateOrders, isTrue);
    });

    test('renumbers contiguously from one', () {
      final renumbered = TrailStopOrderPolicy.renumberContiguous([
        TrailStop(
          venueId: 'a',
          venueName: 'A',
          address: '',
          bannerImageUrl: '',
          logoUrl: '',
          order: 5,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 20),
          leaveAt: DateTime(2026, 1, 1, 21),
        ),
      ]);
      expect(renumbered.single.order, 1);
    });
  });

  group('TrailProgressStatePolicy', () {
    test('initial stop states mark first index current', () {
      final trail = buildTrail();
      final states = TrailProgressStatePolicy.initialStopStates(trail);
      expect(states[1], TrailStopState.current);
      expect(states[2], TrailStopState.upcoming);
    });

    test('belongsTo rejects stale generatedAt', () {
      final trail = buildTrail(generatedAt: DateTime(2026, 7, 19));
      final progress = buildProgress(
        trailGeneratedAt: DateTime(2026, 7, 18, 12),
      );
      expect(
        TrailProgressStatePolicy.belongsToTrail(
          progress: progress,
          trail: trail,
        ),
        isFalse,
      );
    });
  });
}
