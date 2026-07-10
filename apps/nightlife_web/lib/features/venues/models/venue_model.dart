import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/venue_image_field_parser.dart';
import 'image_position_metadata.dart';

/// Firestore venue document — aligned with the Vexda mobile app model.
class VenueModel {
  VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.city,
    this.postcode = '',
    required this.category,
    required this.venueType,
    required this.crowdLevel,
    this.hasDeals = false,
    this.searchTerms = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.bannerImageUrl = '',
    this.logoUrl = '',
    this.bannerImagePosition,
    this.logoImagePosition,
    this.galleryImagePositions = const {},
    this.phone = '',
    this.website = '',
    this.description = '',
    this.galleryImageUrls = const [],
    this.galleryImages = const [],
    this.features = const [],
    this.featureTags = const [],
    this.averageRating = 0,
    this.openingHours = const {},
    this.subscriptionPlanId = 'professional',
    this.customMediaLimits = const {},
    this.ownerId = '',
    this.currentLogoMediaId = '',
    this.currentBannerMediaId = '',
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final String city;
  final String postcode;
  final String category;
  final String venueType;
  final String crowdLevel;
  final bool hasDeals;
  final List<String> searchTerms;
  final GeoPoint? location;
  final double? latitude;
  final double? longitude;
  final String bannerImageUrl;
  final String logoUrl;
  final ImagePositionMetadata? bannerImagePosition;
  final ImagePositionMetadata? logoImagePosition;
  final Map<String, ImagePositionMetadata> galleryImagePositions;
  final String phone;
  final String website;
  final String description;
  final List<String> galleryImageUrls;
  final List<VenueGalleryImageData> galleryImages;
  final List<String> features;
  final List<String> featureTags;
  final double averageRating;
  final Map<String, dynamic> openingHours;
  final String subscriptionPlanId;
  final Map<String, int> customMediaLimits;
  final String ownerId;
  final String currentLogoMediaId;
  final String currentBannerMediaId;

