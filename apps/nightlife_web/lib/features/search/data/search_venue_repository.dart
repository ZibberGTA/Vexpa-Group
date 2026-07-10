import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_search_result.dart';
import 'search_venue_catalog.dart';
import 'search_venue_mapper.dart';

/// Fetches venues from Firestore with mock preview fallback.
///
/// Firestore is accessed lazily after [VexdaFirebase.initialize] completes so
/// [FirebaseFirestore.instance] is never touched before Firebase is ready.
class SearchVenueRepository {
  SearchVenueRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  Future<SearchVenueCatalog> loadVenues() async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return _fallbackCatalog(reason: 'Firebase not initialized');
    }

    try {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .where('searchablePublic', isNotEqualTo: false)
          .get();

      final venues = <VenueSearchResult>[];
      var skippedWithoutCoordinates = 0;

      for (final doc in snapshot.docs) {
        final venue = VenueModel.fromMap(doc.id, doc.data());
        final mapped = SearchVenueMapper.fromVenueModel(venue);
        if (mapped != null) {
          venues.add(mapped);
        } else {
          skippedWithoutCoordinates++;
        }
      }

      if (venues.isEmpty) {
        return _fallbackCatalog(
          reason: snapshot.docs.isEmpty
              ? 'Firestore returned no venue documents'
              : 'Firestore returned no venues with valid latitude/longitude '
                  '($skippedWithoutCoordinates skipped)',
        );
      }

      venues.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (kDebugMode) {
        final count = venues.length;
        debugPrint(
          '[SearchVenueRepository] Loaded $count Firestore venues '
          '($skippedWithoutCoordinates skipped without coordinates).',
        );
      }

      return SearchVenueCatalog(
        venues: venues,
        usingFallback: false,
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SearchVenueRepository] Firestore load failed: $error');
        debugPrint('$stackTrace');
      }
      return _fallbackCatalog(reason: 'Firestore load failed');
    }
  }

  SearchVenueCatalog _fallbackCatalog({required String reason}) {
    if (kDebugMode) {
      debugPrint('[SearchVenueRepository] Using mock fallback: $reason');
    }
    return SearchVenueCatalog(
      venues: SearchVenueMapper.fallbackVenues(),
      usingFallback: true,
    );
  }
}
