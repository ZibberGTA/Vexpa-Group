import '../data/data_result.dart';
import 'trail_commands.dart';
import 'trail_queries.dart';
import 'trail_snapshots.dart';

/// Read/write access for trail documents in `trails/{trailId}`.
abstract interface class TrailRepository {
  Future<DataResult<TrailSnapshot>> get(String trailId);

  Stream<DataResult<TrailSnapshot?>> watch(String trailId);

  Future<DataResult<List<TrailSnapshot>>> list(TrailListQuery query);

  Stream<DataResult<List<TrailSnapshot>>> watchList(TrailListQuery query);

  Future<DataResult<TrailSnapshot>> create(CreateTrailCommand command);

  Future<DataResult<TrailSnapshot>> updateMetadata(
    UpdateTrailMetadataCommand command,
  );

  Future<DataResult<TrailSnapshot>> updateStops(
    UpdateTrailStopsCommand command,
  );

  Future<DataResult<TrailSnapshot>> replaceDocument(
    ReplaceTrailDocumentCommand command,
  );

  Future<DataResult<TrailSnapshot>> publish(PublishTrailCommand command);

  Future<DataResult<TrailSnapshot>> unpublish(UnpublishTrailCommand command);

  Future<DataResult<TrailSnapshot>> archive(ArchiveTrailCommand command);

  Future<DataResult<TrailSnapshot>> duplicate(DuplicateTrailCommand command);

  Future<DataResult<void>> delete(DeleteTrailCommand command);
}
