import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistApplicationModel {
  final String id;
  final String artistId;
  final String artistName;
  final String artistEmail;
  final String venueId;
  final String venueName;
  final String venueOwnerId;
  final String performanceType;
  final String genre;
  final String bio;
  final String message;
  final String socialLink;
  final String priceExpectation;
  final DateTime availableDate;
  final String status;
  final bool adminFeePaid;
  final String paymentId;
  final int artistThumbsUpCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  ArtistApplicationModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.artistEmail,
    required this.venueId,
    required this.venueName,
    required this.venueOwnerId,
    required this.performanceType,
    required this.genre,
    required this.bio,
    required this.message,
    required this.socialLink,
    required this.priceExpectation,
    required this.availableDate,
    required this.status,
    required this.adminFeePaid,
    required this.paymentId,
    required this.artistThumbsUpCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory ArtistApplicationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtistApplicationModel(
      id: doc.id,
      artistId: data['artistId'] ?? '',
      artistName: data['artistName'] ?? '',
      artistEmail: data['artistEmail'] ?? '',
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueOwnerId: data['venueOwnerId'] ?? '',
      performanceType: data['performanceType'] ?? '',
      genre: data['genre'] ?? '',
      bio: data['bio'] ?? '',
      message: data['message'] ?? '',
      socialLink: data['socialLink'] ?? '',
      priceExpectation: data['priceExpectation'] ?? '',
      availableDate:
          (data['availableDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      adminFeePaid: data['adminFeePaid'] ?? false,
      paymentId: data['paymentId'] ?? '',
      artistThumbsUpCount: data['artistThumbsUpCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }
}