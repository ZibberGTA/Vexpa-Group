import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_engines/trail/trail_engine.dart';

/// Loads venue geofence inputs for trail check-in assessment.
class FirebaseTrailVenueLookupAdapter implements TrailVenueLookupPort {
  FirebaseTrailVenueLookupAdapter({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  static const defaultPresenceRadiusMeters = 75.0;

  @override
  Future<TrailVenuePresence?> lookup(String venueId) async {
    try {
      final doc = await _db.collection('venues').doc(venueId.trim()).get();
      final data = doc.data();
      if (data == null) return null;

      final location = data['location'];
      double? latitude;
      double? longitude;
      if (location is GeoPoint) {
        latitude = location.latitude;
        longitude = location.longitude;
      }

      final radiusRaw = data['presenceRadiusMeters'];
      final radius = (radiusRaw as num?)?.toDouble();

      return TrailVenuePresence(
        venueId: venueId,
        latitude: latitude,
        longitude: longitude,
        presenceRadiusMeters: radius ?? defaultPresenceRadiusMeters,
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[FirebaseTrailVenueLookupAdapter] lookup failed: $error');
      }
      return null;
    }
  }
}
