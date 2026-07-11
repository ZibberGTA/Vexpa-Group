import '../shared/experience_deal_types.dart';

/// Validates venue deal form input for management surfaces.
final class ExperienceDealValidator {
  ExperienceDealValidator._();

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deal title is required.';
    }
    return null;
  }

  static String? validateDealType(String? value) {
    if (value == null || !ExperienceDealTypes.isAllowed(value)) {
      return 'Deal type is required.';
    }
    return null;
  }

  static String? validateValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim().replaceAll('£', '');
    if (trimmed.contains('%')) return null;
    if (double.tryParse(trimmed) != null) return null;
    if (trimmed.toLowerCase().contains('for')) return null;
    return 'Enter a valid value (e.g. 20, £5, 2-for-1).';
  }

  static String? validateStartDate(DateTime? value) {
    if (value == null) return 'Start date is required.';
    return null;
  }

  static String? validateEndDate(DateTime? start, DateTime? end) {
    if (end == null) return 'End date is required.';
    if (start != null && !end.isAfter(start)) {
      return 'End date must be after start date.';
    }
    return null;
  }
}
