/// Venue participation application settings on a trail.
final class TrailParticipationSettings {
  const TrailParticipationSettings({
    this.acceptsVenueApplications = false,
    this.participationApplicationOpensAt,
    this.participationApplicationClosesAt,
    this.maximumStops,
    this.venueSelectableStopPosition = true,
    this.participationInstructions = '',
  });

  final bool acceptsVenueApplications;
  final DateTime? participationApplicationOpensAt;
  final DateTime? participationApplicationClosesAt;
  final int? maximumStops;
  final bool venueSelectableStopPosition;
  final String participationInstructions;
}
