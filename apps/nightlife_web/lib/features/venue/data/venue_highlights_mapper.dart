import 'package:vex_engines/experience/application/venue_public_presentation_service.dart';

import '../../venues/models/venue_model.dart';

/// Builds venue highlight chips from Firestore venue fields.
class VenueHighlightsMapper {
  VenueHighlightsMapper._();

  static const _publicPresentation = VenuePublicPresentationService();

  static List<String> fromVenueModel(VenueModel venue) {
    return _publicPresentation.resolvePublicHighlights(
      featureTags: venue.featureTags,
      features: venue.features,
      venueType: venue.venueType,
      category: venue.category,
    );
  }
}
