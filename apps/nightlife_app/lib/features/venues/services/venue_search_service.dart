import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/application/discovery_venue_client_matcher.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_catalog_entry.dart';

import '../models/venue_filter_model.dart';
import '../models/venue_model.dart';

class VenueSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<VenueModel>> searchVenues(VenueFilterModel filter) async {
    Query<Map<String, dynamic>> query = _firestore.collection('venues');

    if (filter.category != null && filter.category!.isNotEmpty) {
      query = query.where('category', isEqualTo: filter.category);
    }

    if (filter.crowdLevel != null && filter.crowdLevel!.isNotEmpty) {
      query = query.where('crowdLevel', isEqualTo: filter.crowdLevel);
    }

    if (filter.dealsOnly) {
      query = query.where('hasDeals', isEqualTo: true);
    }

    final snapshot = await query.get();

    final venues = snapshot.docs
        .map((doc) => VenueModel.fromMap(doc.id, doc.data()))
        .toList();

    return DiscoveryVenueClientMatcher.filterWithReasons(
      items: venues,
      query: filter.searchText,
      toEntry: _toCatalogEntry,
      withReasons: (venue, reasons) => venue.copyWith(matchReasons: reasons),
    );
  }

  static DiscoveryVenueCatalogEntry _toCatalogEntry(VenueModel venue) {
    return DiscoveryVenueCatalogEntry(
      name: venue.name,
      category: venue.category,
      crowdLevel: venue.crowdLevel,
      address: venue.address ?? '',
      searchTerms: venue.searchTerms,
    );
  }
}
