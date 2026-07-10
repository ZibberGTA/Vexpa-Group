/// Shared text helpers for discovery search queries.
class SearchTextUtils {
  SearchTextUtils._();

  static String normalise(String value) => value.trim().toLowerCase();

  static bool containsQuery(dynamic value, String query) {
    if (query.isEmpty) return true;
    if (value == null) return false;

    if (value is Iterable) {
      return value.any((item) => containsQuery(item, query));
    }

    return value.toString().toLowerCase().contains(query);
  }

  static String formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '';

    if (rawPrice is num) {
      return '£${rawPrice.toStringAsFixed(2)}';
    }

    final value = rawPrice.toString().trim();
    if (value.isEmpty) return '';
    return value.startsWith('£') ? value : '£$value';
  }

  static List<String> termsFromQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.isNotEmpty)
        .take(10)
        .toList();
  }
}
