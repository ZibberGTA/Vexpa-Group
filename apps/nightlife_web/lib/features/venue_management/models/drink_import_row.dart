/// Parsed row from a drinks bulk import spreadsheet.
class DrinkImportRow {
  const DrinkImportRow({
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
  final DrinkImportRowStatus status;
  final String statusLabel;
  final bool isBlocking;
  final bool isDuplicateWarning;
}

enum DrinkImportRowStatus {
  ready,
  missingName,
  invalidCategory,
  invalidPrice,
  invalidAvailable,
  invalidFeatured,
  possibleDuplicate,
}

class DrinkImportParseResult {
  const DrinkImportParseResult({
    required this.rows,
    this.fileError,
  });

  final List<DrinkImportRow> rows;
  final String? fileError;

  bool get hasFileError => fileError != null;
  bool get hasBlockingErrors => rows.any((row) => row.isBlocking);
  bool get hasDuplicateWarnings => rows.any((row) => row.isDuplicateWarning);
  int get importableCount => rows.where((row) => !row.isBlocking).length;
}

class DrinkImportCommitRow {
  const DrinkImportCommitRow({
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
