import '../../../core/vexcore/mobile_vexcore.dart';
import '../models/venue_model.dart';
import '../../owner/services/owner_venue_service.dart';

class VenueService {
  VenueService._();

  static Stream<List<VenueModel>> getVenues() {
    return MobileVexCore.venueRepository.watchHomeVenueCatalog();
  }

  static Stream<List<VenueModel>> getVenuesForOwner(String ownerId) {
    return OwnerVenueService.watchVenuesForOwner(ownerId);
  }
}
