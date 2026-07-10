import 'venue_opening_hours_entry.dart';
import '../../venues/models/image_position_metadata.dart';
import '../../venues/models/venue_model.dart';

/// UI model for the venue details page shell.
class VenueDetailsView {
  const VenueDetailsView({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.city,
    required this.postcode,
    required this.category,
    required this.venueType,
    required this.rating,
    required this.isOpen,
    required this.tags,
    required this.highlights,
    this.bannerImageUrl,
    this.logoUrl,
    this.bannerImagePosition,
    this.logoImagePosition,
    this.galleryCoverPosition,
    this.phone,
    this.website,
    this.description,
    this.galleryImageUrls = const [],
    this.galleryImages = const [],
    this.openingHours = const [],
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final String city;
  final String postcode;
  final String category;
  final String venueType;
  final double rating;
  final bool isOpen;
  final List<String> tags;
  final List<String> highlights;
  final String? bannerImageUrl;
  final String? logoUrl;
  final ImagePositionMetadata? bannerImagePosition;
  final ImagePositionMetadata? logoImagePosition;
  final ImagePositionMetadata? galleryCoverPosition;
  final String? phone;
  final String? website;
  final String? description;
  final List<String> galleryImageUrls;
  final List<VenueGalleryImageData> galleryImages;
  final List<VenueOpeningHoursEntry> openingHours;
  final double? latitude;
  final double? longitude;

  String get locationLabel {
    if (area.isNotEmpty && city.isNotEmpty) return '$area, $city';
    if (address.isNotEmpty) return address;
    if (city.isNotEmpty) return city;
    return area;
  }

  String get displayCategory =>
      venueType.trim().isNotEmpty ? venueType : category;

  String get displayAddress =>
      address.trim().isNotEmpty ? address : locationLabel;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  bool get hasWebsite => website != null && website!.trim().isNotEmpty;

  bool get hasOpeningHours => openingHours.isNotEmpty;

  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;

  bool get hasGallery => galleryImageUrls.isNotEmpty;

  String? get galleryCoverImageUrl {
    for (final image in galleryImages) {
      if (image.isCover && image.imageUrl.trim().isNotEmpty) {
        return image.imageUrl;
      }
    }
    return galleryImageUrls.isNotEmpty ? galleryImageUrls.first : null;
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  VenueOpeningHoursEntry? get todayOpeningHours {
    for (final entry in openingHours) {
      if (entry.isToday) return entry;
    }
    return null;
  }

  String get todayHoursLabel {
    final today = todayOpeningHours;
    if (today == null) return 'Hours unavailable';
    return today.hoursLabel;
  }

  String get overviewDescription {
    if (hasDescription) return description!.trim();
    return 'Discover ${name.trim().isNotEmpty ? name : 'this venue'} on Vexda — '
        'explore drinks, deals, events and everything happening tonight.';
  }
}
