import 'package:test/test.dart';
import 'package:vex_core/trails/trail_commands.dart';
import 'package:vex_core/trails/trail_paths.dart';
import 'package:vex_core/trails/trail_queries.dart';
import 'package:vex_core/trails/trail_snapshots.dart';

void main() {
  group('TrailPaths', () {
    test('builds canonical and legacy paths', () {
      expect(TrailPaths.trailDocument('abc'), 'trails/abc');
      expect(
        TrailPaths.userTrailProgressDocument('user-1', 'trail-1'),
        'users/user-1/trails/trail-1/progress/current',
      );
      expect(
        TrailPaths.legacyUserTrailProgressDocument('user-1'),
        'trail_progress/user-1',
      );
      expect(
        TrailPaths.userActiveTrailStateDocument('user-1'),
        'users/user-1/trail_state/active',
      );
      expect(TrailPaths.activeTrailDocumentId, 'activeTrail');
    });
  });

  group('TrailListQuery validation', () {
    test('rejects non-positive limit', () {
      expect(() => TrailListQuery(limit: 0), throwsA(isA<AssertionError>()));
    });

    test('rejects excessive limit', () {
      expect(() => TrailListQuery(limit: 501), throwsA(isA<AssertionError>()));
    });
  });

  group('TrailProgressListQuery validation', () {
    test('rejects empty user id', () {
      expect(
        () => TrailProgressListQuery(userId: '  '),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects active and completed together', () {
      expect(
        () => TrailProgressListQuery(
          userId: 'user-1',
          activeOnly: true,
          completedOnly: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Trail command validation', () {
    test('DeleteTrailCommand rejects empty trail id', () {
      expect(
        () => DeleteTrailCommand(trailId: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('AppendTrailActivityCommand rejects empty action', () {
      expect(
        () => AppendTrailActivityCommand(trailId: 't1', action: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('UploadTrailArtworkCommand rejects empty bytes', () {
      expect(
        () => UploadTrailArtworkCommand(
          trailId: 't1',
          bytes: const [],
          contentType: 'image/png',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('SetActiveTrailCommand requires non-empty ids', () {
      expect(
        () => SetActiveTrailCommand(userId: '', activeTrailId: 't1'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Command DTOs carry typed trail write payloads', () {
    test('UpdateTrailStopsCommand embeds stop snapshots', () {
      final command = UpdateTrailStopsCommand(
        trailId: 'trail-1',
        stops: [
          TrailStopSnapshot(
            venueId: 'v1',
            venueName: 'Venue',
            address: 'Addr',
            bannerImageUrl: '',
            logoUrl: '',
            order: 1,
            score: 10,
            arriveAt: DateTime(2026, 1, 1, 20),
            leaveAt: DateTime(2026, 1, 1, 21),
          ),
        ],
        availabilityStart: DateTime(2026, 1, 1, 20),
        availabilityEnd: DateTime(2026, 1, 1, 21),
        estimatedDurationMinutes: 60,
        venueCount: 1,
      );

      expect(command.stops.single.order, 1);
      expect(command.venueCount, 1);
    });

    test('CreateTrailProgressCommand exposes legacy mirror flag', () {
      final command = CreateTrailProgressCommand(
        userId: 'user-1',
        trailId: TrailPaths.activeTrailDocumentId,
        trailGeneratedAt: DateTime(2026, 1, 1),
        stopStates: const {
          1: KnownTrailStopProgressStateSnapshot(
            TrailStopProgressStateValue.current,
          ),
        },
        mirrorLegacyProgress: true,
      );

      expect(command.mirrorLegacyProgress, isTrue);
    });
  });
}
