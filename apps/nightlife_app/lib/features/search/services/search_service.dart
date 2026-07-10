import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/venue_branding_parser.dart';

class SearchService {
  static final _db = FirebaseFirestore.instance;

  static String _normalise(String value) => value.trim().toLowerCase();

  static bool _containsQuery(dynamic value, String query) {
    if (query.isEmpty) return true;
    if (value == null) return false;

    if (value is Iterable) {
      return value.any((item) => _containsQuery(item, query));
    }

    return value.toString().toLowerCase().contains(query);
  }

  static String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '';

    if (rawPrice is num) {
      return '£${rawPrice.toStringAsFixed(2)}';
    }

    final value = rawPrice.toString().trim();
    if (value.isEmpty) return '';
    return value.startsWith('£') ? value : '£$value';
  }

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

  static bool _venuePassesFilters({
    required Map<String, dynamic> venueData,
    String? crowdLevel,
    bool busyOnly = false,
    String? venueType,
  }) {
    if (venueType != null && venueType != 'All') {
      final venueKind = (venueData['venueType'] ?? venueData['category'] ?? '')
          .toString()
          .toLowerCase();
      if (!venueKind.contains(venueType.toLowerCase())) return false;
    }

    final venueCrowd = (venueData['crowdLevel'] ??
            venueData['currentCrowdLevel'] ??
            'unknown')
        .toString();

    if (crowdLevel != null && crowdLevel != 'All' && venueCrowd != crowdLevel) {
      return false;
    }

    if (busyOnly && venueCrowd != 'busy' && venueCrowd != 'packed') {
      return false;
    }

    return true;
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

  static void _addVenueResult({
    required Map<String, Map<String, dynamic>> grouped,
    required Map<String, dynamic> venueData,
    Map<String, dynamic>? drink,
    Map<String, dynamic>? deal,
    Map<String, dynamic>? event,
  }) {
    final venueId = venueData['id']?.toString() ?? '';
    if (venueId.isEmpty) return;

    final result = grouped.putIfAbsent(
      venueId,
      () => _venueResultShell(venueData),
    );

    if (drink != null) {
      final drinks = result['matchedDrinks'] as List<Map<String, dynamic>>;
      if (!drinks.any((item) => item['id'] == drink['id'])) {
        drinks.add(drink);
      }
    }

    if (deal != null) {
      final deals = result['matchedDeals'] as List<Map<String, dynamic>>;
      if (!deals.any((item) => item['id'] == deal['id'])) {
        deals.add(deal);
      }
      result['hasDeal'] = true;
    }

    if (event != null) {
      final events = result['matchedEvents'] as List<Map<String, dynamic>>;
      if (!events.any((item) => item['id'] == event['id'])) {
        events.add(event);
      }
    }
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
    final cleanQuery = _normalise(query);
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
            _containsQuery(drinkData['name'], cleanQuery) ||
            _containsQuery(drinkData['brand'], cleanQuery) ||
            _containsQuery(drinkData['category'], cleanQuery) ||
            _containsQuery(drinkData['ingredients'], cleanQuery) ||
            _containsQuery(drinkData['searchTerms'], cleanQuery) ||
            _containsQuery(drinkData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        if (priceBand != null && priceBand != 'All') {
          final price = drinkData['price'];
          if (price is num) {
            final matchesPrice = switch (priceBand) {
              '£' => price < 6,
              '££' => price >= 6 && price < 12,
              '£££' => price >= 12,
              _ => true,
            };
            if (!matchesPrice) continue;
          }
        }

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!_venuePassesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        _addVenueResult(
          grouped: grouped,
          venueData: venueData,
          drink: {
            'id': drinkDoc.id,
            'name': drinkData['name']?.toString() ?? '',
            'category': drinkData['category']?.toString() ?? '',
            'price': _formatPrice(drinkData['price']),
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
            _containsQuery(dealData['title'], cleanQuery) ||
            _containsQuery(dealData['description'], cleanQuery) ||
            _containsQuery(dealData['category'], cleanQuery) ||
            _containsQuery(dealData['searchTerms'], cleanQuery) ||
            _containsQuery(dealData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        final venueId = dealData['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!_venuePassesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        _addVenueResult(
          grouped: grouped,
          venueData: venueData,
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
        final startTimestamp = eventData['startDateTime'] as Timestamp? ?? eventData['dateTime'] as Timestamp?;
        final endDate = endTimestamp?.toDate() ??
            (startTimestamp == null ? null : startTimestamp.toDate().add(const Duration(hours: 24)));
        if (endDate == null || endDate.isBefore(now)) continue;

        final matchesQuery = cleanQuery.isEmpty ||
            _containsQuery(eventData['title'], cleanQuery) ||
            _containsQuery(eventData['description'], cleanQuery) ||
            _containsQuery(eventData['category'], cleanQuery) ||
            _containsQuery(eventData['searchTerms'], cleanQuery) ||
            _containsQuery(eventData['searchKeywords'], cleanQuery);

        if (!matchesQuery) continue;

        final venueId = eventData['venueId']?.toString();
        if (venueId == null || venueId.isEmpty) continue;

        final venueData = await _loadVenue(venueId, venueCache);
        if (venueData == null) continue;

        if (!_venuePassesFilters(
          venueData: venueData,
          crowdLevel: crowdLevel,
          busyOnly: busyOnly,
          venueType: venueType,
        )) {
          continue;
        }

        _addVenueResult(
          grouped: grouped,
          venueData: venueData,
          event: {
            'id': eventDoc.id,
            'title': eventData['title']?.toString() ?? '',
            'dateTime': eventData['dateTime'],
          },
        );
      }
    }

    final results = grouped.values.toList();

    results.sort((a, b) {
      final aCount = (a['matchedDrinks'] as List).length +
          (a['matchedDeals'] as List).length +
          (a['matchedEvents'] as List).length;
      final bCount = (b['matchedDrinks'] as List).length +
          (b['matchedDeals'] as List).length +
          (b['matchedEvents'] as List).length;
      return bCount.compareTo(aCount);
    });

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
