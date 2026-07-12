/// Drink bulk-import row validation result from Experience Engine.
enum ExperienceDrinkImportRowStatus {
  ready,
  missingName,
  invalidCategory,
  invalidPrice,
  invalidAvailable,
  invalidFeatured,
  possibleDuplicate,
}

/// Validated drink import row — Firebase-free.
final class ExperienceDrinkImportRow {
  const ExperienceDrinkImportRow({
    required this.rowNumber,
    required this.name,
    required this.category,
    required this.priceRaw,
    required this.availableRaw,
    required this.featuredRaw,
    required this.price,
    required this.available,
    required this.featured,
    required this.status,
    required this.statusLabel,
    required this.isBlocking,
    required this.isDuplicateWarning,
  });

  final int rowNumber;
  final String name;
  final String category;
  final String priceRaw;
  final String availableRaw;
  final String featuredRaw;
  final double? price;
  final bool available;
  final bool featured;
  final ExperienceDrinkImportRowStatus status;
  final String statusLabel;
  final bool isBlocking;
  final bool isDuplicateWarning;
}

/// Rows eligible for commit after import validation.
final class ExperienceDrinkImportCommitRow {
  const ExperienceDrinkImportCommitRow({
    required this.name,
    required this.category,
    required this.price,
    required this.available,
    required this.featured,
  });

  final String name;
  final String category;
  final double? price;
  final bool available;
  final bool featured;
}
