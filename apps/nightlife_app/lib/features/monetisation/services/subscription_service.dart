import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../payments/services/stripe_checkout_service.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String artistMonthlyPriceId = StripeCheckoutService.artistMonthlyPriceId;
  static const String venueProPriceId = StripeCheckoutService.venueProPriceId;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<DocumentSnapshot<Map<String, dynamic>>> mySubscriptionStream() {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    return _db.collection('users').doc(uid).snapshots();
  }

  static Future<bool> hasActiveStripeSubscriptionForPlan(
    String appPlan,
  ) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final snapshot = await _db
        .collection('customers')
        .doc(uid)
        .collection('subscriptions')
        .where('status', whereIn: ['trialing', 'active'])
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'];

      if (items is List) {
        for (final item in items) {
          final price = item['price'];
          final product = price?['product'];

          if (product is Map &&
              product['metadata'] is Map &&
              product['metadata']['app_plan'] == appPlan) {
            return true;
          }
        }
      }

      final metadata = data['metadata'];
      if (metadata is Map && metadata['app_plan'] == appPlan) {
        return true;
      }
    }

    return false;
  }

  static Future<bool> isArtistSubscriptionActive() async {
    final stripeActive = await hasActiveStripeSubscriptionForPlan(
      'artist_monthly_499',
    );

    if (stripeActive) return true;

    final uid = currentUserId;
    if (uid == null) return false;

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};

    return data['artistSubscriptionActive'] == true;
  }



  static Future<bool> isOwnerVenueProActive() async {
    final stripeActive = await hasActiveStripeSubscriptionForPlan('venue_pro');
    if (stripeActive) return true;

    final uid = currentUserId;
    if (uid == null) return false;

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};

    return data['ownerSubscriptionActive'] == true ||
        data['ownerSubscriptionPlan'] == 'venue_pro';
  }

  static Future<void> markOwnerVenueProActiveForTesting() async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'ownerSubscriptionActive': true,
      'ownerSubscriptionPlan': 'venue_pro',
      'ownerSubscriptionPrice': 14.99,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> isVenueBookingFeatureEnabled(String venueId) async {
    final stripeActive = await hasActiveStripeSubscriptionForPlan('venue_pro');

    if (stripeActive) {
      await _db.collection('venues').doc(venueId).set({
        'bookingFeatureEnabled': true,
        'subscriptionPlan': 'venue_pro',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    }

    final venueDoc = await _db.collection('venues').doc(venueId).get();
    final data = venueDoc.data() ?? {};

    return data['bookingFeatureEnabled'] == true ||
        data['subscriptionPlan'] == 'venue_pro';
  }

  static Future<void> startArtistSubscriptionCheckout() async {
    await _startCheckout(
      priceId: artistMonthlyPriceId,
      appPlan: 'artist_monthly_499',
    );
  }

  static Future<void> startVenueProCheckout() async {
    await _startCheckout(
      priceId: venueProPriceId,
      appPlan: 'venue_pro',
    );
  }

  static Future<void> _startCheckout({
    required String priceId,
    required String appPlan,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    final checkoutRef = await _db
        .collection('customers')
        .doc(uid)
        .collection('checkout_sessions')
        .add({
      'mode': 'subscription',
      'price': priceId,
      'success_url': 'https://drinkspot.app/payments/success?kind=subscription',
      'cancel_url': 'https://drinkspot.app/payments/cancelled?kind=subscription',
      'metadata': {
        'app_plan': appPlan,
        'firebase_uid': uid,
      },
    });

    checkoutRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final error = data['error'];
      if (error != null) {
        throw Exception(error['message'] ?? 'Stripe checkout failed');
      }

      final url = data['url'];
      if (url is String && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      }
    });
  }

  static Future<void> openCustomerPortal() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    final portalRef = await _db
        .collection('customers')
        .doc(uid)
        .collection('portal_links')
        .add({
      'return_url': 'https://drinkspot.app/account',
    });

    portalRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final url = data['url'];
      if (url is String && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      }
    });
  }

  static Future<void> markArtistSubscriptionActiveForTesting() async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'artistSubscriptionActive': true,
      'artistSubscriptionPlan': 'artist_monthly_499',
      'artistSubscriptionPrice': 4.99,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markVenueBookingEnabledForTesting(String venueId) async {
    await _db.collection('venues').doc(venueId).set({
      'bookingFeatureEnabled': true,
      'subscriptionPlan': 'venue_pro',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}