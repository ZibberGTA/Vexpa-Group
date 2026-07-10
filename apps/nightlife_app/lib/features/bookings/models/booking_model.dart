import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String applicationId;
  final String artistId;
  final String artistName;
  final String ownerId;
  final String venueId;
  final String venueName;
  final DateTime bookingDate;
  final String agreedFee;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.applicationId,
    required this.artistId,
    required this.artistName,
    required this.ownerId,
    required this.venueId,
    required this.venueName,
    required this.bookingDate,
    required this.agreedFee,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      id: doc.id,
      applicationId: data['applicationId'] ?? '',
      artistId: data['artistId'] ?? '',
      artistName: data['artistName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      bookingDate:
          (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      agreedFee: data['agreedFee'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'confirmed',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}