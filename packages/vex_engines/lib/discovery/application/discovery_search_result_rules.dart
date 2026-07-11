/// Platform-independent search result enrichment rules for venue cards.
final class DiscoverySearchResultRules {
  DiscoverySearchResultRules._();

  static const double defaultRating = 4.5;

  static double resolveRating(double averageRating) {
    return averageRating > 0 ? averageRating : defaultRating;
  }

  static List<String> tagsFromCategory(String category) {
    final cleaned = category.trim();
    if (cleaned.isEmpty) return const ['Venue'];
    return [cleaned];
  }

  static List<String> resolveTags({
    required List<String> featureTags,
    required String venueType,
    required String category,
  }) {
    if (featureTags.isNotEmpty) {
      return featureTags.take(3).toList();
    }

    final type = venueType.trim().isNotEmpty ? venueType : category;
    return tagsFromCategory(type);
  }

  static String resultReasonFor({
    required bool hasDeals,
    required List<String> featureTags,
    required String venueType,
    required String category,
  }) {
    if (hasDeals) return 'Happy Hour active';
    if (featureTags.isNotEmpty) return featureTags.first;

    final type = venueType.trim();
    if (type.isNotEmpty) return type;

    final cleanedCategory = category.trim();
    if (cleanedCategory.isNotEmpty) return cleanedCategory;

    return 'Open until late';
  }
}
