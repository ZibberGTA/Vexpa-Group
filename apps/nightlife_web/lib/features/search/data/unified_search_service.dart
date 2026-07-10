import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_composer.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import 'search_ranking.dart';
import 'search_text_utils.dart';
import 'search_venue_filter.dart';
import 'sources/venue_search_data_source.dart';

/// Unified Firestore search across venues, drinks, deals, events and trails.
///
/// Mirrors the mobile [SearchService] flow while reusing the web venue catalog.
/// Venue matching, ranking, and response composition use the Discovery Engine.
class UnifiedSearchService {
  UnifiedSearchService({
    FirebaseFirestore? firestore,
    VenueSearchDataSource? venueSearchDataSource,
    DiscoveryUnifiedSearchComposer? searchComposer,
  })  : _firestoreOverride = firestore,
        _venueSearch = venueSearchDataSource ?? VenueSearchDataSource(),
        _composer = searchComposer ?? const DiscoveryUnifiedSearchComposer();

  final FirebaseFirestore? _firestoreOverride;
  final VenueSearchDataSource _venueSearch;
  final DiscoveryUnifiedSearchComposer _composer;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<UnifiedSearchResponse> search({
    required String query,
    required List<VenueSearchResult> catalog,
    required SearchFilterCategory category,
    required bool usingFallback,
  }) async {
    final trimmed = query.trim();
    final catalogById = {
      for (var index = 0; index < catalog.length; index++)
        catalog[index].id: index,
    };

    if (trimmed.isEmpty) {
      return _allVenuesResponse(catalog, category);
    }

    if (usingFallback) {
      return _fallbackVenueSearch(trimmed, catalog, category);
    }

    final cleanQuery = SearchTextUtils.normalise(trimmed);
    if (cleanQuery.length < 2 && category != SearchFilterCategory.venues) {
      return UnifiedSearchResponse.empty;
    }

    final grouped = <String, SearchVenueMatch>{};
    final shouldSearchVenues =
        category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.openNow;
    final shouldSearchDrinks =
        category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.drinks;
    final shouldSearchDeals =
        category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.deals;
    final shouldSearchEvents =
        category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.events;
    final shouldSearchTrails =
        category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.trails;

    if (shouldSearchVenues) {
      await _searchDirectVenues(
        query: trimmed,
        catalog: catalog,
        catalogById: catalogById,
        grouped: grouped,
      );
    }

    if (shouldSearchDrinks) {
      await _searchDrinks(cleanQuery, catalog, catalogById, grouped);
    }
    if (shouldSearchDeals) {
      await _searchDeals(cleanQuery, catalog, catalogById, grouped);
    }
    if (shouldSearchEvents) {
      await _searchEvents(cleanQuery, catalog, catalogById, grouped);
    }
    if (shouldSearchTrails) {
      await _searchTrails(cleanQuery, catalog, catalogById, grouped);
    }

    return _buildResponse(grouped, trimmed, category);
  }

  UnifiedSearchResponse _allVenuesResponse(
    List<VenueSearchResult> catalog,
    SearchFilterCategory category,
  ) {
    final matches = <SearchVenueMatch>[];
    for (var index = 0; index < catalog.length; index++) {
      final venue = catalog[index];
      if (category == SearchFilterCategory.openNow && !venue.isOpen) {
        continue;
      }
      matches.add(
        SearchVenueMatch(
          catalogIndex: index,
          venue: venue,
          directVenueMatch: true,
        ),
      );
    }

    return UnifiedSearchResponse(
      matches: matches,
      groupCounts: SearchGroupCounts(venues: matches.length),
    );
  }

