import '../domain/venue_profile_completion.dart';
import '../domain/venue_profile_completion_input.dart';

/// Calculates venue profile completion from engine-neutral profile fields.
final class VenueProfileCompletionCalculator {
  VenueProfileCompletionCalculator._();

  static VenueProfileCompletion calculate(VenueProfileCompletionInput input) {
    var completed = 0;

    if (input.name.trim().isNotEmpty) completed++;
    if (_hasAddress(input)) completed++;
    if (input.category.trim().isNotEmpty || input.venueType.trim().isNotEmpty) {
      completed++;
    }
    if (input.logoUrl.trim().isNotEmpty) completed++;
    if (input.bannerImageUrl.trim().isNotEmpty) completed++;
    if (_hasOpeningHours(input.openingHours)) completed++;
    if (input.featureTags.isNotEmpty || input.features.isNotEmpty) {
      completed++;
    }
    if (input.phone.trim().isNotEmpty) completed++;
    if (input.website.trim().isNotEmpty) completed++;
    if (input.drinkCount > 0) completed++;

    return VenueProfileCompletion(
      completedSteps: completed,
      totalSteps: VenueProfileCompletion.totalChecklistSteps,
    );
  }

  static bool _hasAddress(VenueProfileCompletionInput input) {
    return input.address.trim().isNotEmpty ||
        input.city.trim().isNotEmpty ||
        input.area.trim().isNotEmpty;
  }

  static bool _hasOpeningHours(Map<String, dynamic> openingHours) {
    if (openingHours.isEmpty) return false;
    return openingHours.values.any((value) {
      if (value is Map) {
        return value.values.any(
          (entry) => entry?.toString().trim().isNotEmpty ?? false,
        );
      }
      return value?.toString().trim().isNotEmpty ?? false;
    });
  }
}
