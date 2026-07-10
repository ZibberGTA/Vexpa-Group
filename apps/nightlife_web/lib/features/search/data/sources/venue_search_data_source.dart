import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/vexda_firebase.dart';
import '../../../venues/models/venue_model.dart';
import '../../models/venue_search_result.dart';
import '../search_venue_filter.dart';
import '../search_venue_mapper.dart';
import '../venue_search_matcher.dart';
import 'search_data_source.dart';

/// Firestore-backed venue search — aligned with the mobile map search flow.
class VenueSearchDataSource implements SearchDataSource {
  VenueSearchDataSource({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  @override
  SearchFilterCategory get category => SearchFilterCategory.venues;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  @override
  Future<List<VenueSearchResult>> search({
    required String query,
    required List<VenueSearchResult> catalog,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List<VenueSearchResult>.from(catalog);

    final firestoreMatches = await _searchFirestore(trimmed);
    final matched = <VenueSearchResult>[];
    final seenIds = <String>{};

    for (final venue in catalog) {
      if (seenIds.contains(venue.id)) continue;

      final textMatch = VenueSearchMatcher.matches(venue, trimmed);
      final firestoreMatch = firestoreMatches.contains(venue.id);
      if (!textMatch && !firestoreMatch) continue;

      matched.add(venue);
      seenIds.add(venue.id);
    }

    VenueSearchMatcher.sortByRelevance(matched, trimmed);
    return matched;
  }

  Future<Set<String>> _searchFirestore(String query) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return const {};

    final terms = VenueSearchMatcher.termsFromQuery(query);
    if (terms.isEmpty) return const {};

    try {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .where('searchablePublic', isNotEqualTo: false)
          .where('searchTerms', arrayContainsAny: terms)
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[VenueSearchDataSource] Firestore search failed: $error');
        debugPrint('$stackTrace');
      }
      return const {};
    }
  }

  /// Maps raw Firestore venue docs into search results (used by catalog load).
  static List<VenueSearchResult> mapDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final venues = <VenueSearchResult>[];
    for (final doc in docs) {
      final venue = VenueModel.fromMap(doc.id, doc.data());
      final mapped = SearchVenueMapper.fromVenueModel(venue);
      if (mapped != null) {
        venues.add(mapped);
      }
    }
    venues.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return venues;
  }
}
