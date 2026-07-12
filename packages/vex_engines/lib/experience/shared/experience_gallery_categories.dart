/// Canonical gallery category values and labels for venue media.
final class ExperienceGalleryCategories {
  ExperienceGalleryCategories._();

  static const values = <String>[
    'cover',
    'interior',
    'drinks',
    'food',
    'events',
    'atmosphere',
    'other',
  ];

  static const publicDisplayLimit = 12;

  static String label(String category) {
    return switch (category) {
      'cover' => 'Cover',
      'interior' => 'Interior',
      'drinks' => 'Drinks',
      'food' => 'Food',
      'events' => 'Events',
      'atmosphere' => 'Atmosphere',
      'all' => 'All',
      _ => 'Other',
    };
  }

  static bool isAllowed(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return values.contains(value.trim().toLowerCase());
  }

  static String normalize(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) return 'other';
    return isAllowed(trimmed) ? trimmed : 'other';
  }
}
