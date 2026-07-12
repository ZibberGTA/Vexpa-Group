import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_engines/growth/growth_engine.dart';

export 'package:vex_engines/growth/domain/boost_plan.dart' show BoostPlan;

class BoostService {
  BoostService._();

  static const _growthBoost = GrowthBoostService();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static List<BoostPlan> get plans => GrowthProductCatalog.boostPlans;

  static Stream<Map<String, dynamic>?> activeBoostStream(String venueId) {
    return _db.collection('venue_boosts').doc(venueId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['active'] != true) return null;
      final endsAt = data['endsAt'];
      final endsAtDate = endsAt is Timestamp ? endsAt.toDate() : null;
      if (!_growthBoost.isBoostActive(active: true, endsAt: endsAtDate)) {
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
    final preparation = _growthBoost.prepareActivation(
      venueId: venueId,
      venueName: venueName,
      ownerId: ownerId,
      planId: plan.id,
      startedAt: DateTime.now(),
      paymentStatus: paymentStatus,
      checkoutSessionPath: checkoutSessionPath,
    );
    if (preparation is GrowthFailure<GrowthBoostActivationPayload>) {
      throw Exception(preparation.message);
    }
    final payload =
        (preparation as GrowthSuccess<GrowthBoostActivationPayload>).value;
    final endsAt = payload.endsAt;

    await _db.collection('venue_boosts').doc(venueId).set({
      'venueId': payload.venueId,
      'venueName': payload.venueName,
      'ownerId': payload.ownerId,
      'planId': payload.plan.id,
      'planName': payload.plan.name,
      'priceLabel': payload.plan.priceLabel,
      'pricePence': payload.plan.pricePence,
      'boostScore': payload.plan.boostScore,
      'active': true,
      'paymentStatus': payload.paymentStatus,
      if (payload.checkoutSessionPath != null)
        'checkoutSessionPath': payload.checkoutSessionPath,
      'startedAt': FieldValue.serverTimestamp(),
      'endsAt': Timestamp.fromDate(endsAt),
    }, SetOptions(merge: true));

    await _db.collection('monetisation_events').add({
      'venueId': payload.venueId,
      'venueName': payload.venueName,
      'ownerId': payload.ownerId,
      'type': 'boost_activated',
      'planId': payload.plan.id,
      'priceLabel': payload.plan.priceLabel,
      'pricePence': payload.plan.pricePence,
      'paymentStatus': payload.paymentStatus,
      if (payload.checkoutSessionPath != null)
        'checkoutSessionPath': payload.checkoutSessionPath,
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
    final validation = _growthBoost.validatePaidCheckout(
      paymentStatus: data?['payment_status']?.toString(),
      sessionStatus: data?['status']?.toString(),
    );
    if (validation is GrowthFailure<void>) {
      throw Exception(validation.message);
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

    return {'paidBoosts': paidBoosts, 'totalPence': totalPence};
  }

  static Future<void> cancelBoost(String venueId) async {
    await _db.collection('venue_boosts').doc(venueId).set({
      'active': false,
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
