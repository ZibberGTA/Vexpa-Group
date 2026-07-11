import '../domain/analytics_event_type.dart';

/// Validates analytics query inputs before repository calls.
final class AnalyticsEventValidator {
  const AnalyticsEventValidator();

  bool isValidVenueId(String? venueId) => venueId?.trim().isNotEmpty == true;

  bool isValidEventType(String? type) =>
      AnalyticsEventType.parse(type) != null ||
      type == AnalyticsEventType.notificationLead.firestoreValue;

  bool canLogEvent({required String venueId, required String type}) =>
      isValidVenueId(venueId) && type.trim().isNotEmpty;
}
