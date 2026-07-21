import '../data/data_result.dart';
import 'trail_commands.dart';
import 'trail_snapshots.dart';

/// Trail artwork reference resolution and optional Storage operations.
///
/// Mobile production currently stores banner URLs on the trail document only.
abstract interface class TrailMediaRepository {
  TrailArtworkReference resolveArtworkReference(String bannerImageUrl);

  Future<DataResult<TrailArtworkReference>> uploadArtwork(
    UploadTrailArtworkCommand command,
  );

  Future<DataResult<void>> deleteArtwork(DeleteTrailArtworkCommand command);
}
