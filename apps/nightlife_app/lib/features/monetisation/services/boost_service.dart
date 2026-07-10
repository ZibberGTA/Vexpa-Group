import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoostPlan {
  final String id;
  final String name;
  final String description;
  final int days;
  final int boostScore;
  final String priceLabel;
  final int pricePence;

  const BoostPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
    required this.boostScore,
    required this.priceLabel,
    required this.pricePence,
  });
}

class BoostService {
  BoostService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const plans = <BoostPlan>[
    BoostPlan(
      id: 'boost_24h',
      name: '24 Hour Boost',
      description: 'Push one venue higher in Trending for a full day.',
      days: 1,
      boostScore: 35,
      priceLabel: '£4.99',
      pricePence: 499,
    ),
    BoostPlan(
      id: 'boost_7d',
      name: '7 Day Boost',
      description: 'Keep one venue promoted during the week.',
      days: 7,
      boostScore: 45,
      priceLabel: '£19.99',
      pricePence: 1999,
    ),
    BoostPlan(
      id: 'boost_30d',
      name: '30 Day Boost',
      description: 'Monthly visibility for your highest-priority venue.',
      days: 30,
      boostScore: 55,
      priceLabel: '£59.99',
      pricePence: 5999,
    ),
  ];

  static Stream<Map<String, dynamic>?> activeBoostStream(String venueId) {
    return _db.collection('venue_boosts').doc(venueId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['active'] != true) return null;
      final endsAt = data['endsAt'];
      if (endsAt is Timestamp && endsAt.toDate().isBefore(DateTime.now())) {
        return null;
      }
      return data;
    });
  }

  static Future<void> activateBoost({
    required String venueId,
    required String venueName,
    required String ownerId,
    required BoostPlan plan,
    String paymentStatus = 'manual',
    String? checkoutSessionPath,
  }) async {
    final now = DateTime.now();
    final endsAt = now.add(Duration(days: plan.days));

    await _db.collection('venue_boosts').doc(venueId).set({
      'venueId': venueId,
      'venueName': venueName,
      'ownerId': ownerId,
      'planId': plan.id,
      'planName': plan.name,
      'priceLabel': plan.priceLabel,
      'pricePence': plan.pricePence,
      'boostScore': plan.boostScore,
      'active': true,
      'paymentStatus': paymentStatus,
      if (checkoutSessionPath != null) 'checkoutSessionPath': checkoutSessionPath,
      'startedAt': FieldValue.serverTimestamp(),
      'endsAt': Timestamp.fromDate(endsAt),
    }, SetOptions(merge: true));

    await _db.collection('monetisation_events').add({
      'venueId': venueId,
      'venueName': venueName,
      'ownerId': ownerId,
      'type': 'boost_activated',
      'planId': plan.id,
      'priceLabel': plan.priceLabel,
      'pricePence': plan.pricePence,
      'paymentStatus': paymentStatus,
      if (checkoutSessionPath != null) 'checkoutSessionPath': checkoutSessionPath,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> activateBoostAfterPayment({
    required DocumentReference<Map<String, dynamic>> checkoutRef,
    required String venueId,
    required String venueName,
    required BoostPlan plan,
  }) async {
    final ownerId = _auth.currentUser?.uid;
    if (ownerId == null) throw Exception('Not logged in');

    final checkout = await checkoutRef.get();
    final data = checkout.data();
    final paymentStatus = data?['payment_status']?.toString().toLowerCase();
    final status = data?['status']?.toString().toLowerCase();
    final paid = paymentStatus == 'paid' || status == 'complete' || status == 'paid';

    if (!paid) {
      throw Exception('Stripe checkout has not been paid yet.');
    }

    await activateBoost(
      venueId: venueId,
      venueName: venueName,
      ownerId: ownerId,
      plan: plan,
      paymentStatus: 'paid',
      checkoutSessionPath: checkoutRef.path,
    );

    await checkoutRef.set({
      'boostActivated': true,
      'boostActivatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, int>> revenueSummary() async {
    final snapshot = await _db
        .collection('monetisation_events')
        .where('type', isEqualTo: 'boost_activated')
        .get();

    var totalPence = 0;
    var paidBoosts = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final paymentStatus = data['paymentStatus']?.toString().toLowerCase();
      if (paymentStatus == 'paid') {
        paidBoosts++;
        totalPence += (data['pricePence'] as num?)?.toInt() ?? 0;
      }
    }

    return {
      'paidBoosts': paidBoosts,
      'totalPence': totalPence,
    };
  }

  static Future<void> cancelBoost(String venueId) async {
    await _db.collection('venue_boosts').doc(venueId).set({
      'active': false,
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
