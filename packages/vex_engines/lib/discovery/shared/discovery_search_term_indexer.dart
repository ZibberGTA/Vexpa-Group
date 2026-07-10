/// Builds Firestore-friendly search term sets from text fields.
final class DiscoverySearchTermIndexer {
  DiscoverySearchTermIndexer._();

  static void addText(Set<String> terms, dynamic value) {
    if (value == null) return;

    final text = value.toString().toLowerCase().trim();
    if (text.isEmpty) return;

    terms.add(text);

    final words = text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    terms.addAll(words);

    for (var i = 0; i < words.length - 1; i++) {
      terms.add('${words[i]} ${words[i + 1]}');
    }

    for (var i = 0; i < words.length - 2; i++) {
      terms.add('${words[i]} ${words[i + 1]} ${words[i + 2]}');
    }
  }

  static void addList(Set<String> terms, dynamic list) {
    if (list is List) {
      for (final item in list) {
        addText(terms, item);
      }
    }
  }

  static void addDealKeywords(Set<String> terms) {
    terms.addAll([
      'deal',
      'deals',
      'offer',
      'offers',
      'discount',
      'happy',
      'hour',
      'happy hour',
    ]);
  }
}
