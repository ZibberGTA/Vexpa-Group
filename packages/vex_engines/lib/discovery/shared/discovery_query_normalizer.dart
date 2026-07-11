/// Shared query normalisation, tokenisation, and alias expansion for discovery.
final class DiscoveryQueryNormalizer {
  DiscoveryQueryNormalizer._();

  static String normalize(String input) => input.toLowerCase().trim();

  static List<String> tokenize(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static List<String> expandAliases(String input) {
    final normalized = normalize(input);
    final variants = <String>{normalized};

    if (normalized == 'whisky') {
      variants.add('whiskey');
    } else if (normalized == 'whiskey') {
      variants.add('whisky');
    }

    return variants.toList();
  }

  static bool matchesAny(String value, List<String> searchVariants) {
    for (final variant in searchVariants) {
      if (value == variant || value.contains(variant)) {
        return true;
      }
    }
    return false;
  }
}
