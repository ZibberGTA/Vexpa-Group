import 'package:test/test.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'fake_trail_repositories.dart';
import 'trail_test_helpers.dart';

void main() {
  group('TrailDiscoveryApplicationService', () {
    test('filters invisible trails and sorts by type then rating', () async {
      final visible = buildTrail(id: 'visible', trailType: TrailType.curated);
      final hidden = buildTrail(
        id: 'hidden',
        status: TrailStatus.draft,
        published: false,
      );
      final repo = FakeTrailRepository(
        trails: [snapshotFromDomain(hidden), snapshotFromDomain(visible)],
      );
      final service = TrailDiscoveryApplicationService(
        trailRepository: repo,
        clock: FixedTrailClock(DateTime(2026, 7, 18, 20)),
      );

      final result = await service.listVisibleTrails();
      expect(result, isA<TrailApplicationSuccess<List<Trail>>>());
      final trails = (result as TrailApplicationSuccess).value;
      expect(trails, hasLength(1));
      expect(trails.first.id, 'visible');
    });

    test('returns mapping failure for invalid snapshot status', () async {
      final repo = FakeTrailRepository(
        trails: [
          TrailSnapshot(
            trailId: 'bad',
            name: 'Bad',
            title: 'Bad',
            description: 'd',
            subtitle: 'd',
            bannerImageUrl: '',
            status: const UnknownTrailStatusSnapshot('mystery'),
            published: true,
            area: 'City',
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
            stops: const [],
          ),
        ],
      );
      final service = TrailDiscoveryApplicationService(trailRepository: repo);
      final result = await service.listVisibleTrails();
      expect(result, isA<TrailApplicationFailure>());
    });
  });

  group('TrailManagementApplicationService', () {
    late FakeTrailRepository repo;
    late FakeTrailEventPublisher publisher;
    late TrailManagementApplicationService service;

    setUp(() {
      repo = FakeTrailRepository(trails: [snapshotFromDomain(buildTrail())]);
      publisher = FakeTrailEventPublisher();
      service = TrailManagementApplicationService(
        trailRepository: repo,
        coordinator: TrailPersistenceCoordinator(
          trailRepository: repo,
          progressRepository: FakeTrailProgressRepository(),
          activityRepository: FakeTrailActivityRepository(),
          eventPublisher: publisher,
        ),
        clock: FixedTrailClock(DateTime(2026, 7, 18, 20)),
      );
    });

    test('publishValidated rejects unreadiness', () async {
      final draft = buildTrail(
        status: TrailStatus.draft,
        published: false,
        stops: [],
      );
      repo.trails[draft.id] = snapshotFromDomain(draft);
      final result = await service.publishValidated(draft.id);
      expect(result, isA<TrailApplicationFailure>());
    });

    test('duplicate returns mapped trail', () async {
      final result = await service.duplicate('trail-1');
      expect(result, isA<TrailApplicationSuccess<Trail>>());
      expect((result as TrailApplicationSuccess).value.name, contains('Copy'));
    });
  });

  group('TrailProgressApplicationService', () {
    late FakeTrailRepository trailRepo;
    late FakeTrailProgressRepository progressRepo;
    late FakeTrailActivityRepository activityRepo;
    late FakeTrailEventPublisher publisher;
    late FakeTrailUserContext userContext;
    late TrailProgressApplicationService service;

    setUp(() {
      final trail = buildTrail(id: 'trail-1');
      trailRepo = FakeTrailRepository(trails: [snapshotFromDomain(trail)]);
      progressRepo = FakeTrailProgressRepository();
      activityRepo = FakeTrailActivityRepository();
      publisher = FakeTrailEventPublisher();
      userContext = FakeTrailUserContext();
      service = TrailProgressApplicationService(
        trailRepository: trailRepo,
        progressRepository: progressRepo,
        coordinator: TrailPersistenceCoordinator(
          trailRepository: trailRepo,
          progressRepository: progressRepo,
          activityRepository: activityRepo,
          eventPublisher: publisher,
        ),
        userContext: userContext,
        clock: FixedTrailClock(DateTime(2026, 7, 18, 20)),
      );
    });

    test('join writes canonical progress and started activity', () async {
      final result = await service.join(trailId: 'trail-1');
      expect(result, isA<TrailApplicationSuccess<TrailProgress>>());
      expect(progressRepo.progressByKey, isNotEmpty);
      expect(activityRepo.appended, hasLength(1));
      expect(activityRepo.appended.first.action, TrailActivityType.started);
      expect(publisher.published, isNotEmpty);
    });

    test('join requires authentication', () async {
      userContext.userId = null;
      final result = await service.join(trailId: 'trail-1');
      expect(result, isA<TrailApplicationFailure>());
    });

    test('check-in with missing venue location is permissive', () async {
      final joined = await service.join(trailId: 'trail-1');
      expect(joined, isA<TrailApplicationSuccess<TrailProgress>>());
      final progress = (joined as TrailApplicationSuccess<TrailProgress>).value;
      final trail = buildTrail(id: 'trail-1');
      final stop = trail.stops.first;

      final result = await service.checkIn(
        trail: trail,
        stop: stop,
        stopIndex: 0,
        progress: progress,
      );
      expect(result, isA<TrailApplicationSuccess<TrailProgress>>());
      expect(
        activityRepo.appended.any(
          (item) => item.action == TrailActivityType.arrived,
        ),
        isTrue,
      );
    });

    test('activity failure returns warning not rollback', () async {
      activityRepo.failNext = true;
      final result = await service.join(trailId: 'trail-1');
      expect(result, isA<TrailApplicationSuccess<TrailProgress>>());
      expect((result as TrailApplicationSuccess).warnings, isNotEmpty);
    });
  });

  group('TrailCheckInApplicationService', () {
    test('assessEligibility allows missing venue location', () async {
      final clock = FixedTrailClock(DateTime(2026, 7, 18, 20));
      final service = TrailCheckInApplicationService(
        venueLookup: FakeTrailVenueLookup(presence: null),
        progressService: TrailProgressApplicationService(
          trailRepository: FakeTrailRepository(),
          progressRepository: FakeTrailProgressRepository(),
          coordinator: TrailPersistenceCoordinator(
            trailRepository: FakeTrailRepository(),
            progressRepository: FakeTrailProgressRepository(),
            activityRepository: FakeTrailActivityRepository(),
            eventPublisher: FakeTrailEventPublisher(),
          ),
          userContext: FakeTrailUserContext(),
        ),
        clock: clock,
      );

      final result = await service.assessEligibility(
        trail: buildTrail(),
        progress: buildProgress(),
        stop: buildTrail().stops.first,
        stopIndex: 0,
        now: clock.now(),
      );
      expect(result, isA<TrailApplicationSuccess<TrailCheckInAssessment>>());
      expect((result as TrailApplicationSuccess).value.eligible, isTrue);
    });
  });
}
