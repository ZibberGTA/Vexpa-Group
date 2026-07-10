import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../analytics/services/analytics_service.dart';

class FavouritesService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static String _docId(String userId, String venueId) {
    return '${userId}_$venueId';
  }

  static Stream<bool> isFavouriteStream(String venueId) {
    final userId = _userId;

    if (userId == null) {
      return Stream.value(false);
    }

    return _db
        .collection('favourites')
        .doc(_docId(userId, venueId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Future<void> toggleFavourite({
    required String venueId,
    required String venueName,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('You must be logged in to favourite venues.');
    }

    final ref = _db.collection('favourites').doc(_docId(userId, venueId));
    final doc = await ref.get();

    await AnalyticsService.logFavouriteTap(venueId);

    if (doc.exists) {
      await ref.delete();
      return;
    }

    final venueDoc = await _db.collection('venues').doc(venueId).get();
    final venueData = venueDoc.data() ?? {};

    final rawAddress = venueData['address'];
    final address = rawAddress is Map<String, dynamic> ? rawAddress : {};

    final name = (venueData['name'] ?? venueName).toString();
    final venueType =
        (venueData['venueType'] ?? venueData['category'] ?? '').toString();
    final category =
        (venueData['category'] ?? venueData['venueType'] ?? '').toString();
    final city = (address['city'] ?? '').toString();
    final addressLine1 = (address['line1'] ?? '').toString();
    final postcode = (address['postcode'] ?? '').toString();

    final searchText = [
      name,
      venueType,
      category,
      city,
      addressLine1,
      postcode,
    ].join(' ').toLowerCase();

    await ref.set({
      'userId': userId,
      'venueId': venueId,
      'venueName': name,
      'venueType': venueType,
      'category': category,
      'city': city,
      'address': addressLine1,
      'postcode': postcode,
      'searchText': searchText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}