import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtistService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<DocumentSnapshot<Map<String, dynamic>>> artistProfileStream() {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _db.collection('artist_profiles').doc(uid).snapshots();
  }

  static Future<void> createOrUpdateArtistProfile({
    required String artistName,
    required String artistType,
    required String bio,
    required String contactEmail,
    required String phone,
    required String location,
    required String performanceFee,
    required List<String> genres,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final profileRef = _db.collection('artist_profiles').doc(uid);
    final existingProfile = await profileRef.get();

    await profileRef.set({
      'artistId': uid,
      'artistName': artistName.trim(),
      'artistType': artistType,
      'bio': bio.trim(),
      'contactEmail': contactEmail.trim(),
      'phone': phone.trim(),
      'location': location.trim(),
      'performanceFee': performanceFee.trim(),
      'genres': genres,
      if (!existingProfile.exists) 'thumbsUpCount': 0,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> myApplicationsStream() {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('artist_applications')
        .where('artistId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> applyToVenue({
    required String venueId,
    required String venueName,
    required String message,
    required String preferredDate,
    required String performanceType,
    required String proposedFee,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final artistDoc = await _db.collection('artist_profiles').doc(uid).get();
    final artistData = artistDoc.data() ?? {};

    final venueDoc = await _db.collection('venues').doc(venueId).get();
    final venueData = venueDoc.data() ?? {};

    await _db.collection('artist_applications').add({
      'artistId': uid,
      'artistName': artistData['artistName'] ?? 'Unknown Artist',
      'artistEmail': artistData['contactEmail'] ?? '',
      'artistType': artistData['artistType'] ?? '',
      'venueId': venueId,
      'venueName': venueName,
      'venueOwnerId': venueData['ownerId'] ?? '',
      'performanceType': performanceType.trim(),
      'genre': '',
      'bio': artistData['bio'] ?? '',
      'message': message.trim(),
      'socialLink': '',
      'priceExpectation': proposedFee.trim(),
      'proposedFee': proposedFee.trim(),
      'preferredDate': preferredDate.trim(),
      'artistThumbsUpCount': artistData['thumbsUpCount'] ?? 0,
      'availableDate': Timestamp.now(),
      'status': 'pending',
      'adminFeePaid': false,
      'paymentId': '',
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteApplication(String applicationId) async {
    await _db.collection('artist_applications').doc(applicationId).delete();
  }
}