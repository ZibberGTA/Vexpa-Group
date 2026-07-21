/// Venue facts supplied by application adapters for check-in assessment.
final class TrailVenuePresence {
  const TrailVenuePresence({
    required this.venueId,
    this.latitude,
    this.longitude,
    this.presenceRadiusMeters,
  });

  final String venueId;
  final double? latitude;
  final double? longitude;
  final double? presenceRadiusMeters;
}

/// Lookup port for venue location/radius (no Firebase in engine).
abstract interface class TrailVenueLookupPort {
  Future<TrailVenuePresence?> lookup(String venueId);
}
