import '../data/data_result.dart';
import 'trail_commands.dart';
import 'trail_queries.dart';
import 'trail_snapshots.dart';

/// Append/read access for trail activity documents.
abstract interface class TrailActivityRepository {
  Future<DataResult<TrailActivitySnapshot>> append(
    AppendTrailActivityCommand command,
  );

  Future<DataResult<List<TrailActivitySnapshot>>> list(
    TrailActivityListQuery query,
  );

  Stream<DataResult<List<TrailActivitySnapshot>>> watchList(
    TrailActivityListQuery query,
  );
}
