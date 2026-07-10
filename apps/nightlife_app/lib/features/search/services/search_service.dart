import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/application/discovery_mobile_search_rules.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';

import '../../../core/utils/venue_branding_parser.dart';

class SearchService {
  static final _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> _loadVenue(
    String venueId,
    Map<String, Map<String, dynamic>?> cache,
  ) async {
    if (cache.containsKey(venueId)) return cache[venueId];

    final venueDoc = await _db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) {
      cache[venueId] = null;
      return null;
    }

    final venueData = venueDoc.data();
    if (venueData == null ||
        venueData['isDeleted'] == true ||
        venueData['isPublished'] == false) {
      cache[venueId] = null;
      return null;
    }

    cache[venueId] = {
      'id': venueDoc.id,
      ...venueData,
    };
    return cache[venueId];
  }

  static Map<String, dynamic> _venueResultShell(Map<String, dynamic> venueData) {
    return {
      'venueId': venueData['id']?.toString() ?? '',
      'venueName': venueData['name']?.toString() ?? 'Unknown venue',
      'venueCategory':
          (venueData['category'] ?? venueData['venueType'] ?? '').toString(),
      'bannerImageUrl': VenueBrandingParser.resolveBannerImageUrl(venueData),
      'logoUrl': VenueBrandingParser.resolveLogoUrl(venueData),
      'crowdLevel': (venueData['crowdLevel'] ??
              venueData['currentCrowdLevel'] ??
              'unknown')
          .toString(),
      'matchedDrinks': <Map<String, dynamic>>[],
      'matchedDeals': <Map<String, dynamic>>[],
      'matchedEvents': <Map<String, dynamic>>[],
      'hasDeal': false,
    };
  }

  static Future<List<Map<String, dynamic>>> searchVenueResults({
    required String query,
    String? category,
    String? crowdLevel,
    String quickFilter = 'All',
    bool busyOnly = false,
    String? venueType,
    String? priceBand,
    int resultLimit = 30,
  }) async {
    final cleanQuery = SearchTextUtils.normalise(query);
    if (cleanQuery.length < 2) return <Map<String, dynamic>>[];
    final grouped = <String, Map<String, dynamic>>{};
    final venueCache = <String, Map<String, dynamic>?>{};

    final shouldSearchDrinks = quickFilter == 'All' || quickFilter == 'Drinks';
    final shouldSearchDeals = quickFilter == 'All' || quickFilter == 'Deals';
    final shouldSearchEvents = quickFilter == 'All' || quickFilter == 'Events';

    if (shouldSearchDrinks) {
      Query<Map<String, dynamic>> drinksQuery = _db
          .collection('drinks')
          .where('isDeleted', isEqualTo: false)
          .where('available', isEqualTo: true);

      if (cleanQuery.isNotEmpty) {
        drinksQuery = drinksQuery.where(
          'searchTerms',
          arrayContains: cleanQuery,
        );
      }

      if (category != null && category != 'All') {
        drinksQuery = drinksQuery.where('category', isEqualTo: category);
      }

      final drinkSnapshot = await drinksQuery.limit(80).get();

      for (final drinkDoc in drinkSnapshot.docs) {
        final drinkData = drinkDoc.data();
        final venueId = drinkData['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(drinkData['name'], cleanQuery) ||
            SearchTextUtils.containsQuery(drinkData['brand'], cleanQuery) ||
            SearchTextUtils.containsQuery(drinkData['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(drinkData['ingredients'], cleanQuery) ||
            SearchTextUtils.containsQuery(drinkData['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(drinkData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        if (priceBand != null &&
            !DiscoveryVenueFilterRules.matchesPriceBand(
              price: drinkData['price'],
              priceBand: priceBand,
            )) {
          continue;
        }

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!DiscoveryVenueFilterRules.passesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        DiscoveryMobileSearchMerger.upsertMatch(
          grouped: grouped,
          venueData: venueData,
          buildShell: _venueResultShell,
          drink: {
            'id': drinkDoc.id,
            'name': drinkData['name']?.toString() ?? '',
            'category': drinkData['category']?.toString() ?? '',
            'price': SearchTextUtils.formatPrice(drinkData['price']),
            'available': drinkData['available'] == true,
          },
        );
      }
    }

    if (shouldSearchDeals) {
      final dealSnapshot = await _db
          .collection('deals')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(80)
          .get();

      for (final dealDoc in dealSnapshot.docs) {
        final dealData = dealDoc.data();

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(dealData['title'], cleanQuery) ||
            SearchTextUtils.containsQuery(dealData['description'], cleanQuery) ||
            SearchTextUtils.containsQuery(dealData['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(dealData['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(dealData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        final venueId = dealData['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!DiscoveryVenueFilterRules.passesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        DiscoveryMobileSearchMerger.upsertMatch(
          grouped: grouped,
          venueData: venueData,
          buildShell: _venueResultShell,
          deal: {
            'id': dealDoc.id,
            'title': dealData['title']?.toString() ?? '',
          },
        );
      }
    }

    if (shouldSearchEvents) {
      final eventSnapshot = await _db
          .collection('events')
          .where('isDeleted', isEqualTo: false)
          .limit(80)
          .get();

      final now = DateTime.now();

      for (final eventDoc in eventSnapshot.docs) {
        final eventData = eventDoc.data();
        final endTimestamp = eventData['endDateTime'] as Timestamp?;
        final startTimestamp = eventData['startDateTime'] as Timestamp? ??
            eventData['dateTime'] as Timestamp?;
        final endDate = endTimestamp?.toDate() ??
            (startTimestamp == null
                ? null
                : startTimestamp.toDate().add(const Duration(hours: 24)));
        if (endDate == null || endDate.isBefore(now)) continue;

        final matchesQuery = cleanQuery.isEmpty ||
            SearchTextUtils.containsQuery(eventData['title'], cleanQuery) ||
            SearchTextUtils.containsQuery(eventData['description'], cleanQuery) ||
            SearchTextUtils.containsQuery(eventData['category'], cleanQuery) ||
            SearchTextUtils.containsQuery(eventData['searchTerms'], cleanQuery) ||
            SearchTextUtils.containsQuery(eventData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        final venueId = eventData['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!DiscoveryVenueFilterRules.passesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        DiscoveryMobileSearchMerger.upsertMatch(
          grouped: grouped,
          venueData: venueData,
          buildShell: _venueResultShell,
          event: {
            'id': eventDoc.id,
            'title': eventData['title']?.toString() ?? '',
            'dateTime': eventData['dateTime'],
          },
        );
      }
    }

    final results = grouped.values.toList();
    DiscoveryMobileSearchRanking.sortByMatchCount(results);
    return results.take(resultLimit).toList();
  }

  static Future<List<Map<String, dynamic>>> searchDrinks({
    required String query,
    String? category,
    String? crowdLevel,
    bool dealsOnly = false,
    bool busyOnly = false,
    String? venueType,
    String? priceBand,
  }) {
    return searchVenueResults(
      query: query,
      category: category,
      crowdLevel: crowdLevel,
      quickFilter: dealsOnly ? 'Deals' : 'All',
      busyOnly: busyOnly,
      venueType: venueType,
      priceBand: priceBand,
    );
  }
}
