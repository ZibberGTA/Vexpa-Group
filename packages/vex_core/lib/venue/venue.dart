/// Crop / focal-point metadata for venue branding images.
final class VenueImagePosition {
  const VenueImagePosition({
    this.focalPointX = 0.5,
    this.focalPointY = 0.5,
    this.scale = 1,
    this.cropX = 0.5,
    this.cropY = 0.5,
    this.aspectRatio,
  });

  final double focalPointX;
  final double focalPointY;
  final double scale;
  final double cropX;
  final double cropY;
  final double? aspectRatio;
}

/// Firebase-free venue entity used by discovery data contracts.
final class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.city,
    this.postcode = '',
    required this.category,
    required this.venueType,
    required this.crowdLevel,
    this.hasDeals = false,
    this.searchTerms = const [],
    this.latitude,
    this.longitude,
    this.bannerImageUrl = '',
    this.logoUrl = '',
    this.bannerImagePosition,
    this.logoImagePosition,
    this.featureTags = const [],
    this.averageRating = 0,
    this.openingHours = const {},
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final String city;
  final String postcode;
  final String category;
  final String venueType;
  final String crowdLevel;
  final bool hasDeals;
  final List<String> searchTerms;
  final double? latitude;
  final double? longitude;
  final String bannerImageUrl;
  final String logoUrl;
  final VenueImagePosition? bannerImagePosition;
  final VenueImagePosition? logoImagePosition;
  final List<String> featureTags;
  final double averageRating;
  final Map<String, dynamic> openingHours;

  bool get hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }
}

/// Sorted public venue catalog returned by [VenueDataService].
final class VenueCatalog {
  const VenueCatalog({required this.venues});

  final List<Venue> venues;
}

/// Venue identifiers matched by discovery search terms.
final class VenueSearchMatch {
  const VenueSearchMatch({required this.venueIds});

  final Set<String> venueIds;
}
