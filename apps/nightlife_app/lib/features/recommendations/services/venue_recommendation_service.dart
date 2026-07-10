import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/application/discovery_recommendation_scorer.dart';
import 'package:vex_engines/discovery/domain/discovery_recommendation.dart';

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

  static const _scorer = DiscoveryRecommendationScorer();
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

        final crowd = CrowdDecay.displayLevel(
          level: venue.crowdLevel,
          updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
        ).toLowerCase();

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

        final scored = _scorer.score(
          RecommendationScoreInput(
            crowdLevel: crowd,
            activeDealCount: activeDeals.length,
            upcomingEventCount: upcomingEvents.length,
            hasDealsFlag: venue.hasDeals,
          ),
        );

        if (scored.isEligible) {
          recommendations.add(
            VenueRecommendation(
              venue: venue,
              score: scored.score,
              reason: scored.reason,
            ),
          );
        }
      }

      return _scorer.rankByScore(
        items: recommendations,
        readScore: (item) => item.score,
        tieBreaker: (a, b) =>
            a.venue.name.toLowerCase().compareTo(b.venue.name.toLowerCase()),
        limit: limit,
      );
    });
  }
}