  Future<UnifiedSearchResponse> _fallbackVenueSearch(
    String query,
    List<VenueSearchResult> catalog,
    SearchFilterCategory category,
  ) async {
    if (category != SearchFilterCategory.venues &&
        category != SearchFilterCategory.openNow) {
      return UnifiedSearchResponse.empty;
    }

    final venueMatches = await _venueSearch.search(
      query: query,
      catalog: catalog,
    );

    final matches = <SearchVenueMatch>[];
    for (final venue in venueMatches) {
      final index = catalog.indexWhere((entry) => entry.id == venue.id);
      if (index < 0) continue;
      if (category == SearchFilterCategory.openNow && !venue.isOpen) continue;
      matches.add(
        SearchVenueMatch(
          catalogIndex: index,
          venue: venue,
          directVenueMatch: true,
          rankScore: SearchRanking.score(
            SearchVenueMatch(
              catalogIndex: index,
              venue: venue,
              directVenueMatch: true,
            ),
            query,
          ),
        ),
      );
    }

    SearchRanking.sortMatches(matches, query);
    return UnifiedSearchResponse(
      matches: matches,
      groupCounts: SearchGroupCounts(venues: matches.length),
    );
  }

  Future<void> _searchDirectVenues({
    required String query,
    required List<VenueSearchResult> catalog,
    required Map<String, int> catalogById,
    required Map<String, SearchVenueMatch> grouped,
  }) async {
    final venueMatches = await _venueSearch.search(
      query: query,
      catalog: catalog,
    );

    for (final venue in venueMatches) {
      final index = catalogById[venue.id];
      if (index == null) continue;
      _upsertMatch(
        grouped: grouped,
        catalog: catalog,
        venueId: venue.id,
        catalogIndex: index,
        venue: venue,
        directVenueMatch: true,
      );
    }
  }

  Future<void> _searchDrinks(
    String cleanQuery,
    List<VenueSearchResult> catalog,
    Map<String, int> catalogById,
    Map<String, SearchVenueMatch> grouped,
  ) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return;

    try {
      Query<Map<String, dynamic>> drinksQuery = firestore
          .collection('drinks')
          .where('isDeleted', isEqualTo: false)
          .where('available', isEqualTo: true);

      if (cleanQuery.isNotEmpty) {
        drinksQuery = drinksQuery.where('searchTerms', arrayContains: cleanQuery);
      }

      final snapshot = await drinksQuery.limit(80).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final venueId = data['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(data['name'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['brand'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['ingredients'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchKeywords'], cleanQuery);
        if (!matchesQuery) continue;

        final catalogIndex = catalogById[venueId];
        if (catalogIndex == null) continue;

        final drink = MatchedDrink(
          id: doc.id,
          name: data['name']?.toString() ?? '',
          category: data['category']?.toString() ?? '',
          price: SearchTextUtils.formatPrice(data['price']),
          available: data['available'] == true,
        );

