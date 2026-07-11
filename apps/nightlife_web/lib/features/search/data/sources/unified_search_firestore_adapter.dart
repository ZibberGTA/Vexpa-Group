import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/discovery/searchable_content_records.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';

import '../../../../core/firebase/vexda_firebase.dart';

/// Loads searchable entity rows from Firestore for unified discovery search.
class UnifiedSearchFirestoreAdapter {
  UnifiedSearchFirestoreAdapter({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? get _db {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<UnifiedSearchCandidateBatch> loadCandidates({
    required String cleanQuery,
    required bool includeDrinks,
    required bool includeDeals,
    required bool includeEvents,
    required bool includeTrails,
  }) async {
    final futures = <Future<UnifiedSearchCandidateBatch>>[];

    if (includeDrinks) {
      futures.add(_loadDrinks(cleanQuery));
    }
    if (includeDeals) {
      futures.add(_loadDeals());
    }
    if (includeEvents) {
      futures.add(_loadEvents());
    }
    if (includeTrails) {
      futures.add(_loadTrails());
    }

    if (futures.isEmpty) return UnifiedSearchCandidateBatch.empty;

    final batches = await Future.wait(futures);
    return UnifiedSearchCandidateBatch(
      drinks: batches.expand((batch) => batch.drinks).toList(),
      deals: batches.expand((batch) => batch.deals).toList(),
      events: batches.expand((batch) => batch.events).toList(),
      trails: batches.expand((batch) => batch.trails).toList(),
    );
  }

  Future<UnifiedSearchCandidateBatch> _loadDrinks(String cleanQuery) async {
    final db = _db;
    if (db == null) return UnifiedSearchCandidateBatch.empty;

    try {
      Query<Map<String, dynamic>> drinksQuery = db
          .collection('drinks')
          .where('isDeleted', isEqualTo: false)
          .where('available', isEqualTo: true);

      if (cleanQuery.isNotEmpty) {
        drinksQuery = drinksQuery.where('searchTerms', arrayContains: cleanQuery);
      }

      final snapshot = await drinksQuery.limit(80).get();
      final drinks = snapshot.docs.map(_mapDrink).whereType<SearchableDrinkRecord>();
      return UnifiedSearchCandidateBatch(drinks: drinks.toList());
    } on Object catch (error, stackTrace) {
      _logFailure('Drink search', error, stackTrace);
      return UnifiedSearchCandidateBatch.empty;
    }
  }

  SearchableDrinkRecord? _mapDrink(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final venueId = data['venueId']?.toString();
    if (venueId == null || venueId.isEmpty) return null;

    return SearchableDrinkRecord(
      id: doc.id,
      venueId: venueId,
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      priceLabel: SearchTextUtils.formatPrice(data['price']),
      brand: data['brand']?.toString() ?? '',
      ingredients: data['ingredients']?.toString() ?? '',
      available: data['available'] == true,
      isDeleted: data['isDeleted'] == true,
      searchTerms: _stringList(data['searchTerms']),
      searchKeywords: _stringList(data['searchKeywords']),
    );
  }

  Future<UnifiedSearchCandidateBatch> _loadDeals() async {
    final db = _db;
    if (db == null) return UnifiedSearchCandidateBatch.empty;

    try {
      final snapshot = await db
          .collection('deals')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(80)
          .get();

      final deals = snapshot.docs.map(_mapDeal).whereType<SearchableDealRecord>();
      return UnifiedSearchCandidateBatch(deals: deals.toList());
    } on Object catch (error, stackTrace) {
      _logFailure('Deal search', error, stackTrace);
      return UnifiedSearchCandidateBatch.empty;
    }
  }

  SearchableDealRecord? _mapDeal(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final venueId = data['venueId']?.toString();
    if (venueId == null || venueId.isEmpty) return null;

    return SearchableDealRecord(
      id: doc.id,
      venueId: venueId,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      isActive: data['isActive'] == true,
      isDeleted: data['isDeleted'] == true,
      searchTerms: _stringList(data['searchTerms']),
      searchKeywords: _stringList(data['searchKeywords']),
    );
  }

  Future<UnifiedSearchCandidateBatch> _loadEvents() async {
    final db = _db;
    if (db == null) return UnifiedSearchCandidateBatch.empty;

    try {
      final snapshot = await db
          .collection('events')
          .where('isDeleted', isEqualTo: false)
          .limit(80)
          .get();

      final events = snapshot.docs.map(_mapEvent).whereType<SearchableEventRecord>();
      return UnifiedSearchCandidateBatch(events: events.toList());
    } on Object catch (error, stackTrace) {
      _logFailure('Event search', error, stackTrace);
      return UnifiedSearchCandidateBatch.empty;
    }
  }

  SearchableEventRecord? _mapEvent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final venueId = data['venueId']?.toString();
    if (venueId == null || venueId.isEmpty) return null;

    final endTimestamp = data['endDateTime'] as Timestamp?;
    final startTimestamp =
        data['startDateTime'] as Timestamp? ?? data['dateTime'] as Timestamp?;

    return SearchableEventRecord(
      id: doc.id,
      venueId: venueId,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      isActive: data['isActive'] != false,
      isDeleted: data['isDeleted'] == true,
      startDateTime: startTimestamp?.toDate(),
      endDateTime: endTimestamp?.toDate(),
      searchTerms: _stringList(data['searchTerms']),
      searchKeywords: _stringList(data['searchKeywords']),
    );
  }

  Future<UnifiedSearchCandidateBatch> _loadTrails() async {
    final db = _db;
    if (db == null) return UnifiedSearchCandidateBatch.empty;

    try {
      final snapshot = await db.collection('trails').limit(80).get();
      final trails = snapshot.docs.map(_mapTrail).whereType<SearchableTrailRecord>();
      return UnifiedSearchCandidateBatch(trails: trails.toList());
    } on Object catch (error, stackTrace) {
      _logFailure('Trail search', error, stackTrace);
      return UnifiedSearchCandidateBatch.empty;
    }
  }

  SearchableTrailRecord? _mapTrail(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status']?.toString().toLowerCase() ?? '';
    final published = data['published'] == true || status == 'published';

    final availabilityEnd =
        (data['availabilityEnd'] as Timestamp?)?.toDate() ??
        (data['endTime'] as Timestamp?)?.toDate();

    final trailName = (data['name'] ?? data['title'] ?? '').toString();
    final trailDescription = (data['description'] ?? data['subtitle'] ?? '').toString();
    final trailArea = (data['area'] ?? '').toString();

    final venueIds = <String>[];
    final stopsRaw = data['stops'];
    if (stopsRaw is List) {
      for (final stop in stopsRaw) {
        if (stop is! Map) continue;
        final stopMap = Map<String, dynamic>.from(stop);
        final venueId = stopMap['venueId']?.toString();
        if (venueId != null && venueId.isNotEmpty) {
          venueIds.add(venueId);
        }
      }
    }

    if (venueIds.isEmpty) return null;

    return SearchableTrailRecord(
      id: doc.id,
      name: trailName,
      description: trailDescription,
      area: trailArea,
      published: published,
      availabilityEnd: availabilityEnd,
      searchTerms: _stringList(data['searchTerms']),
      venueIds: venueIds,
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList();
  }

  void _logFailure(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[UnifiedSearchFirestoreAdapter] $label failed: $error');
      debugPrint('$stackTrace');
    }
  }
}
