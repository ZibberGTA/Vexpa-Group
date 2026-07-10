import '../shared/experience_search_term_builder.dart';

/// Prepares shared write/update fields for venue-published content.
final class ExperienceUpdatePreparation {
  ExperienceUpdatePreparation._();

  static List<String> searchTermsForValues(List<String> values) =>
      ExperienceSearchTermBuilder.buildFromValues(values);

  static Map<String, dynamic> searchTermsField(List<String> values) => {
        'searchTerms': searchTermsForValues(values),
      };

  static void applySearchTermsIfNeeded({
    required Map<String, dynamic> payload,
    required bool shouldRebuild,
    required List<String> values,
  }) {
    if (!shouldRebuild) return;
    payload.addAll(searchTermsField(values));
  }
}
