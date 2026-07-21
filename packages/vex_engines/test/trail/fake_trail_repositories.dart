import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/events/vex_event.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_engines/trail/trail_engine.dart';

final class FakeTrailUserContext implements TrailUserContextPort {
  FakeTrailUserContext({this.userId = 'user-1', this.isAnonymous = false});

  String? userId;
  bool isAnonymous;

  @override
  TrailUserContext currentUser() {
    return TrailUserContext(userId: userId, isAnonymous: isAnonymous);
  }
}

final class FakeTrailEventPublisher implements TrailEventPublisherPort {
  final published = <VexEvent>[];

  @override
  Future<void> publishAll(List<VexEvent> events) async {
    published.addAll(events);
  }
}

final class FakeTrailVenueLookup implements TrailVenueLookupPort {
  FakeTrailVenueLookup({this.presence});

  TrailVenuePresence? presence;

  @override
  Future<TrailVenuePresence?> lookup(String venueId) async => presence;
}

final class FakeTrailRepository implements TrailRepository {
  FakeTrailRepository({List<TrailSnapshot>? trails})
    : trails = {for (final trail in trails ?? []) trail.trailId: trail};

  final Map<String, TrailSnapshot> trails;
  bool failNext = false;

  @override
  Future<DataResult<TrailSnapshot>> archive(
    ArchiveTrailCommand command,
  ) async => get(command.trailId);

  @override
  Future<DataResult<TrailSnapshot>> create(CreateTrailCommand command) async {
    if (failNext) return _fail();
    final id = command.trailId ?? 'new-trail';
    final snapshot = TrailSnapshot(
      trailId: id,
      name: command.name,
      title: command.name,
      description: command.description,
      subtitle: command.description,
      bannerImageUrl: command.bannerImageUrl,
      status: const KnownTrailStatusSnapshot(TrailStatusValue.draft),
      published: false,
      area: command.area,
      availabilityStart: command.availabilityStart,
      availabilityEnd: command.availabilityEnd,
      startTime: command.availabilityStart,
      endTime: command.availabilityEnd,
      estimatedDurationMinutes: command.availabilityEnd
          .difference(command.availabilityStart)
          .inMinutes,
      estimatedWalkingDistance: 0,
      averageRating: 0,
      venueCount: 0,
      trailType: KnownTrailTypeSnapshot(TrailTypeValue.curated),
      generatedAt: DateTime(2026, 7, 18, 12),
      stops: const [],
    );
    trails[id] = snapshot;
    return DataSuccess(snapshot);
  }

  @override
  Future<DataResult<void>> delete(DeleteTrailCommand command) async {
    trails.remove(command.trailId);
    return const DataSuccess(null);
  }

  @override
  Future<DataResult<TrailSnapshot>> duplicate(
    DuplicateTrailCommand command,
  ) async {
    final source = trails[command.sourceTrailId];
    if (source == null) return _fail();
    final copy = TrailSnapshot(
      trailId: 'copy-${source.trailId}',
      name: '${source.name} Copy',
      title: '${source.name} Copy',
      description: source.description,
      subtitle: source.subtitle,
      bannerImageUrl: source.bannerImageUrl,
      status: const KnownTrailStatusSnapshot(TrailStatusValue.draft),
      published: false,
      area: source.area,
      availabilityStart: source.availabilityStart,
      availabilityEnd: source.availabilityEnd,
      startTime: source.startTime,
      endTime: source.endTime,
      estimatedDurationMinutes: source.estimatedDurationMinutes,
      estimatedWalkingDistance: source.estimatedWalkingDistance,
      averageRating: source.averageRating,
      venueCount: source.venueCount,
      trailType: source.trailType,
      generatedAt: DateTime.now(),
      stops: source.stops,
    );
    trails[copy.trailId] = copy;
    return DataSuccess(copy);
  }

