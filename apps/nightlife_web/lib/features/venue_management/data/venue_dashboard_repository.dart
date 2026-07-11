import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_highlight_composer.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_stats_composer.dart';
import 'package:vex_engines/analytics/domain/analytics_venue_metrics.dart';
import 'package:vex_engines/venue/application/venue_active_venue_selector.dart';
import 'package:vex_engines/venue/application/venue_dashboard_composer.dart';
import 'package:vex_engines/venue/domain/venue_dashboard_models.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../services/venue_dashboard_engine_mapper.dart';
import '../services/venue_profile_completion_calculator.dart';
import 'venue_activity_service.dart';
import 'venue_analytics_service.dart';

/// Resolves active venue context and dashboard home data from Firestore.
class VenueDashboardRepository {
  VenueDashboardRepository({
    FirebaseFirestore? firestore,
    VenueAnalyticsService? analyticsService,
    VenueActivitySource? activityService,
    VenueActiveVenueSelector? activeVenueSelector,
    AnalyticsDashboardStatsComposer? statsComposer,
    AnalyticsDashboardHighlightComposer? highlightComposer,
    VenueDashboardHighlightComposer? dashboardHighlightComposer,
    VenueWhatsNextComposer? whatsNextComposer,
  })  : _firestoreOverride = firestore,
        _analyticsService = analyticsService ?? VenueAnalyticsService(firestore: firestore),
        _activityService = activityService ?? VenueActivityService(firestore: firestore),
        _activeVenueSelector = activeVenueSelector ?? const VenueActiveVenueSelector(),
        _statsComposer = statsComposer ?? const AnalyticsDashboardStatsComposer(),
        _highlightComposer = highlightComposer ?? const AnalyticsDashboardHighlightComposer(),
        _dashboardHighlightComposer =
            dashboardHighlightComposer ?? const VenueDashboardHighlightComposer(),
        _whatsNextComposer = whatsNextComposer ?? const VenueWhatsNextComposer();

  final FirebaseFirestore? _firestoreOverride;
  final VenueAnalyticsService _analyticsService;
  final VenueActivitySource _activityService;
  final VenueActiveVenueSelector _activeVenueSelector;
  final AnalyticsDashboardStatsComposer _statsComposer;
  final AnalyticsDashboardHighlightComposer _highlightComposer;
  final VenueDashboardHighlightComposer _dashboardHighlightComposer;
  final VenueWhatsNextComposer _whatsNextComposer;

