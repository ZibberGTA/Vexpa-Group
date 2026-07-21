import '../models/venue_management_activity.dart';
import '../models/venue_management_activity_types.dart';
import 'venue_management_activity_service.dart';

/// Canonical venue management activity writes for successful mutations.
abstract final class VenueManagementActivityRecording {
  static Future<void> recordDeal({
    required VenueManagementActivityService service,
    required String venueId,
    required String dealId,
    required String dealTitle,
    required String actorUid,
    required String actionType,
    required String description,
    String? actorDisplayName,
  }) {
    return service.recordActivity(
      VenueManagementActivity(
        venueId: venueId,
        sourceArea: VenueManagementActivitySourceAreas.deals,
        actionType: actionType,
        entityType: VenueManagementActivityEntityTypes.deal,
        entityId: dealId,
        entityName: dealTitle,
        description: description,
        actorUid: actorUid,
        actorDisplayName: actorDisplayName,
      ),
    );
  }

  static Future<void> recordEvent({
    required VenueManagementActivityService service,
    required String venueId,
    required String eventId,
    required String eventTitle,
    required String actorUid,
    required String actionType,
    required String description,
    String? actorDisplayName,
  }) {
    return service.recordActivity(
      VenueManagementActivity(
        venueId: venueId,
        sourceArea: VenueManagementActivitySourceAreas.events,
        actionType: actionType,
        entityType: VenueManagementActivityEntityTypes.event,
        entityId: eventId,
        entityName: eventTitle,
        description: description,
        actorUid: actorUid,
        actorDisplayName: actorDisplayName,
      ),
    );
  }
}
