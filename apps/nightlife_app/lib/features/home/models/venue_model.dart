import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/venue_branding_parser.dart';

class VenueModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String category;
  final String crowdLevel;
  final bool hasDeals;
  final List<String> searchTerms;
  final GeoPoint? location;
  final String bannerImageUrl;
  final String logoUrl;
  final String websiteUrl;
  final String phone;
  final Timestamp? crowdUpdatedAt;
  final Timestamp? updatedAt;
  final Map<String, dynamic> openingHours;
  final List<String> featureTags;
  final int presenceRadiusMeters;

  VenueModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.crowdLevel,
    this.hasDeals = false,
    this.searchTerms = const [],
    this.location,
    this.bannerImageUrl = '',
    this.logoUrl = '',
    this.websiteUrl = '',
    this.phone = '',
    this.crowdUpdatedAt,
    this.updatedAt,
    this.openingHours = const {},
    this.featureTags = const [],
    this.presenceRadiusMeters = 75,
  });

  factory VenueModel.fromMap(String id, Map<String, dynamic> map) {
    return VenueModel(
      id: id,
      ownerId: (map['ownerId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      crowdLevel: (map['currentCrowdLevel'] ?? map['crowdLevel'] ?? 'quiet').toString(),
      hasDeals: map['hasDeals'] == true,
      searchTerms: _parseSearchTerms(map['searchTerms']),
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      bannerImageUrl: VenueBrandingParser.resolveBannerImageUrl(map),
      logoUrl: VenueBrandingParser.resolveLogoUrl(map),
      websiteUrl: (map['websiteUrl'] ?? map['website'] ?? '').toString(),
      phone: (map['phone'] ?? map['phoneNumber'] ?? map['telephone'] ?? '').toString(),
      crowdUpdatedAt: map['crowdUpdatedAt'] is Timestamp ? map['crowdUpdatedAt'] as Timestamp : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] as Timestamp : null,
      openingHours: map['openingHours'] is Map ? Map<String, dynamic>.from(map['openingHours'] as Map) : const {},
      featureTags: _parseFeatureTags(map['featureTags'], map['venueFeatures']),
      presenceRadiusMeters: (map['presenceRadiusMeters'] as num?)?.toInt() ?? 75,
    );
  }

  static List<String> _parseFeatureTags(dynamic featureTags, dynamic venueFeatures) {
    final tags = <String>[];

    void addTag(String tag) {
      final cleaned = tag.trim();
      if (cleaned.isEmpty) return;
      if (!tags.contains(cleaned)) tags.add(cleaned);
    }

    if (featureTags is List) {
      for (final tag in featureTags) {
        addTag(tag.toString());
      }
    }

    if (venueFeatures is Map) {
      final map = Map<String, dynamic>.from(venueFeatures as Map);
      const labels = <String, String>{
        'age18': '18+',
        'age21': '21+',
        'liveMusic': 'Live Music',
        'dj': 'DJ',
        'sports': 'Sports',
        'karaoke': 'Karaoke',
        'quizNight': 'Quiz Night',
        'danceFloor': 'Dance Floor',
        'foodServed': 'Food Served',
        'outdoorSeating': 'Outdoor',
      };
      labels.forEach((key, label) {
        if (map[key] == true) addTag(label);
      });
    }

    return tags.take(3).toList();
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
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'category': category,
      'crowdLevel': crowdLevel,
      'currentCrowdLevel': crowdLevel,
      'hasDeals': hasDeals,
      'searchTerms': searchTerms,
      'location': location,
      'bannerImageUrl': bannerImageUrl,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'phone': phone,
      'crowdUpdatedAt': crowdUpdatedAt,
      'updatedAt': updatedAt,
      'openingHours': openingHours,
      'featureTags': featureTags,
      'presenceRadiusMeters': presenceRadiusMeters,
    };
  }
}