  factory VenueModel.fromMap(String id, Map<String, dynamic> map) {
    final addressParts = _parseAddress(map);
    final coordinates = _parseCoordinates(map);

    return VenueModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      address: addressParts.full,
      area: addressParts.area,
      city: addressParts.city,
      postcode: addressParts.postcode,
      category: (map['category'] ?? '').toString(),
      venueType: (map['venueType'] ?? map['category'] ?? '').toString(),
      crowdLevel: (map['currentCrowdLevel'] ?? map['crowdLevel'] ?? 'quiet')
          .toString(),
      hasDeals: map['hasDeals'] == true,
      searchTerms: _parseSearchTerms(map['searchTerms']),
      location: coordinates.location,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      bannerImageUrl: VenueImageFieldParser.resolveVenueBannerUrl(map),
      logoUrl: VenueImageFieldParser.resolveVenueLogoUrl(map),
      bannerImagePosition: VenueImageFieldParser.resolveBannerImagePosition(
        map,
      ),
      logoImagePosition: VenueImageFieldParser.resolveLogoImagePosition(map),
      galleryImagePositions: VenueImageFieldParser.resolveGalleryImagePositions(
        map,
      ),
      phone: (map['phone'] ?? '').toString(),
      website: (map['website'] ?? map['websiteUrl'] ?? '').toString(),
      description: (map['description'] ?? map['Description'] ?? '').toString(),
      galleryImageUrls: _parseStringList(
        map['galleryImageUrls'] ?? map['galleryImages'],
      ),
      galleryImages: _parseGalleryImages(map),
      features: _parseStringList(map['features']),
      featureTags: _parseFeatureTags(map['featureTags'], map['venueFeatures']),
      averageRating: _parseRating(map),
      openingHours: map['openingHours'] is Map
          ? Map<String, dynamic>.from(map['openingHours'] as Map)
          : const {},
      subscriptionPlanId: _parseSubscriptionPlan(map),
      customMediaLimits: _parseCustomMediaLimits(map),
      ownerId: (map['ownerId'] ?? '').toString(),
      currentLogoMediaId: (map['currentLogoMediaId'] ?? '').toString(),
      currentBannerMediaId: (map['currentBannerMediaId'] ?? '').toString(),
    );
  }

  static List<VenueGalleryImageData> _parseGalleryImages(
    Map<String, dynamic> map,
  ) {
    final raw = map['galleryImages'];
    if (raw is List) {
      final parsed = <VenueGalleryImageData>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final data = VenueGalleryImageData.fromMap(
          Map<String, dynamic>.from(entry),
        );
        if (data.imageUrl.isNotEmpty && data.status == 'active') {
          parsed.add(data);
        }
      }
      if (parsed.isNotEmpty) {
        parsed.sort((a, b) {
          if (a.isCover != b.isCover) return a.isCover ? -1 : 1;
          return a.sortOrder.compareTo(b.sortOrder);
        });
        return parsed;
      }
    }

    return _parseStringList(map['galleryImageUrls'] ?? map['galleryImages'])
        .asMap()
        .entries
        .map(
          (entry) => VenueGalleryImageData(
            imageId: 'legacy-${entry.key}',
            imageUrl: entry.value,
            thumbnailUrl: entry.value,
            category: entry.key == 0 ? 'cover' : 'other',
            isCover: entry.key == 0,
            sortOrder: entry.key,
          ),
        )
        .toList();
  }

  static String _parseSubscriptionPlan(Map<String, dynamic> map) {
    final raw =
        (map['subscriptionPlan'] ??
                map['subscriptionPlanId'] ??
                map['plan'] ??
                map['planId'] ??
                'professional')
            .toString()
            .trim()
            .toLowerCase();
    if (raw.isEmpty) return 'professional';
    return raw;
  }

  static Map<String, int> _parseCustomMediaLimits(Map<String, dynamic> map) {
    final raw = map['mediaLimits'] ?? map['customMediaLimits'];
    if (raw is! Map) return const {};

    final limits = <String, int>{};
    raw.forEach((key, value) {
      if (value is num) {
        limits[key.toString()] = value.toInt();
      }
    });
    return limits;
  }

  static double _parseRating(Map<String, dynamic> map) {
    final value = map['averageRating'] ?? map['rating'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static ({String full, String area, String city, String postcode})
  _parseAddress(Map<String, dynamic> map) {
    final rawAddress = map['address'];

    if (rawAddress is Map) {
      final address = Map<String, dynamic>.from(rawAddress);
      final line1 = (address['line1'] ?? address['street'] ?? '')
          .toString()
          .trim();
      final line2 = (address['line2'] ?? '').toString().trim();
      final area = (address['area'] ?? line2).toString().trim();
      final city = (address['city'] ?? '').toString().trim();
      final postcode = (address['postcode'] ?? '').toString().trim();

      final parts = <String>[
        if (line1.isNotEmpty) line1,
        if (area.isNotEmpty) area,
        if (city.isNotEmpty) city,
        if (postcode.isNotEmpty) postcode,
      ];

      return (
        full: parts.join(', '),
        area: area.isNotEmpty ? area : line1,
        city: city,
        postcode: postcode,
      );
    }

    final flat = rawAddress?.toString().trim() ?? '';
    if (flat.isEmpty) {
      final city = (map['city'] ?? '').toString().trim();
      return (full: city, area: city, city: city, postcode: '');
    }

    final parts = flat
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return (
        full: flat,
        area: parts[parts.length - 2],
        city: parts.last,
        postcode: '',
      );
    }

    return (full: flat, area: flat, city: '', postcode: '');
  }

  static ({GeoPoint? location, double? latitude, double? longitude})
  _parseCoordinates(Map<String, dynamic> map) {
    final rawLocation = map['location'];

    if (rawLocation is GeoPoint) {
      return (
        location: rawLocation,
        latitude: rawLocation.latitude,
        longitude: rawLocation.longitude,
      );
    }

    if (rawLocation is Map) {
      final locationMap = Map<String, dynamic>.from(rawLocation);
      final lat = _toDouble(locationMap['lat'] ?? locationMap['latitude']);
      final lng = _toDouble(locationMap['lng'] ?? locationMap['longitude']);
      if (_isValidCoordinate(lat, lng)) {
        return (location: GeoPoint(lat!, lng!), latitude: lat, longitude: lng);
      }
    }

    final lat = _toDouble(map['lat'] ?? map['latitude']);
    final lng = _toDouble(map['lng'] ?? map['longitude']);
    if (_isValidCoordinate(lat, lng)) {
      return (location: GeoPoint(lat!, lng!), latitude: lat, longitude: lng);
    }

    return (location: null, latitude: null, longitude: null);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  static List<String> _parseFeatureTags(
    dynamic featureTags,
    dynamic venueFeatures,
  ) {
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
      final map = Map<String, dynamic>.from(venueFeatures);
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

    return tags;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _parseSearchTerms(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return [value];
    }
    return const [];
  }
}

class VenueGalleryImageData {
  const VenueGalleryImageData({
    required this.imageId,
    required this.imageUrl,
    this.thumbnailUrl = '',
    this.category = 'other',
    this.caption = '',
    this.isCover = false,
    this.sortOrder = 0,
    this.status = 'active',
  });

  final String imageId;
  final String imageUrl;
  final String thumbnailUrl;
  final String category;
  final String caption;
  final bool isCover;
  final int sortOrder;
  final String status;

  String get previewUrl =>
      thumbnailUrl.trim().isNotEmpty ? thumbnailUrl : imageUrl;

  factory VenueGalleryImageData.fromMap(Map<String, dynamic> map) {
    return VenueGalleryImageData(
      imageId: (map['imageId'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? map['url'] ?? '').toString().trim(),
      thumbnailUrl: (map['thumbnailUrl'] ?? '').toString().trim(),
      category: _normalizeCategory(map['category']?.toString()),
      caption: (map['caption'] ?? '').toString().trim(),
      isCover: map['isCover'] == true,
      sortOrder: map['sortOrder'] is num
          ? (map['sortOrder'] as num).toInt()
          : int.tryParse(map['sortOrder']?.toString() ?? '') ?? 0,
      status: _normalizeStatus(map['status']?.toString()),
    );
  }

  static String _normalizeCategory(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    return switch (normalized) {
      'cover' || 'hero' || 'hero_image' => 'cover',
      'interior' => 'interior',
      'drinks' || 'drink' => 'drinks',
      'food' => 'food',
      'events' || 'event' => 'events',
      'atmosphere' || 'ambience' || 'ambiance' => 'atmosphere',
      _ => 'other',
    };
  }

  static String _normalizeStatus(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'hidden' => 'hidden',
      'deleted' => 'deleted',
      _ => 'active',
    };
  }
}
