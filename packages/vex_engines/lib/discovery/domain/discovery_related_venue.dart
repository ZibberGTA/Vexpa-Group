/// Venue subject used for related-venue scoring.
final class DiscoveryRelatedVenueSubject {
  const DiscoveryRelatedVenueSubject({
    required this.id,
    required this.category,
    required this.city,
    this.tags = const [],
    this.latitude,
    this.longitude,
  });

  final String id;
  final String category;
  final String city;
  final List<String> tags;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Candidate venue fields used for related-venue scoring.
abstract interface class DiscoveryRelatedVenueCandidate {
  String get id;

  String get venueType;

  String get city;

  List<String> get tags;

  double get latitude;

  double get longitude;
}
