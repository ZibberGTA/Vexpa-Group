import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/models/deal_model.dart';

/// Read-only consumer catalog counts for saved venue cards.
class ConsumerVenueCatalogService {
  ConsumerVenueCatalogService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, int>> loadLiveCountsForVenue(String venueId) async {
    if (venueId.trim().isEmpty) {
      return const {'events': 0, 'deals': 0};
    }

    try {
      final now = DateTime.now();

      final events = await _db
          .collection('events')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .limit(50)
          .get();

      final activeEventCount = events.docs.where((doc) {
        final data = doc.data();
        final endTimestamp = data['endDateTime'] as Timestamp?;
        final startTimestamp = data['startDateTime'] as Timestamp? ??
            data['dateTime'] as Timestamp?;
        final endDate = endTimestamp?.toDate() ??
            (startTimestamp == null
                ? null
                : startTimestamp.toDate().add(const Duration(hours: 24)));
        return endDate != null && endDate.isAfter(now);
      }).length;

      final deals = await _db
          .collection('deals')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();

      final activeDealCount = deals.docs
          .map((doc) => DealModel.fromMap(doc.id, doc.data()))
          .where((deal) => deal.isCurrentlyVisible)
          .length;

      return {
        'events': activeEventCount,
        'deals': activeDealCount,
      };
    } on Object {
      return const {'events': 0, 'deals': 0};
    }
  }
}
