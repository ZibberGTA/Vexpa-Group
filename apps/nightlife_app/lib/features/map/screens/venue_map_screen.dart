import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vex_engines/discovery/shared/discovery_geo_utils.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';

import '../../../core/utils/venue_branding_parser.dart';
import '../../../core/config/app_config.dart';
import '../../../core/map/dark_map_style.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/widgets/venue_map_marker.dart';

import '../../crowd/utils/crowd_decay.dart';
import '../../crowd/services/smart_crowd_service.dart';
import '../../home/models/event_model.dart';
import '../../home/services/deal_service.dart';
import '../../home/services/event_service.dart';
import '../../analytics/services/analytics_service.dart';
import '../../favourites/services/favourites_service.dart';
import '../../home/models/venue_model.dart';
import '../../home/models/deal_model.dart';
import '../../home/services/experience_content_support.dart';
import '../../venues/screens/venue_details_screen.dart';
import '../../trails/screens/tonights_trail_screen.dart';
import '../../trails/models/trail_model.dart';
import '../../trails/services/trail_service.dart';
import '../../startup/services/startup_cache.dart';

class VenueMapPendingRoute {
  const VenueMapPendingRoute({
    required this.venueId,
    this.trail,
    this.trailStop,
    this.trailStopIndex,
  });

  final String venueId;
  final DrinkSpotTrailModel? trail;
  final TrailStopModel? trailStop;
  final int? trailStopIndex;
}

class VenueMapScreen extends StatefulWidget {
  const VenueMapScreen({
    super.key,
    this.initialRouteVenueId,
    this.initialTrail,
    this.initialTrailStop,
    this.initialTrailStopIndex,
    this.onNavigationModeChanged,
  });

  /// Optional venue id used when another feature, such as Tonight's Trail,
  /// asks the map to open with directions ready. Routing is still user-initiated
  /// because this value is only supplied after the user taps a Directions button.
  final String? initialRouteVenueId;
  final DrinkSpotTrailModel? initialTrail;
  final TrailStopModel? initialTrailStop;
  final int? initialTrailStopIndex;
  final ValueChanged<bool>? onNavigationModeChanged;

  static final ValueNotifier<VenueMapPendingRoute?> pendingRoute =
      ValueNotifier<VenueMapPendingRoute?>(null);

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

enum _NavigationHudCheckInState { idle, checkedIn, readyForNext, trailComplete }

class _VenueMapScreenState extends State<VenueMapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _venuesFuture;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _allVenuesStream =
      FirebaseFirestore.instance
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .snapshots();
  final Map<String, BitmapDescriptor> _markerIconCache =
      <String, BitmapDescriptor>{};
  Future<Set<Marker>>? _markersFuture;
  String? _markersFutureKey;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestVenueDocs = const [];
  Set<String> _venueIdsWithEventsInViewToday = <String>{};
  String? _lastEventViewportKey;
  bool _eventViewportRefreshInProgress = false;

  Timer? _searchDebounce;
  Timer? _pulseTimer;
  double _pulsePhase = 0;

  static const LatLng _defaultCenter = LatLng(51.5074, -0.1278);

  String searchText = '';
  bool _satelliteView = false;
  LatLng _lastCameraTarget = _defaultCenter;
  double _lastCameraZoom = 13;
  Set<Polyline> _routePolylines = const <Polyline>{};
  String? _routeSummary;
  bool _routeLoading = false;
  bool _liveNavigationActive = false;
  VenueModel? _routeVenue;
  LatLng? _routeDestination;
  int? _routeInitialDistanceMeters;
  int? _routeInitialDurationSeconds;
  int? _routeRemainingMeters;
  int? _routeRemainingSeconds;
  bool _routeArrived = false;
  bool _checkingInFromHud = false;
  DrinkSpotTrailModel? _routeTrail;
  TrailStopModel? _routeTrailStop;
  int? _routeTrailStopIndex;
  String? _routeTrailStopLabel;
  String? _routeDiscountLabel;
  StreamSubscription<Position>? _liveNavigationSubscription;
  Timer? _navigationHudCheckInTimer;
  _NavigationHudCheckInState _navigationHudCheckInState =
      _NavigationHudCheckInState.idle;
  bool _navigationHudExpanded = false;
  bool _initialRouteStarted = false;
  List<DrinkSpotTrailModel> _lastVisibleTrails = const [];
  late final Stream<List<DrinkSpotTrailModel>> _visibleTrailsStream =
      TrailService.watchVisibleTrails();

  @override
  void initState() {
    super.initState();
    _venuesFuture = _loadVenues();
    VenueMapScreen.pendingRoute.addListener(_onPendingRouteChanged);
    // Keep map rendering light: do not pulse/rebuild map overlays on a timer.
  }

  @override
  void dispose() {
    widget.onNavigationModeChanged?.call(false);
    VenueMapScreen.pendingRoute.removeListener(_onPendingRouteChanged);
    _pulseTimer?.cancel();
    _searchDebounce?.cancel();
    _liveNavigationSubscription?.cancel();
    _navigationHudCheckInTimer?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setLiveNavigationActive(bool active) {
    if (_liveNavigationActive == active) return;
    _liveNavigationActive = active;
    widget.onNavigationModeChanged?.call(active);
  }

  void _onPendingRouteChanged() {
    final route = VenueMapScreen.pendingRoute.value;
    if (route == null) return;

    VenueMapScreen.pendingRoute.value = null;
    _startInAppDirectionsForVenueId(
      route.venueId,
      trail: route.trail,
      stop: route.trailStop,
      stopIndex: route.trailStopIndex,
    );
  }

  List<String> _termsFromSearch(String value) {
    return SearchTextUtils.termsFromQuery(value);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadVenues() async {
    final firestore = FirebaseFirestore.instance;
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .get();

      return snapshot.docs;
    }

    final terms = _termsFromSearch(query);

    if (terms.isEmpty) {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .get();

      return snapshot.docs;
    }

    final matchingVenueIds = <String>{};

    final venueSnapshot = await firestore
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in venueSnapshot.docs) {
      matchingVenueIds.add(doc.id);
    }

    final drinkSnapshot = await firestore
        .collection('drinks')
        .where('isDeleted', isEqualTo: false)
        .where('available', isEqualTo: true)
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in drinkSnapshot.docs) {
      final venueId = doc.data()['venueId']?.toString();
      if (venueId != null && venueId.isNotEmpty) {
        matchingVenueIds.add(venueId);
      }
    }

