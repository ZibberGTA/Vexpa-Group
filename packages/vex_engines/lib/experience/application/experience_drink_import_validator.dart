import '../domain/experience_drink_import.dart';
import '../shared/experience_drink_categories.dart';
import 'experience_drink_validator.dart';

/// Validates drink bulk-import rows and parses spreadsheet cell values.
final class ExperienceDrinkImportValidator {
  const ExperienceDrinkImportValidator();

  static const requiredColumns = [
    'name',
    'category',
    'price',
    'available',
    'featured',
  ];

  static ExperienceDrinkImportRow validateRow({
    required int rowNumber,
    required String name,
    required String category,
    required String priceRaw,
    required String availableRaw,
    required String featuredRaw,
    required Set<String> existingDrinkNames,
    required bool Function(String category) isAllowedCategory,
  }) {
    final parsedAvailable = parseOptionalBoolean(availableRaw);
    final parsedFeatured = parseOptionalBoolean(featuredRaw);
    final parsedPrice = parseOptionalPrice(priceRaw);

    final available = parsedAvailable ?? true;
    final featured = parsedFeatured ?? false;

    var status = ExperienceDrinkImportRowStatus.ready;
    var isBlocking = false;
    var isDuplicate = false;

    if (name.trim().isEmpty) {
      status = ExperienceDrinkImportRowStatus.missingName;
      isBlocking = true;
    } else if (category.trim().isEmpty || !isAllowedCategory(category)) {
      status = ExperienceDrinkImportRowStatus.invalidCategory;
      isBlocking = true;
    } else if (parsedPrice == null && priceRaw.trim().isNotEmpty) {
      status = ExperienceDrinkImportRowStatus.invalidPrice;
      isBlocking = true;
    } else if (availableRaw.trim().isNotEmpty && parsedAvailable == null) {
      status = ExperienceDrinkImportRowStatus.invalidAvailable;
      isBlocking = true;
    } else if (featuredRaw.trim().isNotEmpty && parsedFeatured == null) {
      status = ExperienceDrinkImportRowStatus.invalidFeatured;
      isBlocking = true;
    } else if (existingDrinkNames.contains(name.trim().toLowerCase())) {
      status = ExperienceDrinkImportRowStatus.possibleDuplicate;
      isDuplicate = true;
    }

    return ExperienceDrinkImportRow(
      rowNumber: rowNumber,
      name: name,
      category: category,
      priceRaw: priceRaw,
      availableRaw: availableRaw,
      featuredRaw: featuredRaw,
      price: parsedPrice,
      available: available,
      featured: featured,
      status: status,
      statusLabel: statusLabel(status),
      isBlocking: isBlocking,
      isDuplicateWarning: isDuplicate,
    );
  }

  static List<ExperienceDrinkImportCommitRow> rowsToCommit({
    required List<ExperienceDrinkImportRow> rows,
    required bool includeDuplicates,
  }) {
    return rows
        .where((row) {
          if (row.isBlocking) return false;
          if (row.isDuplicateWarning) return includeDuplicates;
          return true;
        })
        .map(
          (row) => ExperienceDrinkImportCommitRow(
            name: row.name.trim(),
            category: row.category.trim(),
            price: row.price,
            available: row.available,
            featured: row.featured,
          ),
        )
        .toList();
  }

  static String? validatePresetDrinkPrice(String? priceText) =>
      ExperienceDrinkValidator.validatePrice(priceText);

  static double? parsePresetDrinkPrice(String? priceText) {
    final error = validatePresetDrinkPrice(priceText);
    if (error != null) return null;
    final trimmed = priceText?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll('£', '').replaceAll(',', '');
    return double.tryParse(normalized);
  }

  static bool isDuplicateName({
    required String name,
    required Set<String> existingDrinkNamesLowercase,
  }) =>
      existingDrinkNamesLowercase.contains(name.trim().toLowerCase());

  static String normalizeDrinkNameKey(String name) => name.trim().toLowerCase();

  static String statusLabel(ExperienceDrinkImportRowStatus status) {
    return switch (status) {
      ExperienceDrinkImportRowStatus.ready => 'Ready',
      ExperienceDrinkImportRowStatus.missingName => 'Missing name',
      ExperienceDrinkImportRowStatus.invalidCategory => 'Invalid category',
      ExperienceDrinkImportRowStatus.invalidPrice => 'Invalid price',
      ExperienceDrinkImportRowStatus.invalidAvailable => 'Invalid available',
      ExperienceDrinkImportRowStatus.invalidFeatured => 'Invalid featured',
      ExperienceDrinkImportRowStatus.possibleDuplicate => 'Possible duplicate',
    };
  }

  static double? parseOptionalPrice(String raw) {
    final trimmed = raw.trim().replaceAll('£', '').replaceAll(',', '');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static bool? parseOptionalBoolean(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    if (const {'true', 'yes', 'y', '1'}.contains(value)) return true;
    if (const {'false', 'no', 'n', '0'}.contains(value)) return false;
    return null;
  }

  static bool isAllowedCategory(String category) =>
      ExperienceDrinkCategories.isAllowed(category);
}
