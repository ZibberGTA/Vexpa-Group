import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';
import 'package:vex_engines/venue/shared/venue_image_field_parser.dart';

import '../../features/home/models/venue_model.dart';
import '../../features/venues/models/venue_details_model.dart';

/// Maps Firestore venue documents into VexCore and mobile view models.
final class MobileVenueDocumentMapper {
  MobileVenueDocumentMapper._();

  static bool isCatalogVisible(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['isDeleted'] != true;
  }

  static Venue? parseVexVenue(String id, Map<String, dynamic>? data) {
    if (!isCatalogVisible(data)) return null;

    try {
      final map = data!;
      final addressParts = _parseAddress(map);
      final coordinates = _parseCoordinates(map);

      return Venue(
        id: id,
        name: (map['name'] ?? '').toString(),
        address: addressParts.full,
        area: addressParts.area,
        city: addressParts.city,
        postcode: addressParts.postcode,
        category: (map['category'] ?? '').toString(),
        venueType: (map['venueType'] ?? map['category'] ?? '').toString(),
        crowdLevel:
            (map['currentCrowdLevel'] ?? map['crowdLevel'] ?? 'quiet').toString(),
        hasDeals: map['hasDeals'] == true,
        searchTerms: _parseSearchTerms(map['searchTerms']),
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        bannerImageUrl: VenueImageFieldParser.resolveVenueBannerUrl(map),
        logoUrl: VenueImageFieldParser.resolveVenueLogoUrl(map),
        featureTags: VenueProfileFieldCodec.displayFeatureTags(
          featureTags: _parseStringList(map['featureTags']),
          features: _parseStringList(map['features']),
        ),
        averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
        openingHours: map['openingHours'] is Map
            ? Map<String, dynamic>.from(map['openingHours'] as Map)
            : const {},
      );
    } on Object {
      return null;
    }
  }

  static VenueModel? parseHomeVenueModel(String id, Map<String, dynamic>? data) {
    if (!isCatalogVisible(data)) return null;
    try {
      return VenueModel.fromMap(id, data!);
    } on Object {
      return null;
    }
  }

  static VenueDetailsModel? parseVenueDetails(
    String id,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    try {
      final rawAddress = data['address'];
      final address =
          rawAddress is Map<String, dynamic> ? rawAddress : <String, dynamic>{};
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
        id: id,
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
        logoUrl: VenueImageFieldParser.resolveVenueLogoUrl(data),
        coverImageUrl: VenueImageFieldParser.resolveVenueBannerUrl(data),
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
        createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
        updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] as Timestamp : null,
        crowdUpdatedAt: data['crowdUpdatedAt'] is Timestamp
            ? data['crowdUpdatedAt'] as Timestamp
            : null,
      );
    } on Object {
      return null;
    }
  }

  static VenueModel homeVenueFromVexVenue(Venue venue) {
    return VenueModel(
      id: venue.id,
      ownerId: '',
      name: venue.name,
      description: '',
      address: venue.address,
      category: venue.category,
      crowdLevel: venue.crowdLevel,
      hasDeals: venue.hasDeals,
      searchTerms: venue.searchTerms,
      location: venue.hasValidCoordinates
          ? GeoPoint(venue.latitude!, venue.longitude!)
          : null,
      bannerImageUrl: venue.bannerImageUrl,
      logoUrl: venue.logoUrl,
      openingHours: venue.openingHours,
      featureTags: venue.featureTags,
    );
  }

  static List<String> _parseSearchTerms(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static _AddressParts _parseAddress(Map<String, dynamic> map) {
    final rawAddress = map['address'];
    if (rawAddress is Map<String, dynamic>) {
      final line1 = (rawAddress['line1'] ?? '').toString();
      final area = (rawAddress['area'] ?? '').toString();
      final city = (rawAddress['city'] ?? '').toString();
      final postcode = (rawAddress['postcode'] ?? '').toString();
      return _AddressParts(
        full: line1,
        area: area,
        city: city,
        postcode: postcode,
      );
    }

    final flat = rawAddress?.toString() ?? '';
    return _AddressParts(full: flat, area: '', city: '', postcode: '');
  }

  static _Coordinates _parseCoordinates(Map<String, dynamic> map) {
    final rawLocation = map['location'];
    if (rawLocation is GeoPoint) {
      return _Coordinates(
        latitude: rawLocation.latitude,
        longitude: rawLocation.longitude,
      );
    }

    final lat = (map['lat'] as num?)?.toDouble();
    final lng = (map['lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      return _Coordinates(latitude: lat, longitude: lng);
    }

    if (rawLocation is Map) {
      final locationMap = Map<String, dynamic>.from(rawLocation);
      return _Coordinates(
        latitude: (locationMap['lat'] as num?)?.toDouble(),
        longitude: (locationMap['lng'] as num?)?.toDouble(),
      );
    }

    return const _Coordinates();
  }
}

final class _AddressParts {
  const _AddressParts({
    required this.full,
    required this.area,
    required this.city,
    required this.postcode,
  });

  final String full;
  final String area;
  final String city;
  final String postcode;
}

final class _Coordinates {
  const _Coordinates({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;
}