        _upsertMatch(
          grouped: grouped,
          catalog: catalog,
          venueId: venueId,
          catalogIndex: catalogIndex,
          drink: drink,
        );
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[UnifiedSearchService] Drink search failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _searchDeals(
    String cleanQuery,
    List<VenueSearchResult> catalog,
    Map<String, int> catalogById,
    Map<String, SearchVenueMatch> grouped,
  ) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection('deals')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(80)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(data['title'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['description'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchKeywords'], cleanQuery);
        if (!matchesQuery) continue;

        final venueId = data['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final catalogIndex = catalogById[venueId];
        if (catalogIndex == null) continue;

        _upsertMatch(
          grouped: grouped,
          catalog: catalog,
          venueId: venueId,
          catalogIndex: catalogIndex,
          deal: MatchedDeal(
            id: doc.id,
            title: data['title']?.toString() ?? '',
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[UnifiedSearchService] Deal search failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _searchEvents(
    String cleanQuery,
    List<VenueSearchResult> catalog,
    Map<String, int> catalogById,
    Map<String, SearchVenueMatch> grouped,
  ) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection('events')
          .where('isDeleted', isEqualTo: false)
          .limit(80)
          .get();

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final endTimestamp = data['endDateTime'] as Timestamp?;
        final startTimestamp =
            data['startDateTime'] as Timestamp? ?? data['dateTime'] as Timestamp?;
        final endDate = endTimestamp?.toDate() ??
            startTimestamp?.toDate().add(const Duration(hours: 24));
        if (endDate == null || endDate.isBefore(now)) continue;

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(data['title'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['description'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchKeywords'], cleanQuery);
        if (!matchesQuery) continue;

        final venueId = data['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final catalogIndex = catalogById[venueId];
        if (catalogIndex == null) continue;

        _upsertMatch(
          grouped: grouped,
          catalog: catalog,
          venueId: venueId,
          catalogIndex: catalogIndex,
          event: MatchedEvent(
            id: doc.id,
            title: data['title']?.toString() ?? '',
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[UnifiedSearchService] Event search failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _searchTrails(
    String cleanQuery,
    List<VenueSearchResult> catalog,
    Map<String, int> catalogById,
    Map<String, SearchVenueMatch> grouped,
  ) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return;

    try {
      final snapshot = await firestore.collection('trails').limit(80).get();
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        final published = data['published'] == true || status == 'published';
        if (!published) continue;

        final availabilityEnd =
            (data['availabilityEnd'] as Timestamp?)?.toDate() ??
            (data['endTime'] as Timestamp?)?.toDate();
        if (availabilityEnd != null && availabilityEnd.isBefore(now)) {
          continue;
        }

        final trailName =
            (data['name'] ?? data['title'] ?? '').toString();
        final trailDescription =
            (data['description'] ?? data['subtitle'] ?? '').toString();
        final trailArea = (data['area'] ?? '').toString();

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(trailName, cleanQuery) ||
            SearchTextUtils.containsQuery(trailDescription, cleanQuery) ||
            SearchTextUtils.containsQuery(trailArea, cleanQuery) ||
            SearchTextUtils.containsQuery(data['searchTerms'], cleanQuery);
        if (!matchesQuery) continue;

        final trail = MatchedTrail(id: doc.id, name: trailName);
        final stopsRaw = data['stops'];
        if (stopsRaw is! List) continue;

        for (final stop in stopsRaw) {
          if (stop is! Map) continue;
          final stopMap = Map<String, dynamic>.from(stop);
          final venueId = stopMap['venueId']?.toString();
          if (venueId == null || venueId.isEmpty) continue;

          final catalogIndex = catalogById[venueId];
          if (catalogIndex == null) continue;

          _upsertMatch(
            grouped: grouped,
            catalog: catalog,
            venueId: venueId,
            catalogIndex: catalogIndex,
            trail: trail,
          );
        }
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[UnifiedSearchService] Trail search failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  void _upsertMatch({
    required Map<String, SearchVenueMatch> grouped,
    required List<VenueSearchResult> catalog,
    required String venueId,
    required int catalogIndex,
    VenueSearchResult? venue,
    bool directVenueMatch = false,
    MatchedDrink? drink,
    MatchedDeal? deal,
    MatchedEvent? event,
    MatchedTrail? trail,
  }) {
    final existing = grouped[venueId];
    final resolvedVenue = venue ?? existing?.venue ?? catalog[catalogIndex];

    var drinks = List<MatchedDrink>.from(existing?.matchedDrinks ?? const []);
    var deals = List<MatchedDeal>.from(existing?.matchedDeals ?? const []);
    var events = List<MatchedEvent>.from(existing?.matchedEvents ?? const []);
    var trails = List<MatchedTrail>.from(existing?.matchedTrails ?? const []);

    if (drink != null && !drinks.any((item) => item.id == drink.id)) {
      drinks.add(drink);
    }
    if (deal != null && !deals.any((item) => item.id == deal.id)) {
      deals.add(deal);
    }
    if (event != null && !events.any((item) => item.id == event.id)) {
      events.add(event);
    }
    if (trail != null && !trails.any((item) => item.id == trail.id)) {
      trails.add(trail);
    }

    grouped[venueId] = SearchVenueMatch(
      catalogIndex: catalogIndex,
      venue: resolvedVenue,
      directVenueMatch: directVenueMatch || (existing?.directVenueMatch ?? false),
      matchedDrinks: drinks,
      matchedDeals: deals,
      matchedEvents: events,
      matchedTrails: trails,
    );
  }

  UnifiedSearchResponse _buildResponse(
    Map<String, SearchVenueMatch> grouped,
    String query,
    SearchFilterCategory category,
  ) {
    final composed = _composer.composeResponse(
      groupedMatches: grouped.values,
      query: query,
      category: category,
      withRankScore: (match, rankScore) => match.copyWith(rankScore: rankScore),
    );

    return UnifiedSearchResponse(
      matches: composed.matches,
      groupCounts: composed.groupCounts,
    );
  }
}