    final dealSnapshot = await firestore
        .collection('deals')
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in dealSnapshot.docs) {
      final deal = DealModel.fromMap(doc.id, doc.data());
      if (!deal.isCurrentlyVisible) continue;
      final venueId = doc.data()['venueId']?.toString();
      if (venueId != null && venueId.isNotEmpty) {
        matchingVenueIds.add(venueId);
      }
    }

    if (matchingVenueIds.isEmpty) {
      return [];
    }

    final venueDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final ids = matchingVenueIds.toList();

    for (var i = 0; i < ids.length; i += 10) {
      final batchIds = ids.skip(i).take(10).toList();

      final snapshot = await firestore
          .collection('venues')
          .where(FieldPath.documentId, whereIn: batchIds)
          .where('isDeleted', isEqualTo: false)
          .get();

      venueDocs.addAll(snapshot.docs);
    }

    return venueDocs;
  }

  bool _isLocationInsideBounds(GeoPoint point, LatLngBounds bounds) {
    return DiscoveryMapBounds.contains(
      latitude: point.latitude,
      longitude: point.longitude,
      bounds: DiscoveryLatLngBounds(
        southLatitude: bounds.southwest.latitude,
        westLongitude: bounds.southwest.longitude,
        northLatitude: bounds.northeast.latitude,
        eastLongitude: bounds.northeast.longitude,
      ),
    );
  }

  String _viewportKeyFor({
    required LatLngBounds bounds,
    required List<String> venueIds,
  }) {
    final day = DateTime.now();
    return [
      '${day.year}-${day.month}-${day.day}',
      bounds.southwest.latitude.toStringAsFixed(3),
      bounds.southwest.longitude.toStringAsFixed(3),
      bounds.northeast.latitude.toStringAsFixed(3),
      bounds.northeast.longitude.toStringAsFixed(3),
      venueIds.length,
      venueIds.take(40).join(','),
    ].join('|');
  }

  Future<Set<String>> _loadVenueIdsWithEventsTodayForVenueIds(
    List<String> venueIds,
  ) async {
    if (venueIds.isEmpty) return <String>{};

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final result = <String>{};
    final firestore = FirebaseFirestore.instance;

    for (var i = 0; i < venueIds.length; i += 10) {
      final batchIds = venueIds.skip(i).take(10).toList();
      if (batchIds.isEmpty) continue;

      final snapshot = await firestore
          .collection('events')
          .where('venueId', whereIn: batchIds)
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('dateTime', isLessThan: Timestamp.fromDate(startOfTomorrow))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue;
        if (data['isActive'] == false) continue;
        final endTimestamp = data['endDateTime'] as Timestamp?;
        final startTimestamp =
            data['startDateTime'] as Timestamp? ??
            data['dateTime'] as Timestamp?;
        final endDate =
            endTimestamp?.toDate() ??
            (startTimestamp == null
                ? null
                : startTimestamp.toDate().add(const Duration(hours: 24)));
        if (endDate == null || endDate.isBefore(now)) continue;
        final venueId = data['venueId']?.toString().trim() ?? '';
        if (venueId.isNotEmpty) {
          result.add(venueId);
        }
      }
    }

    return result;
  }

  Future<void> _refreshEventGlowForVisibleVenues() async {
    if (_mapController == null || _eventViewportRefreshInProgress) return;
    final docs = _latestVenueDocs;
    if (docs.isEmpty) return;

    final bounds = await _mapController!.getVisibleRegion();
    final visibleVenueIds = <String>[];

    for (final doc in docs) {
      final location = doc.data()['location'];
      if (location is! GeoPoint) continue;
      if (_isLocationInsideBounds(location, bounds)) {
        visibleVenueIds.add(doc.id);
      }
    }

    final cappedVenueIds = visibleVenueIds.take(500).toList();
    final viewportKey = _viewportKeyFor(
      bounds: bounds,
      venueIds: cappedVenueIds,
    );
    if (_lastEventViewportKey == viewportKey) return;

    _lastEventViewportKey = viewportKey;
    _eventViewportRefreshInProgress = true;

    try {
      final eventVenueIds = await _loadVenueIdsWithEventsTodayForVenueIds(
        cappedVenueIds,
      );
      if (!mounted) return;
      setState(() {
        _venueIdsWithEventsInViewToday = eventVenueIds;
        _markersFuture = null;
        _markersFutureKey = null;
      });
    } catch (_) {
      // Keep map stable if the event lookup/index is unavailable.
    } finally {
      _eventViewportRefreshInProgress = false;
    }
  }

  String _markersKeyForDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final parts = <String>[];
    for (final doc in docs) {
      final data = doc.data();
      final location = data['location'];
      if (location is! GeoPoint) continue;
      final crowd = CrowdDecay.displayLevel(
        level:
            (data['currentCrowdLevel'] ?? data['crowdLevel'])?.toString() ?? '',
        updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
      );
      parts.add(
        [
          doc.id,
          location.latitude.toStringAsFixed(5),
          location.longitude.toStringAsFixed(5),
          VenueBrandingParser.resolveLogoUrl(data),
          VenueBrandingParser.resolveBannerImageUrl(data),
          crowd,
          _venueIdsWithEventsInViewToday.contains(doc.id) ? 'event' : 'noevent',
        ].join('~'),
      );
    }
    return parts.join('|');
  }

  Future<Set<Marker>> _markersForDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final key = _markersKeyForDocs(docs);
    if (_markersFuture != null && _markersFutureKey == key) {
      return _markersFuture!;
    }

    _markersFutureKey = key;
    _markersFuture = _buildMarkers(docs);
    return _markersFuture!;
  }

  Future<Set<Marker>> _buildMarkers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final markers = <Marker>{};

    for (final doc in docs) {
      final data = doc.data();
      final location = data['location'];

      if (location is! GeoPoint) continue;

      final venue = VenueModel.fromMap(doc.id, data);

      final displayCrowd = CrowdDecay.displayLevel(
        level: venue.crowdLevel,
        updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
      );

      final markerImageUrl = venue.logoUrl.trim().isNotEmpty
          ? venue.logoUrl
          : venue.bannerImageUrl;

      final hasEventToday = _venueIdsWithEventsInViewToday.contains(venue.id);
      final crowdShouldGlow =
          displayCrowd.toLowerCase() == 'busy' ||
          displayCrowd.toLowerCase() == 'packed';
      final markerCacheKey =
          '${venue.id}|$markerImageUrl|$displayCrowd|eventToday:$hasEventToday';

      final markerIcon =
          _markerIconCache[markerCacheKey] ??
          BitmapDescriptor.fromBytes(
            await VenueMapMarker.create(
              venueId: venue.id,
              venueName: venue.name,
              imageUrl: markerImageUrl,
              glow: hasEventToday || crowdShouldGlow,
              glowColor: hasEventToday ? const Color(0xFF00E5FF) : null,
              size: 200,
            ),
          );

      _markerIconCache[markerCacheKey] = markerIcon;
      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(location.latitude, location.longitude),
          icon: markerIcon,
          anchor: const Offset(0.5, 0.92),
          infoWindow: InfoWindow.noText,
          onTap: () {
            AnalyticsService.logVenueView(venue.id);
            _showVenuePreview(
              venue: venue,
              updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
            );
          },
        ),
      );
    }

    return markers;
  }

  static const List<String> _openingDayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  _VenueOpeningStatus _openingStatusFor(VenueModel venue) {
    final hours = venue.openingHours;
    if (hours.isEmpty) {
      return const _VenueOpeningStatus(
        label: '',
        hasHours: false,
        isOpen: false,
      );
    }

    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final nowMinutes = now.hour * 60 + now.minute;

    Map<String, dynamic>? dayData(int index) {
      final value = hours[_openingDayKeys[index % 7]];
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    int? parseMinutes(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      final parts = text.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return hour * 60 + minute;
    }

    bool isClosed(Map<String, dynamic>? data) =>
        data == null || data['closed'] == true || data['isClosed'] == true;

    String formatMinutes(int minutes) {
      final normalized = minutes % (24 * 60);
      final hour24 = normalized ~/ 60;
      final minute = normalized % 60;
      final suffix = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      return '$hour12:${minute.toString().padLeft(2, "0")} $suffix';
    }

    final today = dayData(todayIndex);
    final yesterday = dayData((todayIndex + 6) % 7);

    if (!isClosed(yesterday)) {
      final yOpen = parseMinutes(yesterday?['open']);
      final yClose = parseMinutes(yesterday?['close']);
      if (yOpen != null &&
          yClose != null &&
          yClose <= yOpen &&
          nowMinutes < yClose) {
        return _VenueOpeningStatus(
          label: 'Open • Closes ${formatMinutes(yClose)}',
          hasHours: true,
          isOpen: true,
        );
      }
    }

    if (!isClosed(today)) {
      final open = parseMinutes(today?['open']);
      final close = parseMinutes(today?['close']);
      if (open != null && close != null) {
        final openNow = close <= open
            ? nowMinutes >= open || nowMinutes < close
            : nowMinutes >= open && nowMinutes < close;
        if (openNow) {
          return _VenueOpeningStatus(
            label: 'Open • Closes ${formatMinutes(close)}',
            hasHours: true,
            isOpen: true,
          );
        }
        if (nowMinutes < open) {
          return _VenueOpeningStatus(
            label: 'Closed • Opens ${formatMinutes(open)}',
            hasHours: true,
            isOpen: false,
          );
        }
      }
    }

    for (var offset = 1; offset <= 7; offset++) {
      final index = (todayIndex + offset) % 7;
      final data = dayData(index);
      if (isClosed(data)) continue;
      final open = parseMinutes(data?['open']);
      if (open == null) continue;
      final dayLabel = offset == 1
          ? 'tomorrow'
          : _openingDayKeys[index][0].toUpperCase() +
                _openingDayKeys[index].substring(1);
      return _VenueOpeningStatus(
        label: 'Closed • Opens $dayLabel ${formatMinutes(open)}',
        hasHours: true,
        isOpen: false,
      );
    }

    return const _VenueOpeningStatus(
      label: 'Closed',
      hasHours: true,
      isOpen: false,
    );
  }

  IconData? _venueTagIcon(String label) {
    switch (label.trim().toLowerCase()) {
      case 'live music':
        return Icons.music_note_rounded;
      case 'dj':
        return Icons.graphic_eq_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'karaoke':
        return Icons.mic_external_on_rounded;
      case 'quiz night':
      case 'quiz':
        return Icons.quiz_rounded;
      case 'dance floor':
        return Icons.nightlife_rounded;
      case 'food served':
        return Icons.restaurant_rounded;
      case 'outdoor seating':
      case 'outdoor':
        return Icons.deck_rounded;
      default:
        return null;
    }
  }

  List<String> _venuePreviewTags(VenueModel venue) =>
      MobileExperienceContentSupport.publicPresentation.venuePreviewTags(
        featureTags: venue.featureTags,
        formatTagLabel: MobileExperienceContentSupport.presentation.formatVenueTagLabel,
      );

  void _showVenuePreview({
    required VenueModel venue,
    required dynamic updatedAt,
  }) {
    final displayCrowd = CrowdDecay.displayLevel(
      level: venue.crowdLevel,
      updatedAt: updatedAt,
    );
    final crowdLabel = _displayCrowdLevel(displayCrowd);
    final openingStatus = _openingStatusFor(venue);
    final venueTags = _venuePreviewTags(venue);
    final bannerUrl = venue.bannerImageUrl.trim();
    final logoUrl = venue.logoUrl.trim();
    final firstLetter = venue.name.trim().isNotEmpty
        ? venue.name.trim()[0].toUpperCase()
        : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withOpacity(0.18),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xB3111218),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primaryPink.withOpacity(0.82),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.18),
                    blurRadius: 26,
                    offset: const Offset(0, -6),
                  ),
                  const BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: const Color(0xFF07070D),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppColors.primaryPurple.withOpacity(
                                    0.55,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPurple.withOpacity(
                                      0.16,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(21),
                                child: bannerUrl.isNotEmpty
                                    ? Image.network(
                                        bannerUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _MapVenueLogoFallback(
                                              letter: firstLetter,
                                            ),
                                      )
                                    : logoUrl.isNotEmpty
                                    ? Container(
                                        color: const Color(0xFF07070D),
                                        padding: const EdgeInsets.all(14),
                                        child: Image.network(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              _MapVenueLogoFallback(
                                                letter: firstLetter,
                                              ),
                                        ),
                                      )
                                    : _MapVenueLogoFallback(
                                        letter: firstLetter,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      venue.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 28,
                                        height: 1.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryPink,
                                          AppColors.primaryPurple,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryPink
                                              .withOpacity(0.30),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      crowdLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              _MapPreviewInfoRow(
                                icon: Icons.storefront_outlined,
                                text: venue.category.isEmpty
                                    ? 'Venue'
                                    : venue.category,
                              ),
                              if (openingStatus.hasHours) ...[
                                const SizedBox(height: 6),
                                _MapOpeningStatusRow(status: openingStatus),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (venueTags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 0,
                          alignment: WrapAlignment.start,
                          children: venueTags.map((tag) {
                            return _MapVenueChip(
                              icon: _venueTagIcon(tag),
                              label: tag,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.028),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          _MapCardActionButton(
                            tooltip: 'Directions',
                            icon: Icons.directions_walk_rounded,
                            iconColor: AppColors.textPrimary,
                            onTap: () {
                              Navigator.pop(context);
                              _startInAppDirections(venue);
                            },
                          ),
                          const SizedBox(width: 8),
                          _MapCardActionButton(
                            tooltip: 'Call venue',
                            icon: Icons.phone_rounded,
                            iconColor: AppColors.textPrimary,
                            onTap: () => _callVenue(venue.phone),
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<bool>(
                            stream: FavouritesService.isFavouriteStream(
                              venue.id,
                            ),
                            builder: (context, snapshot) {
                              final isFavourite = snapshot.data ?? false;
                              return _MapCardActionButton(
                                tooltip: isFavourite
                                    ? 'Remove saved venue'
                                    : 'Save venue',
                                icon: isFavourite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: isFavourite
                                    ? AppColors.primaryPink
                                    : AppColors.textPrimary,
                                onTap: () async {
                                  try {
                                    await FavouritesService.toggleFavourite(
                                      venueId: venue.id,
                                      venueName: venue.name,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VenueDetailsScreen(venueId: venue.id),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryPink,
                                      AppColors.primaryPurple,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple
                                          .withOpacity(0.26),
                                      blurRadius: 18,
                                      offset: const Offset(0, 9),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'View Venue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _markerHue(String crowd) {
    switch (crowd.toLowerCase()) {
      case 'quiet':
        return BitmapDescriptor.hueGreen;
      case 'steady':
      case 'medium':
      case 'lively':
        return BitmapDescriptor.hueOrange;
      case 'busy':
        return BitmapDescriptor.hueRed;
      case 'packed':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Set<Circle> _buildCrowdGlow(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final circles = <Circle>{};

    for (final doc in docs) {
      final data = doc.data();
      final location = data['location'];
      if (location is! GeoPoint) continue;

      final venue = VenueModel.fromMap(doc.id, data);
      final displayCrowd = CrowdDecay.displayLevel(
        level: venue.crowdLevel,
        updatedAt: data['crowdUpdatedAt'] ?? data['updatedAt'],
      ).toLowerCase();

      final color = _glowColor(displayCrowd);
      if (color == null) continue;

      circles.add(
        Circle(
          circleId: CircleId('glow_${doc.id}'),
          center: LatLng(location.latitude, location.longitude),
          radius: displayCrowd == 'packed' ? 165 : 115,
          fillColor: color.withOpacity(displayCrowd == 'packed' ? 0.20 : 0.14),
          strokeColor: color.withOpacity(0.30),
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  Color? _glowColor(String crowd) {
    switch (crowd.toLowerCase()) {
      case 'busy':
        return Colors.deepOrange;
      case 'packed':
        return Colors.purple;
      default:
        return null;
    }
  }

  String _displayCrowdLevel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'quiet':
        return 'Relaxed';
      case 'medium':
      case 'steady':
        return 'Steady';
      case 'busy':
        return 'Buzzing';
      case 'packed':
        return 'Lively';
      default:
        if (value.isEmpty) return 'Unknown';
        return value[0].toUpperCase() + value.substring(1).toLowerCase();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      setState(() {
        searchText = value.trim().toLowerCase();
        _venuesFuture = _loadVenues();
      });
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      searchText = '';
      _venuesFuture = _loadVenues();
    });
  }

  String get _googleRoutesApiKey => AppConfig.routesApiKey;

  Future<LatLng?> _getCurrentLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are switched off.')),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is needed for in-app directions.'),
        ),
      );
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _startInAppDirectionsForVenueId(
    String venueId, {
    DrinkSpotTrailModel? trail,
    TrailStopModel? stop,
    int? stopIndex,
  }) async {
    if (venueId.trim().isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This trail venue could not be found.')),
        );
        return;
      }

      final venue = VenueModel.fromMap(
        doc.id,
        doc.data() ?? const <String, dynamic>{},
      );
      await _startInAppDirections(
        venue,
        trail: trail ?? widget.initialTrail,
        stop: stop ?? widget.initialTrailStop,
        stopIndex: stopIndex ?? widget.initialTrailStopIndex,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load trail venue directions: $e')),
      );
    }
  }

  Future<void> _startInAppDirections(
    VenueModel venue, {
    DrinkSpotTrailModel? trail,
    TrailStopModel? stop,
    int? stopIndex,
  }) async {
    _navigationHudCheckInTimer?.cancel();
    _navigationHudCheckInTimer = null;

    final destination = venue.location;
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This venue does not have a map location.'),
        ),
      );
      return;
    }

    setState(() {
      _routeLoading = true;
      _routeSummary = 'Finding route to ${venue.name}...';
      _routeVenue = venue;
      _routeTrail = trail;
      _routeTrailStop = stop;
      _routeTrailStopIndex = stopIndex;
      _routeTrailStopLabel = trail != null && stopIndex != null
          ? 'Trail Stop ${stopIndex + 1} / ${trail.stops.length}'
          : null;
      _routeDiscountLabel = stop?.discountLabel.trim().isNotEmpty == true
          ? stop!.discountLabel.trim()
          : null;
      _routeArrived = false;
      _routeRemainingMeters = null;
      _routeRemainingSeconds = null;
      _navigationHudCheckInState = _NavigationHudCheckInState.idle;
      _navigationHudExpanded = false;
    });

    try {
      final origin = await _getCurrentLatLng();
      if (origin == null) {
        if (!mounted) return;
        setState(() {
          _routeLoading = false;
          _setLiveNavigationActive(false);
          _routeSummary = null;
          _routeVenue = null;
          _routeTrail = null;
          _routeTrailStop = null;
          _routeTrailStopIndex = null;
          _routeTrailStopLabel = null;
          _routeDiscountLabel = null;
          _routeArrived = false;
          _routeRemainingMeters = null;
          _routeRemainingSeconds = null;
          _navigationHudCheckInState = _NavigationHudCheckInState.idle;
        });
        return;
      }

      final route = await _fetchGoogleDirectionsRoute(
        origin: origin,
        destination: LatLng(destination.latitude, destination.longitude),
      );

      if (!mounted) return;

      if (route.points.isEmpty) {
        setState(() {
          _routeLoading = false;
          _setLiveNavigationActive(false);
          _routeSummary = null;
          _routeVenue = null;
          _routePolylines = const <Polyline>{};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No route was found for this venue.')),
        );
        return;
      }

      final polyline = Polyline(
        polylineId: const PolylineId('active_directions_route'),
        points: route.points,
        color: const Color(0xFFB84DFF),
        width: 7,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        zIndex: 3,
      );

      final destinationLatLng = LatLng(
        destination.latitude,
        destination.longitude,
      );
      setState(() {
        _routePolylines = {polyline};
        _routeSummary =
            '${route.distanceText} • ${route.durationText} walk to ${venue.name}';
        _routeLoading = false;
        _setLiveNavigationActive(true);
        _routeVenue = venue;
        _routeDestination = destinationLatLng;
        _routeInitialDistanceMeters = route.distanceMeters;
        _routeInitialDurationSeconds = route.durationSeconds;
        _routeRemainingMeters = route.distanceMeters;
        _routeRemainingSeconds = route.durationSeconds;
        _routeArrived = false;
        _routeTrail = trail;
        _routeTrailStop = stop;
        _routeTrailStopIndex = stopIndex;
        _routeTrailStopLabel = trail != null && stopIndex != null
            ? 'Trail Stop ${stopIndex + 1} / ${trail.stops.length}'
            : null;
        _routeDiscountLabel = stop?.discountLabel.trim().isNotEmpty == true
            ? stop!.discountLabel.trim()
            : null;
        _navigationHudCheckInState = _NavigationHudCheckInState.idle;
      });

      await _fitRouteOnMap(route.points);
      _startLiveNavigationUpdates(destination: destinationLatLng, venue: venue);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _setLiveNavigationActive(false);
        _routeSummary = null;
        _routeVenue = null;
        _routeDestination = null;
        _routeInitialDistanceMeters = null;
        _routeInitialDurationSeconds = null;
        _routeRemainingMeters = null;
        _routeRemainingSeconds = null;
        _routeArrived = false;
        _routeTrail = null;
        _routeTrailStop = null;
        _routeTrailStopIndex = null;
        _routeTrailStopLabel = null;
        _routeDiscountLabel = null;
        _routePolylines = const <Polyline>{};
        _navigationHudCheckInState = _NavigationHudCheckInState.idle;
      });

      await _showDirectionsFailedDialog(venue, e);
    }
  }

  Future<void> _showDirectionsFailedDialog(
    VenueModel venue,
    Object error,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Could not load in-app directions'),
        content: Text(
          'DrinkSpot could not draw the route inside the app. '
          'You can try again, or open the route in Google Maps.\n\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Stay in DrinkSpot'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final openedExternal = await DirectionsService.openDirections(
                destinationName: venue.name,
                destinationAddress: venue.address,
                destinationLatitude: venue.location?.latitude,
                destinationLongitude: venue.location?.longitude,
              );

              if (!mounted || openedExternal) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Google Maps.')),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open Google Maps'),
          ),
        ],
      ),
    );
  }

  Future<_DirectionsRoute> _fetchGoogleDirectionsRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = _googleRoutesApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception('Missing Google Routes API key.');
    }

    final uri = Uri.https(
      'routes.googleapis.com',
      '/directions/v2:computeRoutes',
    );

    final payload = <String, dynamic>{
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': 'WALK',
      'polylineQuality': 'HIGH_QUALITY',
      'polylineEncoding': 'ENCODED_POLYLINE',
      'units': 'METRIC',
    };

    final client = HttpClient();
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.headers.set('X-Goog-Api-Key', apiKey);
      request.headers.set(
        'X-Goog-FieldMask',
        'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      );
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        String message = body;
        try {
          final error = jsonDecode(body) as Map<String, dynamic>;
          final errorData = error['error'];
          if (errorData is Map && errorData['message'] != null) {
            message = errorData['message'].toString();
          }
        } catch (_) {
          // Keep raw response body.
        }
        throw Exception('Routes API returned ${response.statusCode}: $message');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) return const _DirectionsRoute.empty();

      final route = routes.first as Map<String, dynamic>;
      final polyline = route['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['encodedPolyline']?.toString() ?? '';
      final points = _decodePolyline(encoded);

      final distanceMeters = (route['distanceMeters'] as num?)?.toInt();
      final durationText = _formatRoutesDuration(route['duration']?.toString());

      final durationSeconds = _parseRoutesDurationSeconds(
        route['duration']?.toString(),
      );

      return _DirectionsRoute(
        points: points,
        distanceText: distanceMeters == null
            ? 'Route ready'
            : _formatDistance(distanceMeters),
        durationText: durationText.isEmpty ? 'Walking' : durationText,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } finally {
      client.close(force: true);
    }
  }

  String _formatDistance(int meters) => DistanceFormatter.formatMeters(meters);

  String _formatRoutesDuration(String? rawDuration) {
    final value = rawDuration?.trim() ?? '';
    if (value.isEmpty) return '';

    final seconds = _parseRoutesDurationSeconds(value);
    if (seconds == null) return value;

    return _formatDurationFromSeconds(seconds);
  }

  int? _parseRoutesDurationSeconds(String? rawDuration) {
    final value = rawDuration?.trim() ?? '';
    if (value.isEmpty) return null;
    return int.tryParse(value.replaceAll('s', ''));
  }

  String _formatDurationFromSeconds(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes} min';
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  Future<void> _fitRouteOnMap(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  void _startLiveNavigationUpdates({
    required LatLng destination,
    required VenueModel venue,
  }) {
    _liveNavigationSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
    );

    _liveNavigationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!mounted || !_liveNavigationActive) return;

            final current = LatLng(position.latitude, position.longitude);
            final remainingMeters = Geolocator.distanceBetween(
              current.latitude,
              current.longitude,
              destination.latitude,
              destination.longitude,
            ).round();

            final estimatedSeconds = _estimateRemainingSeconds(remainingMeters);
            final bearing = _navigationBearing(
              current: current,
              destination: destination,
              heading: position.heading,
            );

            setState(() {
              _routeRemainingMeters = remainingMeters;
              _routeRemainingSeconds = estimatedSeconds;
              _routeArrived = remainingMeters <= venue.presenceRadiusMeters;
              _routeSummary =
                  '${_formatDistance(remainingMeters)} • ${_formatDurationFromSeconds(estimatedSeconds)} walk to ${venue.name}';
            });

            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: current,
                  zoom: remainingMeters < 120 ? 18.2 : 17.0,
                  tilt: 45,
                  bearing: bearing,
                ),
              ),
            );
          },
          onError: (_) {
            // Keep the static route visible if live location updates fail.
          },
        );
  }

  int _estimateRemainingSeconds(int remainingMeters) {
    final initialDistance = _routeInitialDistanceMeters;
    final initialDuration = _routeInitialDurationSeconds;

    if (initialDistance != null &&
        initialDuration != null &&
        initialDistance > 0 &&
        initialDuration > 0) {
      final ratio = (remainingMeters / initialDistance).clamp(0.0, 1.5);
      return math.max(30, (initialDuration * ratio).round());
    }

    // Average walking speed: about 1.35 m/s.
    return math.max(30, (remainingMeters / 1.35).round());
  }

  double _navigationBearing({
    required LatLng current,
    required LatLng destination,
    required double heading,
  }) {
    if (!heading.isNaN && heading >= 0) return heading;
    return _bearingBetween(current, destination);
  }

  double _bearingBetween(LatLng start, LatLng end) {
    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);
    final deltaLng = _degreesToRadians(end.longitude - start.longitude);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    final bearing = _radiansToDegrees(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  void _clearRoute() {
    _liveNavigationSubscription?.cancel();
    _liveNavigationSubscription = null;
    _navigationHudCheckInTimer?.cancel();
    _navigationHudCheckInTimer = null;
    setState(() {
      _routePolylines = const <Polyline>{};
      _routeSummary = null;
      _routeLoading = false;
      _setLiveNavigationActive(false);
      _routeVenue = null;
      _routeDestination = null;
      _routeInitialDistanceMeters = null;
      _routeInitialDurationSeconds = null;
      _routeRemainingMeters = null;
      _routeRemainingSeconds = null;
      _routeArrived = false;
      _routeTrail = null;
      _routeTrailStop = null;
      _routeTrailStopIndex = null;
      _routeTrailStopLabel = null;
      _routeDiscountLabel = null;
      _navigationHudCheckInState = _NavigationHudCheckInState.idle;
      _navigationHudExpanded = false;
    });
  }

  Future<void> _handleNavigationHudCheckIn() async {
    final trail = _routeTrail;
    final stop = _routeTrailStop;
    final stopIndex = _routeTrailStopIndex;

    if (trail == null || stop == null || stopIndex == null) {
      return;
    }

    setState(() => _checkingInFromHud = true);
    try {
      final validation = await TrailService.validateStopCheckIn(stop: stop);
      if (!mounted) return;

      if (!validation.allowed) {
        _showNavigationHudMessage(
          validation.message ?? 'You are not close enough to check in.',
        );
        return;
      }

      _navigationHudCheckInTimer?.cancel();
      await TrailService.checkInAtStop(
        trail: trail,
        stop: stop,
        stopIndex: stopIndex,
      );

      if (!mounted) return;
      final isLastStop = stopIndex >= trail.stops.length - 1;
      setState(() {
        _routeArrived = true;
        _checkingInFromHud = false;
        _navigationHudCheckInState = _NavigationHudCheckInState.checkedIn;
      });

      _navigationHudCheckInTimer = Timer(
        const Duration(milliseconds: 1700),
        () async {
          if (!mounted ||
              _routeTrail != trail ||
              _routeTrailStopIndex != stopIndex) {
            return;
          }

          if (isLastStop) {
            await TrailService.continueTrail(
              trail: trail,
              stop: stop,
              stopIndex: stopIndex,
            );
            if (!mounted ||
                _routeTrail != trail ||
                _routeTrailStopIndex != stopIndex) {
              return;
            }
          }

          setState(() {
            _navigationHudCheckInTimer = null;
            _navigationHudCheckInState = isLastStop
                ? _NavigationHudCheckInState.trailComplete
                : _NavigationHudCheckInState.readyForNext;
          });
        },
      );
    } finally {
      if (mounted &&
          _navigationHudCheckInState == _NavigationHudCheckInState.idle) {
        setState(() => _checkingInFromHud = false);
      }
    }
  }

  void _showNavigationHudMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 96, 12, 0),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  Future<void> _handleNavigationHudContinueTrail() async {
    final trail = _routeTrail;
    final stop = _routeTrailStop;
    final stopIndex = _routeTrailStopIndex;

    if (trail == null || stop == null || stopIndex == null) {
      return;
    }

    final nextStopIndex = await TrailService.continueTrail(
      trail: trail,
      stop: stop,
      stopIndex: stopIndex,
    );

    if (!mounted) return;

    if (nextStopIndex == null) {
      setState(() {
        _navigationHudCheckInState = _NavigationHudCheckInState.trailComplete;
      });
      return;
    }

    final nextStop = trail.stops[nextStopIndex];
    await _startInAppDirectionsForTrailStop(
      trail: trail,
      stop: nextStop,
      stopIndex: nextStopIndex,
    );
  }

  Future<void> _handleNavigationHudSkipStop() async {
    final trail = _routeTrail;
    final stop = _routeTrailStop;
    final stopIndex = _routeTrailStopIndex;

    if (trail == null || stop == null || stopIndex == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Skip Stop'),
          content: const Text('Skip this venue and continue to the next stop?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Skip Stop'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final nextStopIndex = await TrailService.skipStop(
      trail: trail,
      stop: stop,
      stopIndex: stopIndex,
    );
    if (!mounted) return;

    if (nextStopIndex == null) {
      setState(() {
        _routeArrived = true;
        _navigationHudCheckInState = _NavigationHudCheckInState.trailComplete;
      });
      return;
    }

    final nextStop = trail.stops[nextStopIndex];
    await _startInAppDirectionsForTrailStop(
      trail: trail,
      stop: nextStop,
      stopIndex: nextStopIndex,
    );
  }

  Future<void> _startInAppDirectionsForTrailStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    if (stop.venueId.trim().isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(stop.venueId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The next trail venue could not be found.'),
          ),
        );
        return;
      }

      final venue = VenueModel.fromMap(
        doc.id,
        doc.data() ?? const <String, dynamic>{},
      );
      await _startInAppDirections(
        venue,
        trail: trail,
        stop: stop,
        stopIndex: stopIndex,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load next trail stop directions: $e'),
        ),
      );
    }
  }

  Future<void> _openStreetView() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${_lastCameraTarget.latitude},${_lastCameraTarget.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Street View is not available here.')),
    );
  }

  Future<void> _callVenue(String rawPhone) async {
    final cleaned = rawPhone.trim();
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number has been added for this venue yet.'),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start a call on this device.')),
    );
  }

  Future<void> _zoomBy(double amount) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomBy(amount));
  }

  Future<void> _recenterOnCurrentLocation() async {
    if (_mapController == null) return;

    final current = await _getCurrentLatLng();
    if (current == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: current, zoom: math.max(_lastCameraZoom, 16)),
      ),
    );
  }

  Future<void> _resetMapBearing() async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _lastCameraTarget, zoom: _lastCameraZoom),
      ),
    );
  }

  Set<Marker> _markersForNavigation(Set<Marker> markers) {
    final routeVenueId = _routeVenue?.id;
    final destination = _routeDestination;
    if (routeVenueId == null || destination == null) {
      return const <Marker>{};
    }

    final destinationMarkers = markers
        .where((marker) => marker.markerId.value == routeVenueId)
        .toSet();
    if (destinationMarkers.isNotEmpty) return destinationMarkers;

    return {
      Marker(
        markerId: MarkerId(routeVenueId),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow.noText,
      ),
    };
  }

  LatLng _initialCenter() {
    final startupData = StartupCache.data;

    if (startupData?.hasUserLocation == true) {
      return LatLng(startupData!.userLatitude!, startupData.userLongitude!);
    }

    VenueModel? nearestVenue;
    for (final venue in startupData?.nearbyVenues ?? const <VenueModel>[]) {
      if (venue.location != null) {
        nearestVenue = venue;
        break;
      }
    }

    if (nearestVenue?.location != null) {
      return LatLng(
        nearestVenue!.location!.latitude,
        nearestVenue.location!.longitude,
      );
    }

    return _defaultCenter;
  }

  Future<void> _moveToResults(Set<Marker> markers) async {
    if (markers.isEmpty || _mapController == null) return;

    final firstMarker = markers.first;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(firstMarker.position, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchText.isEmpty) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _allVenuesStream,
        builder: (context, snapshot) {
          return _buildMapScaffold(
            docs: snapshot.data?.docs ?? const [],
            venuesLoading: snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData,
            venuesError: snapshot.hasError ? snapshot.error : null,
          );
        },
      );
    }

    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _venuesFuture,
      builder: (context, snapshot) {
        return _buildMapScaffold(
          docs: snapshot.data ?? const [],
          venuesLoading: snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          venuesError: snapshot.hasError ? snapshot.error : null,
        );
      },
    );
  }

  Widget _buildMapScaffold({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required bool venuesLoading,
    Object? venuesError,
  }) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          _latestVenueDocs = docs;
          final crowdGlow = _buildCrowdGlow(docs);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshEventGlowForVisibleVenues();
          });

          // Search should only filter visible venues; do not auto-move the map camera.

          return FutureBuilder<Set<Marker>>(
            future: _markersForDocs(docs),
            builder: (context, markerSnapshot) {
              final markers = markerSnapshot.data ?? <Marker>{};
              final navigationMode = _liveNavigationActive;
              final visibleMarkers = navigationMode
                  ? _markersForNavigation(markers)
                  : markers;
              final visibleCrowdGlow = navigationMode
                  ? const <Circle>{}
                  : crowdGlow;
              final routeControlsActive =
                  _routeLoading || _routeSummary != null;
              final controlRailBottom = routeControlsActive
                  ? (_navigationHudExpanded || _routeLoading || _routeArrived
                        ? 292.0
                        : 178.0)
                  : 112.0;

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialCenter(),
                      zoom: 13,
                    ),
                    markers: visibleMarkers,
                    circles: visibleCrowdGlow,
                    polylines: _routePolylines,
                    mapType: _satelliteView
                        ? MapType.satellite
                        : MapType.normal,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: true,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    onCameraMove: (position) {
                      _lastCameraTarget = position.target;
                      _lastCameraZoom = position.zoom;
                    },
                    onCameraIdle: _refreshEventGlowForVisibleVenues,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      controller.setMapStyle(
                        _satelliteView ? null : DarkMapStyle.json,
                      );

                      final initialVenueId = widget.initialRouteVenueId?.trim();
                      if (!_initialRouteStarted &&
                          initialVenueId != null &&
                          initialVenueId.isNotEmpty) {
                        _initialRouteStarted = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _startInAppDirectionsForVenueId(initialVenueId);
                        });
                      }
                    },
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(30),
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search venues, drinks, deals...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _clearSearch,
                                    ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_routeLoading || _routeSummary != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 18,
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _RouteStatusCard(
                            loading: _routeLoading,
                            liveNavigation: _liveNavigationActive,
                            summary: _routeSummary ?? 'Loading directions...',
                            venueName: _routeVenue?.name,
                            remainingMeters: _routeRemainingMeters,
                            remainingSeconds: _routeRemainingSeconds,
                            trailStopLabel: _routeTrailStopLabel,
                            trailStopNumber: _routeTrailStopIndex == null
                                ? null
                                : _routeTrailStopIndex! + 1,
                            trailStopCount: _routeTrail?.stops.length,
                            discountLabel: _routeDiscountLabel,
                            arrived: _routeArrived,
                            canCheckIn:
                                _routeTrail != null &&
                                _routeTrailStop != null &&
                                _routeTrailStopIndex != null,
                            canSkipStop:
                                _routeTrail != null &&
                                _routeTrailStop != null &&
                                _routeTrailStopIndex != null,
                            checkingIn: _checkingInFromHud,
                            checkInState: _navigationHudCheckInState,
                            onCheckIn: _handleNavigationHudCheckIn,
                            onContinueTrail: _handleNavigationHudContinueTrail,
                            onSkipStop: _handleNavigationHudSkipStop,
                            onExpandedChanged: (expanded) {
                              if (_navigationHudExpanded == expanded) return;
                              setState(() => _navigationHudExpanded = expanded);
                            },
                            onClear: _clearRoute,
                          ),
                        ),
                      ),
                    ),

                  if (!_liveNavigationActive)
                    StreamBuilder<List<DrinkSpotTrailModel>>(
                      stream: _visibleTrailsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          _lastVisibleTrails = snapshot.data!;
                        }

                        final showButton = _lastVisibleTrails.isNotEmpty;
                        debugPrint(
                          'Map visible trails cached count: ${_lastVisibleTrails.length}',
                        );

                        if (!showButton) {
                          return const SizedBox.shrink();
                        }

                        return Positioned(
                          left: 12,
                          top: (_routeLoading || _routeSummary != null)
                              ? 148
                              : 76,
                          child: SafeArea(
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(18),
                              color: Theme.of(
                                context,
                              ).cardColor.withOpacity(0.94),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TonightsTrailScreen(),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 18,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Tonight's Trails",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    right: 12,
                    bottom: controlRailBottom,
                    child: SafeArea(
                      child: _MapControlRail(
                        satelliteView: _satelliteView,
                        showEndNavigation: routeControlsActive,
                        onResetBearing: _resetMapBearing,
                        onCurrentLocation: _recenterOnCurrentLocation,
                        onZoomIn: () => _zoomBy(1),
                        onZoomOut: () => _zoomBy(-1),
                        onStreetView: _openStreetView,
                        onToggleSatellite: () {
                          setState(() {
                            _satelliteView = !_satelliteView;
                          });
                          _mapController?.setMapStyle(
                            _satelliteView ? null : DarkMapStyle.json,
                          );
                        },
                        onEndNavigation: _clearRoute,
                      ),
                    ),
                  ),
                  if (!navigationMode && venuesLoading)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 28,
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Loading venues...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (venuesError != null)
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Map error: $venuesError'),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DirectionsRoute {
  const _DirectionsRoute({
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  const _DirectionsRoute.empty()
    : points = const <LatLng>[],
      distanceText = '',
      durationText = '',
      distanceMeters = null,
      durationSeconds = null;

  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  final int? distanceMeters;
  final int? durationSeconds;
}

class _VenueOpeningStatus {
  const _VenueOpeningStatus({
    required this.label,
    required this.hasHours,
    required this.isOpen,
  });

  final String label;
  final bool hasHours;
  final bool isOpen;
}

class _MapOpeningStatusRow extends StatelessWidget {
  const _MapOpeningStatusRow({required this.status});

  final _VenueOpeningStatus status;

  @override
  Widget build(BuildContext context) {
    final parts = status.label.split(' • ');
    final stateText = parts.isNotEmpty ? parts.first : status.label;
    final detailText = parts.length > 1 ? parts.sublist(1).join(' • ') : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stateText,
          style: TextStyle(
            color: status.isOpen
                ? const Color(0xFF35E06F)
                : const Color(0xFFFF5A6A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (detailText.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            '• $detailText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _MapCardActionButton extends StatelessWidget {
  const _MapCardActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
      ),
    );
  }
}

class _MapControlRail extends StatelessWidget {
  const _MapControlRail({
    required this.satelliteView,
    required this.showEndNavigation,
    required this.onResetBearing,
    required this.onCurrentLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onStreetView,
    required this.onToggleSatellite,
    required this.onEndNavigation,
  });

  final bool satelliteView;
  final bool showEndNavigation;
  final VoidCallback onResetBearing;
  final VoidCallback onCurrentLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onStreetView;
  final VoidCallback onToggleSatellite;
  final VoidCallback onEndNavigation;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xE6111218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlRailButton(
            icon: Icons.explore_outlined,
            tooltip: 'Reset compass',
            onPressed: onResetBearing,
          ),
          _MapControlRailButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Current location',
            onPressed: onCurrentLocation,
            accentColor: AppColors.primaryPurple,
          ),
          _MapControlRailDivider(),
          _MapControlRailButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
          ),
          _MapControlRailButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
          ),
          _MapControlRailDivider(),
          _MapControlRailButton(
            icon: Icons.person_pin_circle_outlined,
            tooltip: 'Street View',
            onPressed: onStreetView,
          ),
          _MapControlRailButton(
            icon: satelliteView
                ? Icons.map_outlined
                : Icons.satellite_alt_outlined,
            tooltip: satelliteView
                ? 'Switch to standard map'
                : 'Switch to satellite',
            onPressed: onToggleSatellite,
            accentColor: satelliteView ? AppColors.primaryPink : null,
          ),
          if (showEndNavigation) ...[
            _MapControlRailDivider(),
            _MapControlRailButton(
              icon: Icons.close_rounded,
              tooltip: 'End navigation',
              onPressed: onEndNavigation,
              accentColor: AppColors.primaryPink,
            ),
          ],
        ],
      ),
    );
  }
}

