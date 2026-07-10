/// Validates venue drink form input for management surfaces.
final class ExperienceDrinkValidator {
  ExperienceDrinkValidator._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a drink name.';
    }
    return null;
  }

  static String? validateCategory(
    String? value, {
    required bool Function(String category) isAllowed,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Select a category.';
    }
    if (!isAllowed(value)) {
      return 'Select a category from the list.';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final normalized = trimmed.replaceAll('£', '').replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid price.';
    }
    return null;
  }
}
