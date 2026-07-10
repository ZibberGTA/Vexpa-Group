/// Builds Firestore `searchTerms` arrays for venue-published content writes.
final class ExperienceSearchTermBuilder {
  ExperienceSearchTermBuilder._();

  /// Prefix-indexes trimmed lowercase values for array-contains discovery queries.
  static List<String> buildFromValues(List<String> values) {
    final terms = <String>{};

    for (final value in values) {
      final cleanValue = value.trim().toLowerCase();
      if (cleanValue.isEmpty) continue;

      terms.add(cleanValue);

      final words = cleanValue.split(RegExp(r'[^a-z0-9]+'));
      for (final word in words) {
        if (word.isEmpty) continue;
        terms.add(word);
        for (var i = 1; i <= word.length; i++) {
          terms.add(word.substring(0, i));
        }
      }
    }

    return terms.take(100).toList();
  }
}
