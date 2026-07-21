import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:intl/intl.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

import '../../../core/utils/public_venue_visibility.dart';
import '../../home/models/deal_model.dart';
import '../../home/models/event_model.dart';
import '../../../core/utils/venue_branding_parser.dart';
import '../models/discover_models.dart';
import '../utils/discover_nearest_results.dart';

class DiscoverLocationResolution {
  const DiscoverLocationResolution._({
    required this.status,
    this.latitude,
    this.longitude,
  });

  final DiscoverLoadStatus status;
  final double? latitude;
  final double? longitude;

  bool get isResolved => latitude != null && longitude != null;

  factory DiscoverLocationResolution.resolved({
    required double latitude,
    required double longitude,
  }) {
    return DiscoverLocationResolution._(
      status: DiscoverLoadStatus.success,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory DiscoverLocationResolution.failure(DiscoverLoadStatus status) {
    return DiscoverLocationResolution._(status: status);
  }
}

class DiscoverFilterService {
  DiscoverFilterService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> publicVenueDocs({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    final eligible = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in docs) {
      if (!PublicVenueVisibility.isPublicMap(doc.data())) continue;
      final location = doc.data()['location'];
      if (location is! GeoPoint) continue;
      eligible.add(doc);
    }
    return eligible;
  }

  static Future<DiscoverLocationResolution> resolveUserLocation({
    double? cachedLatitude,
    double? cachedLongitude,
  }) async {
    if (cachedLatitude != null && cachedLongitude != null) {
      return DiscoverLocationResolution.resolved(
        latitude: cachedLatitude,
        longitude: cachedLongitude,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return DiscoverLocationResolution.failure(
        DiscoverLoadStatus.locationDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return DiscoverLocationResolution.failure(
        DiscoverLoadStatus.locationDenied,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return DiscoverLocationResolution.resolved(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Object {
      return DiscoverLocationResolution.failure(
        DiscoverLoadStatus.locationUnavailable,
      );
    }
  }

  static Future<DiscoverLoadState> loadForFilter({
    required DiscoverFilter filter,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> venueDocs,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final location = await resolveUserLocation(
        cachedLatitude: userLatitude,
        cachedLongitude: userLongitude,
      );

      if (!location.isResolved) {
        return DiscoverLoadState(status: location.status);
      }

      final eligibleDocs = publicVenueDocs(docs: venueDocs);
      final latitude = location.latitude!;
      final longitude = location.longitude!;

      switch (filter) {
        case DiscoverFilter.deals:
          return _loadDeals(eligibleDocs, latitude, longitude);
        case DiscoverFilter.events:
          return _loadEvents(eligibleDocs, latitude, longitude);
        case DiscoverFilter.venues:
          return _loadVenues(eligibleDocs, latitude, longitude);
      }
    } on Object catch (error) {
      return DiscoverLoadState(
        status: DiscoverLoadStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  static Future<DiscoverLoadState> _loadDeals(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> venueDocs,
    double userLatitude,
    double userLongitude,
  ) async {
    if (venueDocs.isEmpty) {
      return const DiscoverLoadState(status: DiscoverLoadStatus.empty);
    }

    final venueById = {for (final doc in venueDocs) doc.id: doc};
    final dealsByVenue = await _loadActiveDealsForVenueIds(
      venueById.keys.toSet(),
    );
    if (dealsByVenue.isEmpty) {
      return const DiscoverLoadState(status: DiscoverLoadStatus.empty);
    }

    final results = <DiscoverVenueResult>[];
    for (final entry in dealsByVenue.entries) {
      final doc = venueById[entry.key];
      if (doc == null) continue;
      final result = _resultFromVenueDoc(
        doc,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        dealTitle: entry.value.title,
        dealAvailability: _dealAvailabilityLabel(entry.value),
      );
      if (result.distanceMeters == null) continue;
      results.add(result);
    }

    results.sort(DiscoverNearestResults.compareByDistanceThenName);

    final limited = DiscoverNearestResults.limit(results);

    return DiscoverLoadState(
      status: limited.isEmpty
          ? DiscoverLoadStatus.empty
          : DiscoverLoadStatus.success,
      results: limited,
      dealVenueIds: limited.map((result) => result.venueId).toSet(),
    );
  }

  static Future<DiscoverLoadState> _loadEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> venueDocs,
    double userLatitude,
    double userLongitude,
  ) async {
    if (venueDocs.isEmpty) {
      return const DiscoverLoadState(status: DiscoverLoadStatus.empty);
    }

    final venueById = {for (final doc in venueDocs) doc.id: doc};
    final eventsByVenue = await _loadUpcomingEventsForVenueIds(
      venueById.keys.toSet(),
    );
    if (eventsByVenue.isEmpty) {
      return const DiscoverLoadState(status: DiscoverLoadStatus.empty);
    }

    final results = <DiscoverVenueResult>[];
    for (final entry in eventsByVenue.entries) {
      final doc = venueById[entry.key];
      if (doc == null) continue;
      final event = entry.value;
      final result = _resultFromVenueDoc(
        doc,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        eventTitle: event.title,
        eventStart: event.startDateTime,
        eventStatusLabel: _eventStatusLabel(event.startDateTime),
      );
      if (result.distanceMeters == null) continue;
      results.add(result);
    }

    results.sort(DiscoverNearestResults.compareByDistanceThenEventThenName);

    final limited = DiscoverNearestResults.limit(results);

    return DiscoverLoadState(
      status: limited.isEmpty
          ? DiscoverLoadStatus.empty
          : DiscoverLoadStatus.success,
      results: limited,
      eventVenueIds: limited.map((result) => result.venueId).toSet(),
    );
  }

  static Future<DiscoverLoadState> _loadVenues(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> venueDocs,
    double userLatitude,
    double userLongitude,
  ) async {
    if (venueDocs.isEmpty) {
      return const DiscoverLoadState(status: DiscoverLoadStatus.empty);
    }

    final results = <DiscoverVenueResult>[];
    for (final doc in venueDocs) {
      final result = _resultFromVenueDoc(
        doc,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      if (result.distanceMeters == null) continue;
      results.add(result);
    }

    results.sort(DiscoverNearestResults.compareByDistanceThenName);

    final limited = DiscoverNearestResults.limit(results);

    return DiscoverLoadState(
      status: limited.isEmpty
          ? DiscoverLoadStatus.empty
          : DiscoverLoadStatus.success,
      results: limited,
    );
  }

  static DiscoverVenueResult _resultFromVenueDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required double userLatitude,
    required double userLongitude,
    String? dealTitle,
    String? dealAvailability,
    String? eventTitle,
    DateTime? eventStart,
    String? eventStatusLabel,
  }) {
    final data = doc.data();
    final location = data['location'] as GeoPoint?;
    final distanceMeters = location == null
        ? null
        : Geolocator.distanceBetween(
            userLatitude,
            userLongitude,
            location.latitude,
            location.longitude,
          );

    return DiscoverVenueResult(
      venueId: doc.id,
      venueName: (data['name'] ?? '').toString(),
      venueData: data,
      distanceMeters: distanceMeters,
      rating: (data['averageRating'] as num?)?.toDouble(),
      isOpen: _parseOpenStatus(data),
      imageUrl: VenueBrandingParser.resolveBannerImageUrl(data).isNotEmpty
          ? VenueBrandingParser.resolveBannerImageUrl(data)
          : VenueBrandingParser.resolveLogoUrl(data),
      dealTitle: dealTitle,
      dealAvailability: dealAvailability,
      eventTitle: eventTitle,
      eventStart: eventStart,
      eventStatusLabel: eventStatusLabel,
      category: (data['category'] ?? data['venueType'] ?? '').toString(),
    );
  }

  static bool? _parseOpenStatus(Map<String, dynamic> data) {
    final openNow = data['openNow'];
    if (openNow is bool) return openNow;
    return null;
  }

  static String _dealAvailabilityLabel(DealModel deal) {
    final end = deal.effectiveEndDateTime;
    if (end == null) return 'Available now';
    return 'Until ${DateFormat.jm().format(end)}';
  }

  static String _eventStatusLabel(DateTime start) {
    final now = DateTime.now();
    if (_isSameLocalDay(now, start)) return 'Tonight';
    if (start.isBefore(now.add(const Duration(hours: 2)))) {
      return 'Starting soon';
    }
    return DateFormat('EEE d MMM').format(start);
  }

  static bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<Map<String, DealModel>> _loadActiveDealsForVenueIds(
    Set<String> eligibleVenueIds,
  ) async {
    if (eligibleVenueIds.isEmpty) return {};

    final snapshot = await _db
        .collection('deals')
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .get();

    final result = <String, DealModel>{};
    for (final doc in snapshot.docs) {
      final deal = DealModel.fromMap(doc.id, doc.data());
      if (!deal.isCurrentlyVisible) continue;
      if (!eligibleVenueIds.contains(deal.venueId)) continue;
      result.putIfAbsent(deal.venueId, () => deal);
    }
    return result;
  }

  static Future<Map<String, EventModel>> _loadUpcomingEventsForVenueIds(
    Set<String> eligibleVenueIds,
  ) async {
    if (eligibleVenueIds.isEmpty) return {};

    final now = DateTime.now();
    final snapshot = await _db
        .collection('events')
        .where('isDeleted', isEqualTo: false)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    final result = <String, EventModel>{};
    for (final doc in snapshot.docs) {
      final event = EventModel.fromDoc(doc);
      if (!eligibleVenueIds.contains(event.venueId)) continue;
      if (!ExperienceEventVisibility.isPublicVisible(
        isDeleted: event.isDeleted,
        isActive: event.isActive,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        now: now,
      )) {
        continue;
      }

      final existing = result[event.venueId];
      if (existing == null ||
          event.startDateTime.isBefore(existing.startDateTime)) {
        result[event.venueId] = event;
      }
    }

    return result;
  }
}
