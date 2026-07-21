import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

import '../../search/data/search_venue_open_status.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_details_view.dart';
import 'venue_highlights_mapper.dart';
import 'venue_opening_hours_formatter.dart';

/// Maps Firestore venue documents to venue details UI models.
class VenueDetailsMapper {
  VenueDetailsMapper._();

  static VenueDetailsView fromVenueModel(VenueModel venue) {
    final openStatus = SearchVenueOpenStatus.fromOpeningHours(
      venue.openingHours,
    );
    final bannerUrl = venue.bannerImageUrl.trim();
    final logoUrl = venue.logoUrl.trim();
    final galleryCoverUrl = venue.galleryImages
        .where((image) => image.isCover && image.imageUrl.trim().isNotEmpty)
        .map((image) => image.imageUrl.trim())
        .firstOrNull;

    final phone = venue.phone.trim();
    final website = venue.website.trim();
    final description = venue.description.trim();
    final tags = VenueProfileFieldCodec.displayFeatureTags(
      featureTags: venue.featureTags,
      features: venue.features,
    );

    return VenueDetailsView(
      id: venue.id,
      name: venue.name,
      address: venue.address,
      area: venue.area,
      city: venue.city,
      postcode: venue.postcode,
      category: venue.category,
      venueType: venue.venueType,
      rating: venue.averageRating,
      isOpen: openStatus.isOpen,
      tags: tags,
      highlights: VenueHighlightsMapper.fromVenueModel(venue),
      bannerImageUrl:
          galleryCoverUrl ?? (bannerUrl.isNotEmpty ? bannerUrl : null),
      logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
      bannerImagePosition: galleryCoverUrl == null
          ? venue.bannerImagePosition
          : venue.galleryImagePositions['0'] ??
                venue.galleryImagePositions[galleryCoverUrl],
      logoImagePosition: venue.logoImagePosition,
      galleryCoverPosition:
          venue.galleryImagePositions['0'] ??
          (venue.galleryImageUrls.isNotEmpty
              ? venue.galleryImagePositions[venue.galleryImageUrls.first]
              : null),
      phone: phone.isNotEmpty ? phone : null,
      website: website.isNotEmpty ? website : null,
      description: description.isNotEmpty ? description : null,
      galleryImageUrls: venue.galleryImageUrls,
      galleryImages: venue.galleryImages,
      openingHours: VenueOpeningHoursFormatter.fromMap(venue.openingHours),
      latitude: venue.latitude,
      longitude: venue.longitude,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