  @override
  Future<DataResult<TrailSnapshot>> get(String trailId) async {
    if (failNext) return _fail();
    final snapshot = trails[trailId];
    if (snapshot == null) {
      return DataFailure(
        VexException('Trail not found.', code: 'trail-not-found'),
      );
    }
    return DataSuccess(snapshot);
  }

  @override
  Future<DataResult<List<TrailSnapshot>>> list(TrailListQuery query) async {
    if (failNext) return _fail();
    return DataSuccess(trails.values.toList());
  }

  @override
  Future<DataResult<TrailSnapshot>> publish(
    PublishTrailCommand command,
  ) async => get(command.trailId);

  @override
  Future<DataResult<TrailSnapshot>> replaceDocument(
    ReplaceTrailDocumentCommand command,
  ) async {
    trails[command.trailId] = command.snapshot;
    return DataSuccess(command.snapshot);
  }

  @override
  Future<DataResult<TrailSnapshot>> unpublish(
    UnpublishTrailCommand command,
  ) async => get(command.trailId);

  @override
  Future<DataResult<TrailSnapshot>> updateMetadata(
    UpdateTrailMetadataCommand command,
  ) async => get(command.trailId);

  @override
  Future<DataResult<TrailSnapshot>> updateStops(
    UpdateTrailStopsCommand command,
  ) async => get(command.trailId);

  @override
  Stream<DataResult<TrailSnapshot?>> watch(String trailId) async* {
    yield await get(trailId).then(
      (result) => result is DataSuccess<TrailSnapshot>
          ? DataSuccess<TrailSnapshot?>(result.value)
          : result as DataResult<TrailSnapshot?>,
    );
  }

  @override
  Stream<DataResult<List<TrailSnapshot>>> watchList(
    TrailListQuery query,
  ) async* {
    yield await list(query);
  }

  DataFailure<T> _fail<T>() =>
      DataFailure(VexException('Repository failure.', code: 'repo-failed'));
}

final class FakeTrailProgressRepository implements TrailProgressRepository {
  final Map<String, TrailProgressSnapshot> progressByKey = {};
  TrailActiveStateSnapshot? activeState;
  bool failNext = false;
  bool failActivity = false;

  String _key(String userId, String trailId) => '$userId::$trailId';

  @override
  Future<DataResult<TrailProgressSnapshot>> checkIn(
    CheckInTrailProgressCommand command,
  ) async =>
      _write(command.trailId, command.userId, currentStop: command.currentStop);

  @override
  Future<DataResult<TrailProgressSnapshot>> continueProgress(
    ContinueTrailProgressCommand command,
  ) async =>
      _write(command.trailId, command.userId, currentStop: command.currentStop);