class _MapControlRailButton extends StatelessWidget {
  const _MapControlRailButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accentColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.textPrimary;

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: accentColor == null
              ? Colors.white.withOpacity(0.045)
              : color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onPressed,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: color, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlRailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Colors.white.withOpacity(0.10),
    );
  }
}

class _RouteStatusCard extends StatefulWidget {
  const _RouteStatusCard({
    required this.loading,
    required this.liveNavigation,
    required this.summary,
    required this.onClear,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.arrived,
    required this.canCheckIn,
    required this.canSkipStop,
    required this.checkingIn,
    required this.checkInState,
    required this.onCheckIn,
    required this.onContinueTrail,
    required this.onSkipStop,
    required this.onExpandedChanged,
    this.venueName,
    this.trailStopLabel,
    this.trailStopNumber,
    this.trailStopCount,
    this.discountLabel,
  });

  final bool loading;
  final bool liveNavigation;
  final String summary;
  final String? venueName;
  final int? remainingMeters;
  final int? remainingSeconds;
  final String? trailStopLabel;
  final int? trailStopNumber;
  final int? trailStopCount;
  final String? discountLabel;
  final bool arrived;
  final bool canCheckIn;
  final bool canSkipStop;
  final bool checkingIn;
  final _NavigationHudCheckInState checkInState;
  final VoidCallback onCheckIn;
  final VoidCallback onContinueTrail;
  final VoidCallback onSkipStop;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onClear;

