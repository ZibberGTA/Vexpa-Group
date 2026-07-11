import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_owner_profile_service.dart';

import '../../home/models/venue_model.dart';
import '../../../core/vexcore/mobile_vexcore.dart';

/// Compatibility facade for owner venue list and write flows.
class OwnerVenueService {
  OwnerVenueService._();

  static const VenueOwnerProfileService _profileService =
      VenueOwnerProfileService();

  static Stream<List<VenueModel>> watchVenuesForOwner(String ownerId) {
    return MobileVexCore.venueRepository.watchOwnerHomeVenues(ownerId);
  }

  static Future<DataResult<String>> createVenue({
    required String ownerId,
    required VenueOwnerProfileDraft draft,
  }) async {
    final prepared = _profileService.prepareCreate(
      ownerId: ownerId,
      draft: draft,
    );

    return switch (prepared) {
      DataSuccess(:final value) =>
        MobileVexCore.venueWriteRepository.createVenue(
          venueWritePayloadFromPreparedWrite(value),
        ),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  static Future<DataResult<void>> updateVenue({
    required String venueId,
    required VenueOwnerProfileDraft draft,
  }) async {
    final prepared = _profileService.prepareUpdate(
      venueId: venueId,
      draft: draft,
    );

    return switch (prepared) {
      DataSuccess(:final value) => MobileVexCore.venueWriteRepository.updateVenue(
          venueId: venueId,
          payload: venueWritePayloadFromPreparedWrite(value),
        ),
      DataFailure(:final error) => DataFailure(error),
    };
  }
}
