import 'package:vex_core/vex_core.dart';

import '../../features/venues/models/image_position_metadata.dart';
import '../../features/venues/models/venue_model.dart';

Venue vexVenueFromVenueModel(VenueModel model) {
  return Venue(
    id: model.id,
    name: model.name,
    address: model.address,
    area: model.area,
    city: model.city,
    postcode: model.postcode,
    category: model.category,
    venueType: model.venueType,
    crowdLevel: model.crowdLevel,
    hasDeals: model.hasDeals,
    searchTerms: model.searchTerms,
    latitude: model.latitude ?? model.location?.latitude,
    longitude: model.longitude ?? model.location?.longitude,
    bannerImageUrl: model.bannerImageUrl,
    logoUrl: model.logoUrl,
    bannerImagePosition: _mapImagePosition(model.bannerImagePosition),
    logoImagePosition: _mapImagePosition(model.logoImagePosition),
    featureTags: model.featureTags,
    averageRating: model.averageRating,
    openingHours: model.openingHours,
  );
}

VenueModel venueModelFromVexVenue(Venue venue) {
  return VenueModel(
    id: venue.id,
    name: venue.name,
    address: venue.address,
    area: venue.area,
    city: venue.city,
    postcode: venue.postcode,
    category: venue.category,
    venueType: venue.venueType,
    crowdLevel: venue.crowdLevel,
    hasDeals: venue.hasDeals,
    searchTerms: venue.searchTerms,
    latitude: venue.latitude,
    longitude: venue.longitude,
    bannerImageUrl: venue.bannerImageUrl,
    logoUrl: venue.logoUrl,
    bannerImagePosition: _mapToAppImagePosition(venue.bannerImagePosition),
    logoImagePosition: _mapToAppImagePosition(venue.logoImagePosition),
    featureTags: venue.featureTags,
    averageRating: venue.averageRating,
    openingHours: venue.openingHours,
  );
}

VenueImagePosition? _mapImagePosition(ImagePositionMetadata? position) {
  if (position == null) return null;
  return VenueImagePosition(
    focalPointX: position.focalPointX,
    focalPointY: position.focalPointY,
    scale: position.scale,
    cropX: position.cropX,
    cropY: position.cropY,
    aspectRatio: position.aspectRatio,
  );
}

ImagePositionMetadata? _mapToAppImagePosition(VenueImagePosition? position) {
  if (position == null) return null;
  return ImagePositionMetadata(
    focalPointX: position.focalPointX,
    focalPointY: position.focalPointY,
    scale: position.scale,
    cropX: position.cropX,
    cropY: position.cropY,
    aspectRatio: position.aspectRatio,
  );
}
