import '../../venues/models/venue_model.dart';

/// Builds venue highlight chips from Firestore venue fields.
class VenueHighlightsMapper {
  VenueHighlightsMapper._();

  static const _maxHighlights = 6;

  static List<String> fromVenueModel(VenueModel venue) {
    final highlights = <String>[];

    void add(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return;
      if (highlights.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
        return;
      }
      highlights.add(cleaned);
    }

    for (final tag in venue.featureTags) {
      add(tag);
      if (highlights.length >= _maxHighlights) return highlights;
    }

    for (final feature in venue.features) {
      add(feature);
      if (highlights.length >= _maxHighlights) return highlights;
    }

    if (highlights.isEmpty) {
      add(venue.venueType.isNotEmpty ? venue.venueType : venue.category);
    }

    return highlights.take(_maxHighlights).toList();
  }
}
