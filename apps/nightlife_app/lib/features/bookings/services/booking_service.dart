import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/models/artist_application_model.dart';
import '../models/booking_model.dart';

class BookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<String> createBookingFromApplication({
    required ArtistApplicationModel application,
    required DateTime bookingDate,
    required String agreedFee,
    required String notes,
  }) async {
    final ownerId = currentUserId;
    if (ownerId == null) {
      throw Exception('Not logged in');
    }

    final bookingRef = await _db.collection('bookings').add({
      'applicationId': application.id,
      'artistId': application.artistId,
      'artistName': application.artistName,
      'ownerId': ownerId,
      'venueId': application.venueId,
      'venueName': application.venueName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'agreedFee': agreedFee.trim(),
      'notes': notes.trim(),
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('artist_applications').doc(application.id).update({
      'status': 'accepted',
      'bookingId': bookingRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('notifications').add({
      'userId': application.artistId,
      'title': 'Booking confirmed',
      'body': '${application.venueName} confirmed your booking.',
      'type': 'booking',
      'relatedId': bookingRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return bookingRef.id;
  }

  static Stream<List<BookingModel>> myOwnerBookingsStream() {
    final ownerId = currentUserId;
    if (ownerId == null) throw Exception('Not logged in');

    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('bookingDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  static Stream<List<BookingModel>> myArtistBookingsStream() {
    final artistId = currentUserId;
    if (artistId == null) throw Exception('Not logged in');

    return _db
        .collection('bookings')
        .where('artistId', isEqualTo: artistId)
        .orderBy('bookingDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList());
  }

  static Future<void> updateBookingStatus({
    required BookingModel booking,
    required String status,
  }) async {
    await _db.collection('bookings').doc(booking.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('notifications').add({
      'userId': booking.artistId,
      'title': 'Booking updated',
      'body': '${booking.venueName} marked your booking as $status.',
      'type': 'booking',
      'relatedId': booking.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
