import '../models/bulk_deal_patch.dart';
import '../models/bulk_drink_patch.dart';
import '../models/bulk_event_patch.dart';
import '../models/venue_management_activity_types.dart';

/// Derives activity action types from partial CRUD payloads.
abstract final class VenueManagementActivityActionInference {
  static String drinkPatchActionType(BulkDrinkPatch patch) {
    if (_changesAvailabilityOnly(patch)) {
      return VenueManagementActivityActionTypes.availabilityChanged;
    }
    return VenueManagementActivityActionTypes.updated;
  }

  static String dealPatchActionType(BulkDealPatch patch) {
    if (patch.isActive == false) {
      return VenueManagementActivityActionTypes.deactivated;
    }
    if (patch.isActive == true) {
      return VenueManagementActivityActionTypes.activated;
    }
    return VenueManagementActivityActionTypes.updated;
  }

  static String eventPatchActionType(BulkEventPatch patch) {
    if (_changesPublicationOnly(patch)) {
      return patch.isActive == true
          ? VenueManagementActivityActionTypes.published
          : VenueManagementActivityActionTypes.unpublished;
    }
    return VenueManagementActivityActionTypes.updated;
  }

  static bool _changesAvailabilityOnly(BulkDrinkPatch patch) {
    return patch.available != null &&
        patch.name == null &&
        patch.category == null &&
        patch.price == null &&
        patch.featured == null;
  }

  static bool _changesPublicationOnly(BulkEventPatch patch) {
    return patch.isActive != null &&
        patch.title == null &&
        patch.startDateTime == null &&
        patch.endDateTime == null &&
        patch.featured == null;
  }
}
