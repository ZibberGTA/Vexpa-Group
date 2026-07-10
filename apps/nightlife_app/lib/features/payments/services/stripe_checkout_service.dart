import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../monetisation/services/boost_service.dart';

class StripeCheckoutResult {
  final String sessionId;
  final DocumentReference<Map<String, dynamic>> reference;

  const StripeCheckoutResult({
    required this.sessionId,
    required this.reference,
  });
}

class StripeCheckoutService {
  StripeCheckoutService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO: Replace these with real Stripe Price IDs after creating products in Stripe.
  // Keep these as Stripe Price IDs, not Product IDs. Real Price IDs usually start with price_...
  static const String artistMonthlyPriceId = 'REPLACE_WITH_STRIPE_ARTIST_MONTHLY_PRICE_ID';
  static const String venueProPriceId = 'REPLACE_WITH_STRIPE_VENUE_PRO_PRICE_ID';

  static const Map<String, String> boostPriceIds = {
    'boost_24h': 'REPLACE_WITH_STRIPE_BOOST_24H_PRICE_ID',
    'boost_7d': 'REPLACE_WITH_STRIPE_BOOST_7D_PRICE_ID',
    'boost_30d': 'REPLACE_WITH_STRIPE_BOOST_30D_PRICE_ID',
  };

  static bool _isMissingPriceId(String priceId) =>
      priceId.trim().isEmpty ||
      priceId.startsWith('REPLACE_WITH_') ||
      priceId.startsWith('PASTE_') ||
      priceId.startsWith('price_ARTIST_') ||
      priceId.startsWith('price_VENUE_') ||
      priceId.startsWith('price_BOOST_');

  static void _validatePriceId(String priceId, String label) {
    if (_isMissingPriceId(priceId)) {
      throw Exception('Missing Stripe Price ID for $label. Update StripeCheckoutService.');
    }
  }

  static String? get currentUserId => _auth.currentUser?.uid;

  // These URLs must be valid for the Firebase Stripe extension. Replace with your production domain
  // or app/universal-link routes before going live.
  static String _successUrl(String kind) =>
      'https://drinkspot.app/payments/success?kind=$kind';

  static String _cancelUrl(String kind) =>
      'https://drinkspot.app/payments/cancelled?kind=$kind';

  static Future<DocumentReference<Map<String, dynamic>>> createSubscriptionCheckout({
    required String priceId,
    String? successUrl,
    String? cancelUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Not logged in');
    }

    _validatePriceId(priceId, 'subscription');

    return _db
        .collection('customers')
        .doc(uid)
        .collection('checkout_sessions')
        .add({
      'price': priceId,
      'success_url': successUrl ?? _successUrl('subscription'),
      'cancel_url': cancelUrl ?? _cancelUrl('subscription'),
      'mode': 'subscription',
      if (metadata != null) 'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<StripeCheckoutResult> createBoostCheckout({
    required String venueId,
    required String venueName,
    required BoostPlan plan,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Not logged in');
    }

    final priceId = boostPriceIds[plan.id];
    if (priceId == null) {
      throw Exception('Missing Stripe Price ID for ${plan.name}. Update StripeCheckoutService.boostPriceIds.');
    }
    _validatePriceId(priceId, plan.name);

    final ref = await _db
        .collection('customers')
        .doc(uid)
        .collection('checkout_sessions')
        .add({
      'price': priceId,
      'mode': 'payment',
      'success_url': successUrl ?? _successUrl('boost'),
      'cancel_url': cancelUrl ?? _cancelUrl('boost'),
      'allow_promotion_codes': true,
      'metadata': {
        'kind': 'venue_boost',
        'venueId': venueId,
        'venueName': venueName,
        'ownerId': uid,
        'planId': plan.id,
        'planName': plan.name,
        'days': plan.days.toString(),
        'boostScore': plan.boostScore.toString(),
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('payment_events').add({
      'type': 'boost_checkout_created',
      'ownerId': uid,
      'venueId': venueId,
      'venueName': venueName,
      'planId': plan.id,
      'priceId': priceId,
      'checkoutSessionPath': ref.path,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return StripeCheckoutResult(sessionId: ref.id, reference: ref);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> checkoutSessionStream(
    DocumentReference<Map<String, dynamic>> ref,
  ) {
    return ref.snapshots();
  }

  static bool isPaidCheckoutSession(Map<String, dynamic>? data) {
    if (data == null) return false;
    final paymentStatus = data['payment_status']?.toString().toLowerCase();
    final status = data['status']?.toString().toLowerCase();
    return paymentStatus == 'paid' || status == 'complete' || status == 'paid';
  }

  static String? checkoutUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data['url']?.toString();
  }


  static Future<void> openCheckoutUrl(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not open Stripe checkout URL');
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static String checkoutStatusLabel(Map<String, dynamic>? data) {
    if (data == null) return 'Creating checkout...';
    if (data['error'] != null) return 'Checkout error';
    if (isPaidCheckoutSession(data)) return 'Payment complete';
    if (data['url'] != null) return 'Checkout ready';
    return data['status']?.toString() ?? 'Waiting for Stripe';
  }
}
