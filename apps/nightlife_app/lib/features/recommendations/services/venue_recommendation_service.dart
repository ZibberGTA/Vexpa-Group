import 'package:cloud_firestore/cloud_firestore.dart';

import '../../crowd/utils/crowd_decay.dart';
import '../../home/models/deal_model.dart';
import '../../home/models/event_model.dart';
import '../../home/models/venue_model.dart';

class VenueRecommendation {
  final VenueModel venue;
  final int score;
  final String reason;

  const VenueRecommendation({
    required this.venue,
    required this.score,
    required this.reason,
  });
}

class VenueRecommendationService {
  VenueRecommendationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<VenueRecommendation>> recommendedNow({int limit = 6}) {
    return _db
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final recommendations = <VenueRecommendation>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final venue = VenueModel.fromMap(doc.id, data);
        var score = 0;
        final reasons = <String>[];

        final crowd = CrowdDecay.displayLevel(
          level: venue.crowdLevel,
          updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
        ).toLowerCase();

        if (crowd == 'packed') {
          score += 35;
          reasons.add('packed now');
        } else if (crowd == 'busy') {
          score += 25;
          reasons.add('busy now');
        } else if (crowd == 'medium' || crowd == 'steady' || crowd == 'lively') {
          score += 12;
          reasons.add('good atmosphere');
        }

        final dealSnapshot = await _db
            .collection('deals')
            .where('venueId', isEqualTo: venue.id)
            .where('isDeleted', isEqualTo: false)
            .where('isActive', isEqualTo: true)
            .limit(10)
            .get();

        final activeDeals = dealSnapshot.docs
            .map((dealDoc) => DealModel.fromMap(dealDoc.id, dealDoc.data()))
            .where((deal) => deal.isCurrentlyVisible)
            .toList();

        if (activeDeals.isNotEmpty) {
          score += activeDeals.length * 15;
          reasons.add('${activeDeals.length} active deal${activeDeals.length == 1 ? '' : 's'}');
        }

        final now = DateTime.now();
        final eventSnapshot = await _db
            .collection('events')
            .where('venueId', isEqualTo: venue.id)
            .where('isDeleted', isEqualTo: false)
            .limit(10)
            .get();

        final upcomingEvents = eventSnapshot.docs
            .map((eventDoc) => EventModel.fromDoc(eventDoc))
            .where((event) => event.endDateTime.isAfter(now))
            .toList();

        if (upcomingEvents.isNotEmpty) {
          score += upcomingEvents.length * 20;
          reasons.add('${upcomingEvents.length} upcoming event${upcomingEvents.length == 1 ? '' : 's'}');
        }

        if (venue.hasDeals) score += 5;

        if (score > 0) {
          recommendations.add(VenueRecommendation(
            venue: venue,
            score: score,
            reason: reasons.take(2).join(' • '),
          ));
        }
      }

      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations.take(limit).toList();
    });
  }
}