  @override
  Future<DataResult<TrailProgressSnapshot>> createProgress(
    CreateTrailProgressCommand command,
  ) async {
    if (failNext) {
      return DataFailure(
        VexException('Progress write failed.', code: 'progress-failed'),
      );
    }
    final snapshot = TrailProgressSnapshot(
      trailId: command.trailId,
      started: true,
      completed: false,
      currentStop: 0,
      checkedInStops: const {},
      stopStates: command.stopStates,
      trailGeneratedAt: command.trailGeneratedAt,
      startedAt: DateTime(2026, 7, 18, 20),
      updatedAt: DateTime(2026, 7, 18, 20),
    );
    progressByKey[_key(command.userId, command.trailId)] = snapshot;
    activeState = TrailActiveStateSnapshot(
      activeTrailId: command.trailId,
      updatedAt: DateTime(2026, 7, 18, 20),
    );
    return DataSuccess(snapshot);
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> get({
    required String userId,
    required String trailId,
  }) async {
    final snapshot = progressByKey[_key(userId, trailId)];
    if (snapshot == null) {
      return DataFailure(
        VexException('Progress not found.', code: 'progress-not-found'),
      );
    }
    return DataSuccess(snapshot);
  }

  @override
  Future<DataResult<TrailActiveStateSnapshot?>> getActiveState({
    required String userId,
  }) async => DataSuccess(activeState);

  @override
  Future<DataResult<TrailProgressSnapshot?>> getLegacyMirror({
    required String userId,
  }) async => const DataSuccess(null);

  @override
  Future<DataResult<List<TrailProgressSnapshot>>> list(
    TrailProgressListQuery query,
  ) async => DataSuccess(progressByKey.values.toList());

  @override
  Future<DataResult<void>> mirrorLegacyProgress(
    MirrorLegacyTrailProgressCommand command,
  ) async => const DataSuccess(null);

  @override
  Future<DataResult<TrailProgressSnapshot>> skipStop(
    SkipTrailProgressCommand command,
  ) async =>
      _write(command.trailId, command.userId, currentStop: command.currentStop);

  @override
  Future<DataResult<void>> setActiveTrail(SetActiveTrailCommand command) async {
    activeState = TrailActiveStateSnapshot(
      activeTrailId: command.activeTrailId,
      updatedAt: DateTime.now(),
    );
    return const DataSuccess(null);
  }

  @override
  Stream<DataResult<TrailProgressSnapshot?>> watch({
    required String userId,
    required String trailId,
  }) async* {
    final result = await get(userId: userId, trailId: trailId);
    yield result is DataSuccess<TrailProgressSnapshot>
        ? DataSuccess<TrailProgressSnapshot?>(result.value)
        : result as DataResult<TrailProgressSnapshot?>;
  }

  @override
  Stream<DataResult<TrailActiveStateSnapshot?>> watchActiveState({
    required String userId,
  }) async* {
    yield await getActiveState(userId: userId);
  }

  Future<DataResult<TrailProgressSnapshot>> _write(
    String trailId,
    String userId, {
    required int currentStop,
  }) async {
    final existing = progressByKey[_key(userId, trailId)];
    if (existing == null) return get(userId: userId, trailId: trailId);
    final updated = TrailProgressSnapshot(
      trailId: existing.trailId,
      started: existing.started,
      completed: existing.completed,
      currentStop: currentStop,
      checkedInStops: existing.checkedInStops,
      stopStates: existing.stopStates,
      trailGeneratedAt: existing.trailGeneratedAt,
      startedAt: existing.startedAt,
      updatedAt: DateTime.now(),
      completedAt: existing.completedAt,
      lastCheckedInVenueId: existing.lastCheckedInVenueId,
      lastCheckedInStopOrder: existing.lastCheckedInStopOrder,
    );
    progressByKey[_key(userId, trailId)] = updated;
    return DataSuccess(updated);
  }
}

final class FakeTrailActivityRepository implements TrailActivityRepository {
  final appended = <AppendTrailActivityCommand>[];
  bool failNext = false;

  @override
  Future<DataResult<TrailActivitySnapshot>> append(
    AppendTrailActivityCommand command,
  ) async {
    if (failNext) {
      return DataFailure(
        VexException('Activity failed.', code: 'activity-failed'),
      );
    }
    appended.add(command);
    return DataSuccess(
      TrailActivitySnapshot(
        activityId: 'act-${appended.length}',
        trailId: command.trailId,
        userId: command.userId,
        isAnonymous: command.isAnonymous,
        action: command.action,
        createdAt: DateTime.now(),
        venueId: command.venueId,
        stopOrder: command.stopOrder,
      ),
    );
  }

  @override
  Future<DataResult<List<TrailActivitySnapshot>>> list(
    TrailActivityListQuery query,
  ) async => const DataSuccess([]);

  @override
  Stream<DataResult<List<TrailActivitySnapshot>>> watchList(
    TrailActivityListQuery query,
  ) => Stream.value(const DataSuccess([]));
}

TrailSnapshot snapshotFromDomain(Trail trail) {
  return TrailPersistenceMapper.toSnapshot(trail);
}
