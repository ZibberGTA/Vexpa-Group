import '../../venues/models/venue_model.dart';
import '../models/venue_profile_completion.dart';

/// Calculates venue profile completion from Firestore venue data.
class VenueProfileCompletionCalculator {
  VenueProfileCompletionCalculator._();

  static VenueProfileCompletion calculate({
    required VenueModel venue,
    required int drinkCount,
  }) {
    var completed = 0;

    if (venue.name.trim().isNotEmpty) completed++;
    if (_hasAddress(venue)) completed++;
    if (venue.category.trim().isNotEmpty || venue.venueType.trim().isNotEmpty) {
      completed++;
    }
    if (venue.logoUrl.trim().isNotEmpty) completed++;
    if (venue.bannerImageUrl.trim().isNotEmpty) completed++;
    if (_hasOpeningHours(venue)) completed++;
    if (venue.featureTags.isNotEmpty || venue.features.isNotEmpty) completed++;
    if (venue.phone.trim().isNotEmpty) completed++;
    if (venue.website.trim().isNotEmpty) completed++;
    if (drinkCount > 0) completed++;

    return VenueProfileCompletion(
      completedSteps: completed,
      totalSteps: VenueProfileCompletion.totalChecklistSteps,
    );
  }

  static bool _hasAddress(VenueModel venue) {
    return venue.address.trim().isNotEmpty ||
        venue.city.trim().isNotEmpty ||
        venue.area.trim().isNotEmpty;
  }

  static bool _hasOpeningHours(VenueModel venue) {
    if (venue.openingHours.isEmpty) return false;
    return venue.openingHours.values.any((value) {
      if (value is Map) {
        return value.values.any((entry) => entry?.toString().trim().isNotEmpty ?? false);
      }
      return value?.toString().trim().isNotEmpty ?? false;
    });
  }
}
