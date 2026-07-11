import 'vex_event.dart';

/// Venue profile write completed in an app adapter.
final class VenueProfileUpdatedEvent extends VexEvent {
  VenueProfileUpdatedEvent({
    required this.venueId,
    required this.updatedByUid,
    String? id,
    DateTime? occurredAt,
  }) : super(
          id: id ??
              'venue-profile-updated-$venueId-${DateTime.now().microsecondsSinceEpoch}',
          occurredAt: occurredAt ?? DateTime.now(),
        );

  final String venueId;
  final String updatedByUid;

  @override
  String get type => 'venue.profile.updated';
}

/// Claim submitted or reviewed in the Claim Engine runtime.
final class ClaimLifecycleEvent extends VexEvent {
  ClaimLifecycleEvent({
    required this.claimId,
    required this.venueId,
    required this.action,
    String? id,
    DateTime? occurredAt,
  }) : super(
          id: id ?? 'claim-$action-$claimId',
          occurredAt: occurredAt ?? DateTime.now(),
        );

  final String claimId;
  final String venueId;

  /// One of: submitted, approved, rejected, assigned.
  final String action;

  @override
  String get type => 'claim.lifecycle.$action';
}

/// Analytics event persisted by an app adapter.
final class AnalyticsEventRecorded extends VexEvent {
  AnalyticsEventRecorded({
    required this.venueId,
    required this.eventType,
    String? id,
    DateTime? occurredAt,
  }) : super(
          id: id ??
              'analytics-$eventType-$venueId-${DateTime.now().microsecondsSinceEpoch}',
          occurredAt: occurredAt ?? DateTime.now(),
        );

  final String venueId;
  final String eventType;

  @override
  String get type => 'analytics.event.recorded';
}
