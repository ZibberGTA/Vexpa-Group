import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/vexcore/mobile_venue_document_mapper.dart';

class VenueDetailsModel {
  final String id;
  final String name;
  final String description;
  final String venueType;
  final String category;
  final List<String> categories;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postcode;
  final String country;
  final double lat;
  final double lng;
  final String phone;
  final String website;
  final String instagram;
  final String logoUrl;
  final String coverImageUrl;
  final List<String> galleryImageUrls;
  final List<String> features;
  final List<String> featureTags;
  final String priceRange;
  final double averageRating;
  final int reviewCount;
  final String currentCrowdLevel;
  final int currentCrowdScore;
  final String ownerId;
  final List<String> managerIds;
  final String subscriptionPlan;
  final bool isVerified;
  final bool isPublished;
  final bool isFeatured;
  final bool isDeleted;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? crowdUpdatedAt;

  VenueDetailsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.venueType,
    required this.category,
    required this.categories,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postcode,
    required this.country,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.website,
    required this.instagram,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.galleryImageUrls,
    required this.features,
    this.featureTags = const [],
    required this.priceRange,
    required this.averageRating,
    required this.reviewCount,
    required this.currentCrowdLevel,
    required this.currentCrowdScore,
    required this.ownerId,
    required this.managerIds,
    required this.subscriptionPlan,
    required this.isVerified,
    required this.isPublished,
    required this.isFeatured,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.crowdUpdatedAt,
  });

  factory VenueDetailsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MobileVenueDocumentMapper.parseVenueDetails(doc.id, doc.data())!;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'venueType': venueType,
      'category': category,
      'categories': categories,
      'address': {
        'line1': addressLine1,
        'line2': addressLine2,
        'city': city,
        'postcode': postcode,
        'country': country,
      },
      'location': GeoPoint(lat, lng),
      'phone': phone,
      'website': website,
      'instagram': instagram,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'bannerImageUrl': coverImageUrl,
      'galleryImageUrls': galleryImageUrls,
      'features': features,
      'priceRange': priceRange,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'currentCrowdLevel': currentCrowdLevel,
      'crowdLevel': currentCrowdLevel,
      'currentCrowdScore': currentCrowdScore,
      'ownerId': ownerId,
      'managerIds': managerIds,
      'subscriptionPlan': subscriptionPlan,
      'isVerified': isVerified,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}