/// Shared TrailService result types used by UI callers.
class TrailCheckInValidation {
  final bool allowed;
  final double? distanceMeters;
  final String? message;

  const TrailCheckInValidation._({
    required this.allowed,
    this.distanceMeters,
    this.message,
  });

  const TrailCheckInValidation.allowed({double? distanceMeters})
    : this._(allowed: true, distanceMeters: distanceMeters);

  const TrailCheckInValidation.blocked({
    required String message,
    double? distanceMeters,
  }) : this._(allowed: false, distanceMeters: distanceMeters, message: message);
}

class TrailVenueOption {
  final String id;
  final String name;
  final String address;
  final String bannerImageUrl;
  final String logoUrl;

  const TrailVenueOption({
    required this.id,
    required this.name,
    required this.address,
    required this.bannerImageUrl,
    required this.logoUrl,
  });
}
