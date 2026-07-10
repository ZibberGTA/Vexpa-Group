import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Admin-only onboarding/claim directory venue record.
///
/// This is intentionally separate from the public live `venues` model because
/// `venue_claim_directory` is an operational dataset used by Vexda staff.
class AdminClaimVenue {
  const AdminClaimVenue({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.region,
    required this.postcode,
    required this.claimStatus,
    required this.latitude,
    required this.longitude,
    required this.rawData,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final String region;
  final String postcode;
  final String claimStatus;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> rawData;

  LatLng get position => LatLng(latitude, longitude);

  bool get isClaimed {
    final status = claimStatus.toLowerCase();
    return status == 'claimed' || status == 'approved' || status == 'verified';
  }

  bool get isPending {
    final status = claimStatus.toLowerCase();
    return status == 'pending' || status == 'in_review' || status == 'review';
  }

  bool get isRejected => claimStatus.toLowerCase() == 'rejected';

  bool get isUnclaimed => !isClaimed && !isPending && !isRejected;

  String get locationLabel {
    final parts = [address, city, postcode]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part != '—')
        .toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  factory AdminClaimVenue.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AdminClaimVenue.fromMap(doc.id, doc.data());
  }

  factory AdminClaimVenue.fromMap(String id, Map<String, dynamic> data) {
    final latitude =
        _readDouble(data, const ['latitude', 'lat', 'geoLat', 'locationLat']) ??
        _readGeoPoint(data, const [
          'location',
          'coordinates',
          'geoPoint',
          'geopoint',
          'position',
        ])?.latitude;

    final longitude =
        _readDouble(data, const [
          'longitude',
          'lng',
          'lon',
          'geoLng',
          'geoLon',
          'locationLng',
        ]) ??
        _readGeoPoint(data, const [
          'location',
          'coordinates',
          'geoPoint',
          'geopoint',
          'position',
        ])?.longitude;

    return AdminClaimVenue(
      id: id,
      name: _readString(data, const [
        'name',
        'venueName',
        'businessName',
        'title',
        'displayName',
      ], fallback: 'Unnamed Venue'),
      category: _readString(data, const [
        'category',
        'venueType',
        'type',
        'primaryCategory',
      ], fallback: 'Venue'),
      address: _readString(data, const [
        'address',
        'fullAddress',
        'formattedAddress',
        'addressLine1',
        'streetAddress',
      ]),
      city: _readString(data, const ['city', 'town', 'locality', 'postalTown']),
      region: _readString(data, const ['region', 'county', 'area', 'state']),
      postcode: _readString(data, const ['postcode', 'postalCode', 'zip']),
      claimStatus: _normaliseClaimStatus(data),
      latitude: latitude ?? double.nan,
      longitude: longitude ?? double.nan,
      rawData: data,
    );
  }

  bool get hasValidCoordinates {
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  static String _normaliseClaimStatus(Map<String, dynamic> data) {
    final explicit = _readString(data, const [
      'claimStatus',
      'claimedStatus',
      'status',
      'verificationStatus',
    ], fallback: '').toLowerCase();
    if (explicit.isNotEmpty && explicit != '—') return explicit;

    final ownerId = _readString(data, const ['ownerId', 'ownerUid']);
    final claimant = _readString(data, const ['claimedBy', 'claimantUid']);
    final verified = data['isVerified'] == true || data['verified'] == true;
    if (ownerId != '—' || claimant != '—' || verified) return 'claimed';
    return 'unclaimed';
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final value = data[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
    }
    return null;
  }

  static GeoPoint? _readGeoPoint(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is GeoPoint) return value;
      if (value is Map) {
        final lat = _readDouble(Map<String, dynamic>.from(value), const [
          'latitude',
          'lat',
        ]);
        final lng = _readDouble(Map<String, dynamic>.from(value), const [
          'longitude',
          'lng',
          'lon',
        ]);
        if (lat != null && lng != null) return GeoPoint(lat, lng);
      }
    }
    return null;
  }
}
