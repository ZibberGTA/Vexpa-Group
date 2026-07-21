import '../data/data_result.dart';
import 'trail_commands.dart';
import 'trail_queries.dart';
import 'trail_snapshots.dart';

/// Read/write access for user trail progress documents.
abstract interface class TrailProgressRepository {
  Future<DataResult<TrailProgressSnapshot>> get({
    required String userId,
    required String trailId,
  });

  Stream<DataResult<TrailProgressSnapshot?>> watch({
    required String userId,
    required String trailId,
  });

  Future<DataResult<TrailProgressSnapshot?>> getLegacyMirror({
    required String userId,
  });

  Future<DataResult<List<TrailProgressSnapshot>>> list(
    TrailProgressListQuery query,
  );

  Future<DataResult<TrailActiveStateSnapshot?>> getActiveState({
    required String userId,
  });

  Stream<DataResult<TrailActiveStateSnapshot?>> watchActiveState({
    required String userId,
  });

  Future<DataResult<void>> setActiveTrail(SetActiveTrailCommand command);

  Future<DataResult<TrailProgressSnapshot>> createProgress(
    CreateTrailProgressCommand command,
  );

  Future<DataResult<TrailProgressSnapshot>> checkIn(
    CheckInTrailProgressCommand command,
  );

  Future<DataResult<TrailProgressSnapshot>> continueProgress(
    ContinueTrailProgressCommand command,
  );

  Future<DataResult<TrailProgressSnapshot>> skipStop(
    SkipTrailProgressCommand command,
  );

  Future<DataResult<void>> mirrorLegacyProgress(
    MirrorLegacyTrailProgressCommand command,
  );
}
