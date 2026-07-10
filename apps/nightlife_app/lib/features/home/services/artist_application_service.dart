import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/artist_application_model.dart';

class ArtistApplicationService {
  static final _applications =
      FirebaseFirestore.instance.collection('artist_applications');
  static final _notifications =
      FirebaseFirestore.instance.collection('notifications');

  static Stream<List<ArtistApplicationModel>> getApplicationsForVenue(
    String venueId,
  ) {
    return _applications
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArtistApplicationModel.fromDoc(doc))
              .toList(),
        );
  }

  static Stream<List<ArtistApplicationModel>> getApplicationsForArtist(
    String artistId,
  ) {
    return _applications
        .where('artistId', isEqualTo: artistId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArtistApplicationModel.fromDoc(doc))
              .toList(),
        );
  }

  static Future<void> submitApplication({
    required String artistId,
    required String artistName,
    required String artistEmail,
    required String venueId,
    required String venueName,
    required String performanceType,
    required String genre,
    required String bio,
    required String message,
    required String socialLink,
    required String priceExpectation,
    required DateTime availableDate,
  }) async {
    await _applications.add({
      'artistId': artistId,
      'artistName': artistName.trim(),
      'artistEmail': artistEmail.trim(),
      'venueId': venueId,
      'venueName': venueName.trim(),
      'venueOwnerId': '',
      'performanceType': performanceType.trim(),
      'genre': genre.trim(),
      'bio': bio.trim(),
      'message': message.trim(),
      'socialLink': socialLink.trim(),
      'priceExpectation': priceExpectation.trim(),
      'availableDate': Timestamp.fromDate(availableDate),
      'status': 'pending',
      'adminFeePaid': false,
      'paymentId': '',
      'artistThumbsUpCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isDeleted': false,
    });
  }

  static Future<void> acceptApplication(ArtistApplicationModel application) async {
    await _applications.doc(application.id).update({
      'status': 'accepted',
      'updatedAt': Timestamp.now(),
    });

    await _notifications.add({
      'userId': application.artistId,
      'title': 'Application accepted',
      'body': '${application.venueName} accepted your application.',
      'type': 'application',
      'relatedId': application.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rejectApplication(ArtistApplicationModel application) async {
    await _applications.doc(application.id).update({
      'status': 'rejected',
      'updatedAt': Timestamp.now(),
    });

    await _notifications.add({
      'userId': application.artistId,
      'title': 'Application declined',
      'body': '${application.venueName} declined your application.',
      'type': 'application',
      'relatedId': application.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteApplication(String applicationId) async {
    await _applications.doc(applicationId).update({
      'isDeleted': true,
      'deletedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> markAdminFeePaid({
    required String applicationId,
    required String paymentId,
  }) async {
    await _applications.doc(applicationId).update({
      'adminFeePaid': true,
      'paymentId': paymentId,
      'updatedAt': Timestamp.now(),
    });
  }
}
