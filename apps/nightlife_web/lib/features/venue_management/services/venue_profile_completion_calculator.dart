import 'package:vex_engines/venue/application/venue_profile_completion_calculator.dart'
    as engine;
import 'package:vex_engines/venue/domain/venue_profile_completion.dart';
import 'package:vex_engines/venue/domain/venue_profile_completion_input.dart';

import '../../venues/models/venue_model.dart';

export 'package:vex_engines/venue/domain/venue_profile_completion.dart';

/// Calculates venue profile completion from Firestore venue data.
class VenueProfileCompletionCalculator {
  VenueProfileCompletionCalculator._();

  static VenueProfileCompletion calculate({
    required VenueModel venue,
    required int drinkCount,
  }) {
    return engine.VenueProfileCompletionCalculator.calculate(
      VenueProfileCompletionInput(
        name: venue.name,
        address: venue.address,
        city: venue.city,
        area: venue.area,
        category: venue.category,
        venueType: venue.venueType,
        logoUrl: venue.logoUrl,
        bannerImageUrl: venue.bannerImageUrl,
        openingHours: venue.openingHours,
        featureTags: venue.featureTags,
        features: venue.features,
        phone: venue.phone,
        website: venue.website,
        drinkCount: drinkCount,
      ),
    );
  }
}
