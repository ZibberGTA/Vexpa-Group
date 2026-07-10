import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/venue_branding_parser.dart';

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
    final data = doc.data() ?? {};

    final rawAddress = data['address'];
    final address = rawAddress is Map<String, dynamic> ? rawAddress : <String, dynamic>{};
    final flatAddress = rawAddress is String ? rawAddress : '';

    final rawLocation = data['location'];

    double lat = 0;
    double lng = 0;

    if (rawLocation is GeoPoint) {
      lat = rawLocation.latitude;
      lng = rawLocation.longitude;
    } else if (rawLocation is Map<String, dynamic>) {
      lat = (rawLocation['lat'] ?? 0).toDouble();
      lng = (rawLocation['lng'] ?? 0).toDouble();
    }

    return VenueDetailsModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? data['Description'] ?? '',
      venueType: data['venueType'] ?? data['category'] ?? '',
      category: data['category'] ?? data['venueType'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      addressLine1: address['line1'] ?? flatAddress,
      addressLine2: address['line2'] ?? '',
      city: address['city'] ?? '',
      postcode: address['postcode'] ?? '',
      country: address['country'] ?? 'UK',
      lat: lat,
      lng: lng,
      phone: data['phone'] ?? '',
      website: (data['website'] ?? data['websiteUrl'] ?? '').toString(),
      instagram: data['instagram'] ?? '',
      logoUrl: VenueBrandingParser.resolveLogoUrl(data),
      coverImageUrl: VenueBrandingParser.resolveBannerImageUrl(data),
      galleryImageUrls: List<String>.from(data['galleryImageUrls'] ?? []),
      features: List<String>.from(data['features'] ?? []),
      priceRange: data['priceRange'] ?? '',
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      currentCrowdLevel:
          data['currentCrowdLevel'] ?? data['crowdLevel'] ?? 'quiet',
      currentCrowdScore: data['currentCrowdScore'] ?? 1,
      ownerId: data['ownerId'] ?? '',
      managerIds: List<String>.from(data['managerIds'] ?? []),
      subscriptionPlan: data['subscriptionPlan'] ?? 'free',
      isVerified: data['isVerified'] ?? false,
      isPublished: data['isPublished'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      crowdUpdatedAt: data['crowdUpdatedAt'] is Timestamp ? data['crowdUpdatedAt'] as Timestamp : null,
    );
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