import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/vexda_firebase.dart';

/// Lightweight activity counts for the venue profile visibility checklist.
class VenueProfileActivityCounts {
  const VenueProfileActivityCounts({
    this.dealCount = 0,
    this.eventCount = 0,
  });

  final int dealCount;
  final int eventCount;

  static const empty = VenueProfileActivityCounts();
}

Future<VenueProfileActivityCounts> loadVenueProfileActivityCounts(
  String venueId,
) async {
  if (!VexdaFirebase.isReady || venueId.trim().isEmpty) {
    return VenueProfileActivityCounts.empty;
  }

  final db = FirebaseFirestore.instance;
  final dealCount = await _countCollection(
    db: db,
    collection: 'deals',
    venueId: venueId,
  );
  final eventCount = await _countCollection(
    db: db,
    collection: 'events',
    venueId: venueId,
  );

  return VenueProfileActivityCounts(
    dealCount: dealCount,
    eventCount: eventCount,
  );
}

Future<int> _countCollection({
  required FirebaseFirestore db,
  required String collection,
  required String venueId,
}) async {
  try {
    final snapshot = await db
        .collection(collection)
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  } on FirebaseException {
    return 0;
  }
}
