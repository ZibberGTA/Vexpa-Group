import 'package:cloud_firestore/cloud_firestore.dart';

/// Partial update payload for event inline and bulk edits.
class BulkEventPatch {
  const BulkEventPatch({
    this.title,
    this.startDateTime,
    this.endDateTime,
    this.isActive,
    this.featured,
  });

  final String? title;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool? isActive;
  final bool? featured;

  bool get isEmpty =>
      title == null &&
      startDateTime == null &&
      endDateTime == null &&
      isActive == null &&
      featured == null;
}
