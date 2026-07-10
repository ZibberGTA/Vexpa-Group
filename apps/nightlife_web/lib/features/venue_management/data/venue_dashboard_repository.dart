import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_performance_highlight.dart';
import '../models/venue_dashboard_stat.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_dashboard_whats_next_action.dart';
import '../models/venue_profile_completion.dart';
import '../services/venue_profile_completion_calculator.dart';
import 'venue_activity_service.dart';
import 'venue_analytics_service.dart';

/// Resolves active venue context and dashboard home data from Firestore.
class VenueDashboardRepository {
  VenueDashboardRepository({
    FirebaseFirestore? firestore,
    VenueAnalyticsService? analyticsService,
    VenueActivitySource? activityService,
  })  : _firestoreOverride = firestore,
        _analyticsService = analyticsService ?? VenueAnalyticsService(firestore: firestore),
        _activityService = activityService ?? VenueActivityService(firestore: firestore);

  final FirebaseFirestore? _firestoreOverride;
  final VenueAnalyticsService _analyticsService;
  final VenueActivitySource _activityService;

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

    final stats = VenueDashboardStatsData.fromAnalytics(
      profileViews: analytics.current.profileViews,
      saves: analytics.current.saves,
      drinkViews: analytics.current.drinkViews,
      dealViews: analytics.current.dealViews,
      eventViews: analytics.current.eventViews,
      profileViewsChange: analytics.previous == null
          ? null
          : VenueAnalyticsService.percentChange(
              analytics.current.profileViews,
              analytics.previous!.profileViews,
            ),
      savesChange: analytics.previous == null
          ? null
          : VenueAnalyticsService.percentChange(
              analytics.current.saves,
              analytics.previous!.saves,
            ),
      drinkViewsChange: analytics.previous == null
          ? null
          : VenueAnalyticsService.percentChange(
              analytics.current.drinkViews,
              analytics.previous!.drinkViews,
            ),
      dealViewsChange: analytics.previous == null
          ? null
          : VenueAnalyticsService.percentChange(
              analytics.current.dealViews,
              analytics.previous!.dealViews,
            ),
      eventViewsChange: analytics.previous == null
          ? null
          : VenueAnalyticsService.percentChange(
              analytics.current.eventViews,
              analytics.previous!.eventViews,
            ),
    );

    final drinkCount = await _countDrinks(venue.id);
    final dealCount = await _countDeals(venue.id);
    final eventCount = await _countEvents(venue.id);
    final hasUpcomingEvent = await _hasUpcomingEvent(venue.id);

    final recentActivity = await _activityService.loadRecentActivity(
      venueId: venue.id,
    );

    return VenueDashboardHomeData(
      dateRange: dateRange,
      stats: stats,
      chartPoints: analytics.chartPoints,
      profileCompletion: profileCompletion,
      highlights: analytics.hasData
          ? _analyticsHighlights(analytics)
          : VenueDashboardInsightsBuilder.setupHighlights(),
      whatsNext: _buildWhatsNext(
        venue: venue,
        profileCompletion: profileCompletion,
        drinkCount: drinkCount,
        dealCount: dealCount,
        eventCount: eventCount,
        hasUpcomingEvent: hasUpcomingEvent,
      ),
      recentActivity: recentActivity,
      analyticsAvailable: analytics.hasData,
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
    if (preferredVenueId != null) {
      final match = venues.where((venue) => venue.id == preferredVenueId);
      if (match.isNotEmpty) return match.first;
    }

    if (roleProfile.venueIds.isNotEmpty) {
      for (final id in roleProfile.venueIds) {
        final match = venues.where((venue) => venue.id == id);
        if (match.isNotEmpty) return match.first;
      }
    }

    return venues.first;
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

  List<VenueDashboardPerformanceHighlight> _analyticsHighlights(
    VenueAnalyticsSnapshot analytics,
  ) {
    final highlights = <VenueDashboardPerformanceHighlight>[];
    final previous = analytics.previous;

    if (previous != null) {
      final profileChange = VenueAnalyticsService.percentChange(
        analytics.current.profileViews,
        previous.profileViews,
      );
      if (profileChange != null && analytics.current.profileViews > 0) {
        highlights.add(
          VenueDashboardPerformanceHighlight(
            message:
                'Your profile views are ${profileChange.abs().toStringAsFixed(0)}% ${profileChange >= 0 ? 'higher' : 'lower'} than the previous period.',
            buttonLabel: 'View Analytics',
            icon: Icons.visibility_outlined,
            targetTab: VenueDashboardTab.analytics,
            accent: VenueDashboardHighlightAccent.blue,
          ),
        );
      }

      final savesChange = VenueAnalyticsService.percentChange(
        analytics.current.saves,
        previous.saves,
      );
      if (savesChange != null && analytics.current.saves > 0) {
        highlights.add(
          VenueDashboardPerformanceHighlight(
            message:
                'Customers saved your venue ${savesChange >= 0 ? '$savesChange% more' : '${savesChange.abs()}% less'} than the previous period.',
            buttonLabel: 'View Analytics',
            icon: Icons.bookmark_outline_rounded,
            targetTab: VenueDashboardTab.analytics,
            accent: VenueDashboardHighlightAccent.pink,
          ),
        );
      }
    }

    if (highlights.length < 4) {
      highlights.addAll(
        VenueDashboardInsightsBuilder.setupHighlights().take(4 - highlights.length),
      );
    }

    return highlights.take(4).toList();
  }

  List<VenueDashboardWhatsNextAction> _buildWhatsNext({
    required VenueModel venue,
    required VenueProfileCompletion profileCompletion,
    required int drinkCount,
    required int dealCount,
    required int eventCount,
    required bool hasUpcomingEvent,
  }) {
    final actions = <VenueDashboardWhatsNextAction>[];

    if (venue.galleryImageUrls.isEmpty) {
      actions.add(
        const VenueDashboardWhatsNextAction(
          title: 'Add more photos',
          message: 'Venues with more photos get more views.',
          buttonLabel: 'Upload photos',
          icon: Icons.photo_library_outlined,
          targetTab: VenueDashboardTab.gallery,
        ),
      );
    }

    if (dealCount == 0) {
      actions.add(
        const VenueDashboardWhatsNextAction(
          title: 'Create a new deal',
          message: 'Deals increase customer engagement.',
          buttonLabel: 'Create deal',
          icon: Icons.local_offer_outlined,
          targetTab: VenueDashboardTab.deals,
        ),
      );
    }

    if (!hasUpcomingEvent) {
      actions.add(
        const VenueDashboardWhatsNextAction(
          title: 'Add an upcoming event',
          message: 'Events bring more people through the door.',
          buttonLabel: 'Add event',
          icon: Icons.event_outlined,
          targetTab: VenueDashboardTab.events,
        ),
      );
    }

    if (profileCompletion.completedSteps < profileCompletion.totalSteps) {
      actions.add(
        VenueDashboardWhatsNextAction(
          title: 'Complete your profile',
          message:
              'Finish ${profileCompletion.totalSteps - profileCompletion.completedSteps} more steps to boost visibility.',
          buttonLabel: 'Go to profile',
          icon: Icons.storefront_outlined,
          targetTab: VenueDashboardTab.venueProfile,
        ),
      );
    }

    if (drinkCount == 0) {
      actions.add(
        const VenueDashboardWhatsNextAction(
          title: 'Add your drinks menu',
          message: 'Help customers discover what you serve.',
          buttonLabel: 'Add drinks',
          icon: Icons.local_bar_outlined,
          targetTab: VenueDashboardTab.drinks,
        ),
      );
    }

    return actions.take(4).toList();
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
