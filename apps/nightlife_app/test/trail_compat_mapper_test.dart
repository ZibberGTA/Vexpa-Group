import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/trails/models/trail_model.dart';
import 'package:nightlife_app/features/trails/services/trail_compat_mapper.dart';
import 'package:nightlife_app/features/trails/services/trail_service.dart';
import 'package:nightlife_app/features/trails/services/trail_service_config.dart';
import 'package:vex_engines/trail/trail_engine.dart' as vex;

void main() {
  group('TrailCompatMapper', () {
    test('round-trips trail and progress models', () {
      final start = DateTime.now().subtract(const Duration(hours: 1));
      final end = DateTime.now().add(const Duration(hours: 4));
      final mobileTrail = DrinkSpotTrailModel(
        id: 'trail-1',
        name: 'Trail',
        description: 'Desc',
        status: TrailStatus.published,
        published: true,
        generatedAt: DateTime(2026, 7, 18, 12),
        availabilityStart: start,
        availabilityEnd: end,
        stops: [
          TrailStopModel(
            venueId: 'v1',
            venueName: 'Venue',
            address: 'Addr',
            bannerImageUrl: '',
            logoUrl: '',
            order: 1,
            score: 10,
            arriveAt: DateTime(2026, 7, 18, 19),
            leaveAt: DateTime(2026, 7, 18, 20),
          ),
        ],
      );

      final domain = TrailCompatMapper.toDomain(mobileTrail);
      final roundTrip = TrailCompatMapper.fromDomain(domain);

      expect(roundTrip.id, mobileTrail.id);
      expect(roundTrip.name, mobileTrail.name);
      expect(roundTrip.stops.first.order, 1);
      expect(roundTrip.isVisible, isTrue);

      final progress = vex.TrailProgress(
        trailId: 'trail-1',
        started: true,
        completed: false,
        currentStopIndex: 0,
        checkedInStopOrders: {1},
        stopStates: {1: vex.TrailStopState.checkedIn},
        trailGeneratedAt: mobileTrail.generatedAt,
      );
      final mobileProgress = TrailCompatMapper.fromDomainProgress(progress);
      expect(mobileProgress.currentStop, 0);
      expect(mobileProgress.checkedInStops, {1});
    });
  });

  group('TrailService migration config', () {
    tearDown(TrailService.resetMigrationTestOverrides);

    test('defaults to VexTrail facade', () {
      expect(TrailServiceMigrationConfig.enabled, isTrue);
    });

    test('supports legacy rollback override for tests', () {
      TrailService.overrideUseVexTrailFacade(false);
      expect(TrailServiceMigrationConfig.enabled, isFalse);
      TrailService.resetMigrationTestOverrides();
      expect(TrailServiceMigrationConfig.enabled, isTrue);
    });
  });
}
