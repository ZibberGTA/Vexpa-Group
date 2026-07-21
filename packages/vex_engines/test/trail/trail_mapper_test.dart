import 'package:test/test.dart';
import 'package:vex_core/trails/trail_snapshots.dart';
import 'package:vex_engines/trail/trail_engine.dart';

void main() {
  group('TrailSnapshotMapper', () {
    test('maps trail snapshot resolving aliases', () {
      final result = TrailSnapshotMapper.toDomain(
        TrailSnapshot(
          trailId: 't1',
          name: '',
          title: 'Alias Title',
          description: '',
          subtitle: 'Alias Description',
          bannerImageUrl: '',
          status: const KnownTrailStatusSnapshot(TrailStatusValue.published),
          published: true,
          area: '',
          availabilityStart: DateTime(2026, 7, 18, 19),
          availabilityEnd: DateTime(2026, 7, 18, 23),
          startTime: DateTime(2026, 7, 18, 19),
          endTime: DateTime(2026, 7, 18, 23),
          estimatedDurationMinutes: 240,
          estimatedWalkingDistance: 0,
          averageRating: 0,
          venueCount: 1,
          trailType: const KnownTrailTypeSnapshot(TrailTypeValue.curated),
          generatedAt: DateTime(2026, 7, 18, 12),
          stops: [
            TrailStopSnapshot(
              venueId: 'v1',
              venueName: 'Venue',
              address: '',
              bannerImageUrl: '',
              logoUrl: '',
              order: 1,
              score: 0,
              arriveAt: DateTime(2026, 7, 18, 19),
              leaveAt: DateTime(2026, 7, 18, 20),
            ),
          ],
        ),
      );

      expect(result, isA<TrailSuccess<Trail>>());
      final trail = (result as TrailSuccess).value;
      expect(trail.name, 'Alias Title');
      expect(trail.description, 'Alias Description');
    });

    test('fails on unknown status', () {
      final result = TrailSnapshotMapper.toDomain(
        TrailSnapshot(
          trailId: 't1',
          name: 'Trail',
          title: 'Trail',
          description: 'Desc',
          subtitle: 'Desc',
          bannerImageUrl: '',
          status: const UnknownTrailStatusSnapshot('experimental'),
          published: false,
          area: '',
          availabilityStart: DateTime(2026, 7, 18, 19),
          availabilityEnd: DateTime(2026, 7, 18, 23),
          startTime: DateTime(2026, 7, 18, 19),
          endTime: DateTime(2026, 7, 18, 23),
          estimatedDurationMinutes: 240,
          estimatedWalkingDistance: 0,
          averageRating: 0,
          venueCount: 0,
          trailType: const KnownTrailTypeSnapshot(TrailTypeValue.curated),
          generatedAt: DateTime(2026, 7, 18, 12),
          stops: const [],
        ),
      );
      expect(result, isA<TrailFailure>());
    });

    test('maps progress snapshot and hydrates checked-in orders', () {
      final result = TrailSnapshotMapper.progressToDomain(
        TrailProgressSnapshot(
          trailId: 't1',
          started: true,
          completed: false,
          currentStop: 0,
          checkedInStops: {1},
          stopStates: const {
            2: KnownTrailStopProgressStateSnapshot(
              TrailStopProgressStateValue.current,
            ),
          },
        ),
      );

      final progress = (result as TrailSuccess).value as TrailProgress;
      expect(progress.stopStates[1], TrailStopState.checkedIn);
      expect(progress.stopStates[2], TrailStopState.current);
    });
  });
}