  @override
  State<_RouteStatusCard> createState() => _RouteStatusCardState();
}

class _RouteStatusCardState extends State<_RouteStatusCard> {
  bool _expanded = false;

  static const _animationDuration = Duration(milliseconds: 240);

  bool get _effectiveExpanded => _expanded || widget.arrived || widget.loading;

  @override
  void initState() {
    super.initState();
    _notifyExpandedAfterFrame(_effectiveExpanded);
  }

  @override
  void didUpdateWidget(covariant _RouteStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasExpanded = _expanded || oldWidget.arrived || oldWidget.loading;
    if (wasExpanded != _effectiveExpanded) {
      _notifyExpandedAfterFrame(_effectiveExpanded);
    }
  }

  void _notifyExpandedAfterFrame(bool expanded) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onExpandedChanged(expanded);
    });
  }

  void _setExpanded(bool expanded) {
    setState(() => _expanded = expanded);
    widget.onExpandedChanged(expanded || widget.arrived || widget.loading);
  }

  String _formatDistance(int? meters) {
    if (meters == null) return 'Route ready';
    return DistanceFormatter.formatMeters(meters);
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'Walking';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final venueName = widget.venueName ?? 'Destination';
    final distance = _formatDistance(widget.remainingMeters);
    final eta = _formatDuration(widget.remainingSeconds);
    final discount = widget.discountLabel?.trim() ?? '';
    final trailLabel = widget.trailStopLabel?.trim() ?? '';
    final isExpanded = _effectiveExpanded;

    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      width: isExpanded ? 560 : 328,
      padding: EdgeInsets.all(isExpanded ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xE6111218),
        borderRadius: BorderRadius.circular(isExpanded ? 28 : 24),
        border: Border.all(
          color: widget.arrived
              ? Colors.greenAccent.withOpacity(0.65)
              : AppColors.primaryPurple.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color:
                (widget.arrived ? Colors.greenAccent : AppColors.primaryPurple)
                    .withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: _animationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: widget.loading
            ? _buildLoading()
            : _buildContent(
                venueName: venueName,
                distance: distance,
                eta: eta,
                discount: discount,
                trailLabel: trailLabel,
              ),
      ),
    );
  }

  Widget _buildLoading() {
    return Row(
      key: const ValueKey('navigation-loading'),
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.summary,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required String venueName,
    required String distance,
    required String eta,
    required String discount,
    required String trailLabel,
  }) {
    if (widget.arrived) {
      if (widget.checkInState == _NavigationHudCheckInState.trailComplete) {
        return _buildTrailCompleteContent();
      }

      return _buildArrivalContent(venueName: venueName, discount: discount);
    }

    return Material(
      key: ValueKey(_expanded ? 'navigation-expanded' : 'navigation-collapsed'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_expanded ? 24 : 20),
        onTap: () => _setExpanded(!_expanded),
        child: _expanded
            ? _buildExpandedNavigation(
                venueName: venueName,
                distance: distance,
                eta: eta,
                discount: discount,
                trailLabel: trailLabel,
              )
            : _buildCollapsedNavigation(
                venueName: venueName,
                distance: distance,
                eta: eta,
              ),
      ),
    );
  }

  Widget _buildCollapsedNavigation({
    required String venueName,
    required String distance,
    required String eta,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _HudIconBubble(
              icon: widget.liveNavigation
                  ? Icons.directions_walk_rounded
                  : Icons.navigation_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                venueName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _HudMetric(icon: Icons.schedule_rounded, label: eta),
            const SizedBox(width: 8),
            _HudMetric(icon: Icons.place_rounded, label: distance),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          duration: _animationDuration,
          opacity: widget.liveNavigation ? 0.78 : 0.55,
          child: const Text(
            'Tap for navigation details',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedNavigation({
    required String venueName,
    required String distance,
    required String eta,
    required String discount,
    required String trailLabel,
  }) {
    final stopNumber = widget.trailStopNumber;
    final stopCount = widget.trailStopCount;
    final hasTrailStop =
        stopNumber != null && stopCount != null && stopCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _HudIconBubble(
              icon: widget.liveNavigation
                  ? Icons.directions_walk_rounded
                  : Icons.navigation_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DrinkSpot Navigation',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    venueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Collapse navigation',
              onPressed: () => _setExpanded(false),
              icon: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _HudMetric(icon: Icons.schedule_rounded, label: eta),
            const SizedBox(width: 10),
            _HudMetric(icon: Icons.place_rounded, label: distance),
          ],
        ),
        if (hasTrailStop || trailLabel.isNotEmpty || discount.isNotEmpty) ...[
          const SizedBox(height: 14),
          AnimatedOpacity(
            duration: _animationDuration,
            opacity: _expanded ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: Colors.white.withOpacity(0.12)),
                if (hasTrailStop) ...[
                  const SizedBox(height: 12),
                  _HudLine(
                    icon: Icons.route_rounded,
                    text: 'Trail stop $stopNumber of $stopCount',
                  ),
                ] else if (trailLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _HudLine(icon: Icons.route_rounded, text: trailLabel),
                ],
                if (discount.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _OfferBanner(label: discount),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (widget.canSkipStop) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSkipStop,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Skip Stop'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('End Navigation'),
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalContent({
    required String venueName,
    required String discount,
  }) {
    return Column(
      key: const ValueKey('navigation-arrival'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _HudIconBubble(
              icon: Icons.check_circle_rounded,
              color: Colors.greenAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to $venueName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "You're here.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'End navigation',
              onPressed: widget.onClear,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withOpacity(0.12)),
        if (discount.isNotEmpty) ...[
          const SizedBox(height: 12),
          _OfferBanner(label: discount),
        ],
        const SizedBox(height: 14),
        _buildArrivalAction(),
      ],
    );
  }

  Widget _buildArrivalAction() {
    return AnimatedSwitcher(
      duration: _animationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (widget.checkInState) {
        _NavigationHudCheckInState.checkedIn => _CheckedInBanner(
          key: const ValueKey('checked-in-banner'),
        ),
        _NavigationHudCheckInState.readyForNext => SizedBox(
          key: const ValueKey('continue-next-stop'),
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.onContinueTrail,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue to Next Stop'),
          ),
        ),
        _NavigationHudCheckInState.trailComplete => const SizedBox.shrink(),
        _NavigationHudCheckInState.idle => SizedBox(
          key: const ValueKey('check-in-button'),
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.canCheckIn && !widget.checkingIn
                ? widget.onCheckIn
                : null,
            icon: widget.checkingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(widget.checkingIn ? 'Checking in...' : 'Check In'),
          ),
        ),
      },
    );
  }

  Widget _buildTrailCompleteContent() {
    return Column(
      key: const ValueKey('trail-complete'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _HudIconBubble(
              icon: Icons.celebration_rounded,
              color: AppColors.primaryPink,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '🎉 Trail Complete',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'End navigation',
              onPressed: widget.onClear,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withOpacity(0.12)),
        const SizedBox(height: 12),
        const Text(
          'Nice one. You finished every stop on tonight\'s trail.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CheckedInBanner extends StatelessWidget {
  const _CheckedInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.48)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
          SizedBox(width: 8),
          Text(
            '✅ Checked In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudIconBubble extends StatelessWidget {
  const _HudIconBubble({
    required this.icon,
    this.color = AppColors.primaryPurple,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryPink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudLine extends StatelessWidget {
  const _HudLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primaryPink.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryPink.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 19,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveModeBadge extends StatelessWidget {
  const _LiveModeBadge({
    required this.satelliteView,
    required this.activeVenueCount,
  });

  final bool satelliteView;
  final int activeVenueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, size: 18, color: Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(
            'Live Map • $activeVenueCount venue${activeVenueCount == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Icon(
            satelliteView ? Icons.satellite_alt_outlined : Icons.map_outlined,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _MapVenueChip extends StatelessWidget {
  const _MapVenueChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewInfoRow extends StatelessWidget {
  const _MapPreviewInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapVenueLogo extends StatelessWidget {
  const _MapVenueLogo({required this.venueName, required this.logoUrl});

  final String venueName;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final firstLetter = venueName.trim().isNotEmpty
        ? venueName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: 56,
      height: 50,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.trim().isNotEmpty
            ? Container(
                color: AppColors.background,
                child: Image.network(
                  logoUrl.trim(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      _MapVenueLogoFallback(letter: firstLetter),
                ),
              )
            : _MapVenueLogoFallback(letter: firstLetter),
      ),
    );
  }
}

class _MapVenueLogoFallback extends StatelessWidget {
  const _MapVenueLogoFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LiveVenueSnapshot extends StatelessWidget {
  const _LiveVenueSnapshot({
    required this.venue,
    required this.displayCrowd,
    required this.updatedAt,
  });

  final VenueModel venue;
  final String displayCrowd;
  final dynamic updatedAt;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SmartCrowdSnapshot>(
      stream: SmartCrowdService.venueCrowdStream(
        venueId: venue.id,
        manualLevel: displayCrowd,
        updatedAt: updatedAt,
      ),
      builder: (context, crowdSnapshot) {
        final smartCrowd = crowdSnapshot.data;
        final level = smartCrowd?.level ?? displayCrowd;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                  avatar: const Icon(Icons.local_fire_department, size: 18),
                  label: Text(
                    'Live crowd: ${CrowdDecay.displayLevel(level: level, updatedAt: venue.crowdUpdatedAt ?? venue.updatedAt)}',
                  ),
                ),
                StreamBuilder<List<DealModel>>(
                  stream: DealService.getDealsForVenue(venue.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Chip(
                      side: const BorderSide(
                        color: Color(0xFF9D28FF),
                        width: 1,
                      ),
                      avatar: const Icon(Icons.local_offer, size: 18),
                      label: Text('$count active deal${count == 1 ? '' : 's'}'),
                    );
                  },
                ),
                StreamBuilder<List<EventModel>>(
                  stream: EventService.getEventsForVenue(venue.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Chip(
                      side: const BorderSide(
                        color: Color(0xFF9D28FF),
                        width: 1,
                      ),
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(
                        '$count upcoming event${count == 1 ? '' : 's'}',
                      ),
                    );
                  },
                ),
              ],
            ),
            if ((smartCrowd?.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Crowd signal: ${smartCrowd!.reason}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}
