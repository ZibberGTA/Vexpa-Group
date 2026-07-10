import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/venue_branding_parser.dart';

class VenueModel {
  final String id;
  final String name;
  final String category;
  final String crowdLevel;
  final bool hasDeals;
  final List<String> searchTerms;
  final List<String> matchReasons;
  final String? address;
  final String? imageUrl;
  final String? bannerImageUrl;
  final String? logoUrl;
  final GeoPoint? location;

  VenueModel({
    required this.id,
    required this.name,
    required this.category,
    required this.crowdLevel,
    required this.hasDeals,
    required this.searchTerms,
    this.matchReasons = const [],
    this.address,
    this.imageUrl,
    this.bannerImageUrl,
    this.logoUrl,
    this.location,
  });

  factory VenueModel.fromMap(String id, Map<String, dynamic> map) {
    final bannerUrl = VenueBrandingParser.resolveBannerImageUrl(map);
    final logoUrl = VenueBrandingParser.resolveLogoUrl(map);

    return VenueModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      crowdLevel: (map['crowdLevel'] ?? '').toString(),
      hasDeals: map['hasDeals'] == true,
      searchTerms: _parseSearchTerms(map['searchTerms']),
      address: map['address']?.toString(),
      imageUrl: bannerUrl.isNotEmpty ? bannerUrl : null,
      bannerImageUrl: bannerUrl.isNotEmpty ? bannerUrl : null,
      logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
      location: map['location'] as GeoPoint?,
    );
  }

  static List<String> _parseSearchTerms(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      return [value];
    }

    return <String>[];
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'crowdLevel': crowdLevel,
      'hasDeals': hasDeals,
      'searchTerms': searchTerms,
      'address': address,
      'imageUrl': imageUrl,
      'bannerImageUrl': bannerImageUrl,
      'logoUrl': logoUrl,
      'location': location,
    };
  }

  VenueModel copyWith({
    List<String>? matchReasons,
  }) {
    return VenueModel(
      id: id,
      name: name,
      category: category,
      crowdLevel: crowdLevel,
      hasDeals: hasDeals,
      searchTerms: searchTerms,
      matchReasons: matchReasons ?? this.matchReasons,
      address: address,
      imageUrl: imageUrl,
      bannerImageUrl: bannerImageUrl,
      logoUrl: logoUrl,
      location: location,
    );
  }
}