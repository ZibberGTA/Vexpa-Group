class SearchTermBuilder {
  static List<String> build({
    required String venueName,
    required String category,
    String address = '',
    String description = '',
    List<String> drinks = const [],
    List<String> deals = const [],
    List<String> events = const [],
  }) {
    final raw = <String>[
      venueName,
      category,
      address,
      description,
      ...drinks,
      ...deals,
      ...events,
    ];

    final terms = <String>{};

    for (final item in raw) {
      final normalized = item.toLowerCase().trim();
      if (normalized.isEmpty) continue;

      terms.add(normalized);

      final parts = normalized.split(RegExp(r'[\s\-/_,.&]+'));
      for (final part in parts) {
        final cleaned = part.trim();
        if (cleaned.isNotEmpty) {
          terms.add(cleaned);
        }
      }
    }

    if (terms.contains('whisky')) terms.add('whiskey');
    if (terms.contains('whiskey')) terms.add('whisky');

    return terms.toList()..sort();
  }
}