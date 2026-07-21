import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/trails/trails.dart';

/// Resolves external banner URLs; upload/delete remain unsupported in production.
class FirebaseTrailMediaRepository implements TrailMediaRepository {
  @override
  TrailArtworkReference resolveArtworkReference(String bannerImageUrl) {
    return TrailArtworkReference(url: bannerImageUrl.trim());
  }

  @override
  Future<DataResult<TrailArtworkReference>> uploadArtwork(
    UploadTrailArtworkCommand command,
  ) async {
    return DataFailure(
      VexException(
        'Trail artwork upload is not implemented in mobile production.',
        code: 'trail-artwork-upload-unsupported',
      ),
    );
  }

  @override
  Future<DataResult<void>> deleteArtwork(DeleteTrailArtworkCommand command) async {
    return DataFailure(
      VexException(
        'Trail artwork delete is not implemented in mobile production.',
        code: 'trail-artwork-delete-unsupported',
      ),
    );
  }
}
