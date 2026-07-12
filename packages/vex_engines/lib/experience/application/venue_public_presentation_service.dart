/// Public venue profile presentation — tags, highlights, and preview chips.
final class VenuePublicPresentationService {
  const VenuePublicPresentationService();

  static const _maxHighlights = 6;
  static const _maxPublicTags = 3;
  static const _defaultPreviewTags = ['Live Music', '18+'];

  static const _featureKeyLabels = <String, String>{
    'age18': '18+',
    'age21': '21+',
    'liveMusic': 'Live Music',
    'dj': 'DJ',
    'sports': 'Sports',
    'karaoke': 'Karaoke',
    'quizNight': 'Quiz Night',
    'danceFloor': 'Dance Floor',
    'foodServed': 'Food Served',
    'outdoorSeating': 'Outdoor',
  };

  /// Parses feature tags from Firestore list and venueFeatures map.
  List<String> parseFeatureTags({
    dynamic featureTags,
    dynamic venueFeatures,
    int limit = _maxPublicTags,
  }) {
    final tags = <String>[];

    void addTag(String tag) {
      final cleaned = tag.trim();
      if (cleaned.isEmpty) return;
      if (!tags.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
        tags.add(cleaned);
      }
    }

    if (featureTags is List) {
      for (final tag in featureTags) {
        addTag(tag.toString());
      }
    }

    if (venueFeatures is Map) {
      final map = Map<String, dynamic>.from(venueFeatures);
      for (final entry in _featureKeyLabels.entries) {
        if (map[entry.key] == true) addTag(entry.value);
      }
    }

    return tags.take(limit).toList();
  }

  /// Customer-facing venue tags for details and cards.
  List<String> resolvePublicTags({
    required List<String> featureTags,
    required String venueType,
    required String category,
    int limit = _maxPublicTags,
  }) {
    if (featureTags.isNotEmpty) {
      return featureTags.take(limit).toList();
    }

    final type = venueType.trim().isNotEmpty ? venueType : category;
    final cleaned = type.trim();
    if (cleaned.isEmpty) return const ['Venue'];
    return [cleaned];
  }

  /// Highlight chips for public venue profile surfaces.
  List<String> resolvePublicHighlights({
    required List<String> featureTags,
    required List<String> features,
    required String venueType,
    required String category,
    int limit = _maxHighlights,
  }) {
    final highlights = <String>[];

    void add(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return;
      if (highlights.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
        return;
      }
      highlights.add(cleaned);
    }

    for (final tag in featureTags) {
      add(tag);
      if (highlights.length >= limit) return highlights;
    }

    for (final feature in features) {
      add(feature);
      if (highlights.length >= limit) return highlights;
    }

    if (highlights.isEmpty) {
      add(venueType.isNotEmpty ? venueType : category);
    }

    return highlights.take(limit).toList();
  }

  /// Map preview tags with formatted labels and venue-type fallbacks.
  List<String> venuePreviewTags({
    required List<String> featureTags,
    required String Function(String tag) formatTagLabel,
    int limit = _maxPublicTags,
    List<String> fallbackTags = _defaultPreviewTags,
  }) {
    final selected = featureTags
        .map(formatTagLabel)
        .where((tag) => tag.isNotEmpty)
        .take(limit)
        .toList();

    if (selected.isNotEmpty) return selected;
    return fallbackTags.take(limit).toList();
  }
}