  FirebaseFirestore? get _db {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<VenueDashboardContext> resolveContext({
    required User user,
    required UserRoleProfile roleProfile,
    String? preferredVenueId,
  }) async {
    final venues = await _loadAccessibleVenues(user: user, roleProfile: roleProfile);
    if (venues.isEmpty) {
      throw VenueDashboardLoadException(
        'No venue found for your account. Please contact support.',
      );
    }

    final activeVenue = _selectActiveVenue(
      venues: venues,
      preferredVenueId: preferredVenueId,
      roleProfile: roleProfile,
    );

    final userDoc = await _loadUserDocument(user.uid);
    final ownerName = _resolveOwnerName(user, userDoc);
    final ownerFirstName = _resolveFirstName(user, userDoc, ownerName);

    return VenueDashboardContext(
      ownerName: ownerName,
      ownerFirstName: ownerFirstName,
      venueName: activeVenue.name.trim().isEmpty ? 'Your Venue' : activeVenue.name,
      venueId: activeVenue.id,
      logoUrl: activeVenue.logoUrl.trim().isEmpty ? null : activeVenue.logoUrl,
      bannerImageUrl: activeVenue.bannerImageUrl.trim().isEmpty
          ? null
          : activeVenue.bannerImageUrl,
      unreadNotifications: 0,
      availableVenueIds: venues.map((venue) => venue.id).toList(),
    );
  }

  Future<VenueDashboardHomeData> loadHomeData({
    required VenueModel venue,
    required VenueProfileCompletion profileCompletion,
    VenueDashboardDateRange dateRange = VenueDashboardDateRange.defaultRange,
  }) async {
    late final VenueAnalyticsSnapshot analytics;
    analytics = await _analyticsService.loadSnapshot(
      venueId: venue.id,
      range: dateRange,
    );

    final stats = VenueDashboardEngineMapper.statsFromEngine(
      _statsComposer.compose(
        current: _toEngineMetrics(analytics.current),
        previous: analytics.previous == null
            ? null
            : _toEngineMetrics(analytics.previous!),
      ),
    );

    final drinkCount = await _countDrinks(venue.id);
    final dealCount = await _countDeals(venue.id);
    final eventCount = await _countEvents(venue.id);
    final hasUpcomingEvent = await _hasUpcomingEvent(venue.id);

    final recentActivity = await _activityService.loadRecentActivity(
      venueId: venue.id,
    );

    final analyticsHighlights = analytics.hasData
        ? VenueDashboardEngineMapper.analyticsHighlightsFromEngine(
            _highlightComposer.compose(
              current: _toEngineMetrics(analytics.current),
              previous: analytics.previous == null
                  ? null
                  : _toEngineMetrics(analytics.previous!),
            ),
          )
        : const <VenueDashboardHighlight>[];

    return VenueDashboardHomeData(
      dateRange: dateRange,
      stats: stats,
      chartPoints: analytics.chartPoints,
      profileCompletion: profileCompletion,
      highlights: VenueDashboardEngineMapper.highlightsFromEngine(
        _dashboardHighlightComposer.compose(
          analyticsAvailable: analytics.hasData,
          analyticsHighlights: analyticsHighlights,
        ),
      ),
      whatsNext: VenueDashboardEngineMapper.whatsNextFromEngine(
        _whatsNextComposer.compose(
          venue: VenueDashboardVenueSnapshot(
            venueId: venue.id,
            galleryImageCount: venue.galleryImageUrls.length,
          ),
          profileCompletion: profileCompletion,
          counts: VenueDashboardContentCounts(
            drinkCount: drinkCount,
            dealCount: dealCount,
            eventCount: eventCount,
            hasUpcomingEvent: hasUpcomingEvent,
          ),
        ),
      ),
      recentActivity: recentActivity,
      analyticsAvailable: analytics.hasData,
    );
  }

  AnalyticsVenueMetrics _toEngineMetrics(VenueAnalyticsCounts counts) {
    return AnalyticsVenueMetrics(
      profileViews: counts.profileViews,
      saves: counts.saves,
      drinkViews: counts.drinkViews,
      dealViews: counts.dealViews,
      eventViews: counts.eventViews,
    );
  }

  Future<VenueModel?> loadVenue(String venueId) async {
    final db = _db;
    if (db == null) return null;

    try {
      final doc = await db.collection('venues').doc(venueId).get();
      if (!doc.exists || doc.data()?['isDeleted'] == true) return null;
      return VenueModel.fromMap(doc.id, doc.data()!);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDashboardRepository] venue load (${error.code})');
      }
      return null;
    }
  }

  Future<VenueProfileCompletion> loadProfileCompletion(VenueModel venue) async {
    final drinkCount = await _countDrinks(venue.id);
    return VenueProfileCompletionCalculator.calculate(
      venue: venue,
      drinkCount: drinkCount,
    );
  }

  Future<List<VenueModel>> _loadAccessibleVenues({
    required User user,
    required UserRoleProfile roleProfile,
  }) async {
    final db = _db;
    if (db == null) return const [];

    final venueIds = <String>{};

    if (roleProfile.role == VexdaUserRole.venueOwner ||
        roleProfile.ownedVenuesCount > 0) {
      try {
        final owned = await db
            .collection('venues')
            .where('ownerId', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .limit(20)
            .get();
        venueIds.addAll(owned.docs.map((doc) => doc.id));
      } on FirebaseException catch (error) {
        if (kDebugMode) {
          debugPrint('[VenueDashboardRepository] owned venues (${error.code})');
        }
        try {
          final owned = await db
              .collection('venues')
              .where('ownerId', isEqualTo: user.uid)
              .limit(20)
              .get();
          venueIds.addAll(
            owned.docs
                .where((doc) => doc.data()['isDeleted'] != true)
                .map((doc) => doc.id),
          );
        } catch (_) {}
      }
    }

    venueIds.addAll(roleProfile.venueIds);

    if (venueIds.isEmpty) return const [];

    final venues = <VenueModel>[];
    for (final id in venueIds) {
      final venue = await loadVenue(id);
      if (venue != null) venues.add(venue);
    }

    venues.sort((a, b) => a.name.compareTo(b.name));
    return venues;
  }

  VenueModel _selectActiveVenue({
    required List<VenueModel> venues,
    required UserRoleProfile roleProfile,
    String? preferredVenueId,
  }) {
    final selectedId = _activeVenueSelector.selectVenueId(
      accessibleVenueIds: venues.map((venue) => venue.id).toList(),
      roleVenueIds: roleProfile.venueIds,
      preferredVenueId: preferredVenueId,
    );

    return venues.firstWhere((venue) => venue.id == selectedId);
  }

  Future<Map<String, dynamic>?> _loadUserDocument(String uid) async {
    final db = _db;
    if (db == null) return null;

    try {
      final doc = await db.collection('users').doc(uid).get();
      return doc.data();
    } on FirebaseException {
      return null;
    }
  }

  String _resolveOwnerName(User user, Map<String, dynamic>? userDoc) {
    final displayName = AuthService.getDisplayName(user);
    if (displayName != 'Account') return displayName;

    final docName = userDoc?['name']?.toString().trim();
    if (docName != null && docName.isNotEmpty) return docName;

    return 'User';
  }

  String? _resolveFirstName(
    User user,
    Map<String, dynamic>? userDoc,
    String ownerName,
  ) {
    final docFirst = userDoc?['firstName']?.toString().trim();
    if (docFirst != null && docFirst.isNotEmpty) return docFirst;

    return AuthService.getFirstName(user) ??
        (ownerName == 'User'
            ? null
            : ownerName.split(RegExp(r'\s+')).firstOrNull);
  }

  Future<int> _countDrinks(String venueId) async {
    final db = _db;
    if (db == null) return 0;

    try {
      final snapshot = await db
          .collection('drinks')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<int> _countDeals(String venueId) async {
    final db = _db;
    if (db == null) return 0;

    try {
      final snapshot = await db
          .collection('deals')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<int> _countEvents(String venueId) async {
    final db = _db;
    if (db == null) return 0;

    try {
      final snapshot = await db
          .collection('events')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<bool> _hasUpcomingEvent(String venueId) async {
    final db = _db;
    if (db == null) return false;

    try {
      final snapshot = await db
          .collection('events')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .where('endDateTime', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException {
      return false;
    }
  }
}

class VenueDashboardLoadException implements Exception {
  VenueDashboardLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
