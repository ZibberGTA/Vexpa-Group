/// Fixed deal type options for venue-published promotions.
final class ExperienceDealTypes {
  ExperienceDealTypes._();

  static const percentageOff = 'percentage_off';
  static const fixedAmountOff = 'fixed_amount_off';
  static const twoForOne = 'two_for_one';
  static const happyHour = 'happy_hour';
  static const freeItem = 'free_item';
  static const bundleDeal = 'bundle_deal';
  static const other = 'other';

  static const all = [
    percentageOff,
    fixedAmountOff,
    twoForOne,
    happyHour,
    freeItem,
    bundleDeal,
    other,
  ];

  static const displayNames = {
    percentageOff: 'Percentage Off',
    fixedAmountOff: 'Fixed Amount Off',
    twoForOne: '2-for-1',
    happyHour: 'Happy Hour',
    freeItem: 'Free Item',
    bundleDeal: 'Bundle Deal',
    other: 'Other',
  };

  static String displayName(String type) =>
      displayNames[normalize(type)] ?? 'Other';

  static String normalize(String? type) {
    if (type == null || type.trim().isEmpty) return other;
    final trimmed = type.trim();
    if (all.contains(trimmed)) return trimmed;
    final match = displayNames.entries.firstWhere(
      (entry) => entry.value.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => const MapEntry(other, 'Other'),
    );
    return match.key;
  }

  static bool isAllowed(String? type) => all.contains(normalize(type));
}

/// Weekday labels for deal availability multi-select.
final class ExperienceDealWeekdays {
  ExperienceDealWeekdays._();

  static const all = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
