import 'package:vex_core/vex_core.dart';

import '../application/venue_profile_update.dart';

/// Provider-neutral contract for applying prepared venue profile updates.
abstract interface class VenueProfileWriteRepository {
  Future<DataResult<void>> applyVenueProfileUpdate({
    required String venueId,
    required VenueProfileUpdate update,
  });
}
