/// Admin CRM venue health checklist item.
final class VenueAdminHealthItem {
  const VenueAdminHealthItem({required this.label, required this.passed});

  final String label;
  final bool passed;
}

/// Admin CRM venue health score derived from profile + content signals.
final class VenueAdminHealth {
  const VenueAdminHealth({
    required this.scorePercent,
    required this.passedCount,
    required this.totalCount,
    required this.items,
  });

  final int scorePercent;
  final int passedCount;
  final int totalCount;
  final List<VenueAdminHealthItem> items;

  List<VenueAdminHealthItem> get missingItems =>
      items.where((item) => !item.passed).toList(growable: false);

  List<VenueAdminHealthItem> get passedItems =>
      items.where((item) => item.passed).toList(growable: false);

  bool get isComplete => missingItems.isEmpty && totalCount > 0;
}

/// Presentation tier for admin health score accents (no Flutter types).
enum VenueHealthAccentTier {
  strong,
  moderate,
  weak,
}
