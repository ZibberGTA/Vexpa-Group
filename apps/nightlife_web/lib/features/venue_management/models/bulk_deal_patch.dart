/// Partial update payload for bulk deal edits and inline patches.
class BulkDealPatch {
  const BulkDealPatch({
    this.title,
    this.dealType,
    this.value,
    this.startDateTime,
    this.endDateTime,
    this.isActive,
    this.featured,
  });

  final String? title;
  final String? dealType;
  final String? value;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool? isActive;
  final bool? featured;

  bool get isEmpty =>
      title == null &&
      dealType == null &&
      value == null &&
      startDateTime == null &&
      endDateTime == null &&
      isActive == null &&
      featured == null;
}
