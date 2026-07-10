import 'package:cloud_firestore/cloud_firestore.dart';
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

    final search = _normalize(filter.searchText);

    if (search.isEmpty) {
      return venues;
    }

    final searchVariants = _expandAliases(search);
    final searchParts = _tokenize(search);

    final matched = <VenueModel>[];

    for (final venue in venues) {
      final reasons = _getMatchReasons(venue, searchVariants, searchParts);

      if (reasons.isNotEmpty) {
        matched.add(venue.copyWith(matchReasons: reasons));
      }
    }

    matched.sort((a, b) {
      final aName = _normalize(a.name);
      final bName = _normalize(b.name);

      final aExact = searchVariants.any((variant) => aName == variant) ? 1 : 0;
      final bExact = searchVariants.any((variant) => bName == variant) ? 1 : 0;
      if (aExact != bExact) return bExact.compareTo(aExact);

      final aStarts =
          searchVariants.any((variant) => aName.startsWith(variant)) ? 1 : 0;
      final bStarts =
          searchVariants.any((variant) => bName.startsWith(variant)) ? 1 : 0;
      if (aStarts != bStarts) return bStarts.compareTo(aStarts);

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return matched;
  }

  static List<String> _getMatchReasons(
    VenueModel venue,
    List<String> searchVariants,
    List<String> searchParts,
  ) {
    final reasons = <String>{};

    final venueName = _normalize(venue.name);
    final category = _normalize(venue.category);
    final crowdLevel = _normalize(venue.crowdLevel);
    final address = _normalize(venue.address ?? '');

    if (_matchesAny(venueName, searchVariants)) {
      reasons.add('Venue name');
    }

    if (_matchesAny(category, searchVariants)) {
      reasons.add('Category');
    }

    if (_matchesAny(crowdLevel, searchVariants)) {
      reasons.add('Crowd level');
    }

    if (address.isNotEmpty && _matchesAny(address, searchVariants)) {
      reasons.add('Address');
    }

    for (final term in venue.searchTerms) {
      final normalizedTerm = _normalize(term);

      final exactOrContains = _matchesAny(normalizedTerm, searchVariants);
      final multiWordMatch =
          searchParts.isNotEmpty &&
          searchParts.every((part) => normalizedTerm.contains(part));

      if ((exactOrContains || multiWordMatch) &&
          !_isGenericFieldMatch(term, venue)) {
        reasons.add(term);
      }
    }

    return reasons.take(3).toList();
  }

  static bool _isGenericFieldMatch(String term, VenueModel venue) {
    final normalizedTerm = _normalize(term);

    return normalizedTerm == _normalize(venue.name) ||
        normalizedTerm == _normalize(venue.category) ||
        normalizedTerm == _normalize(venue.crowdLevel) ||
        normalizedTerm == _normalize(venue.address ?? '');
  }

  static bool _matchesAny(String value, List<String> searchVariants) {
    for (final variant in searchVariants) {
      if (value == variant || value.contains(variant)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String input) {
    return input.toLowerCase().trim();
  }

  static List<String> _tokenize(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _expandAliases(String input) {
    final normalized = _normalize(input);
    final variants = <String>{normalized};

    if (normalized == 'whisky') {
      variants.add('whiskey');
    } else if (normalized == 'whiskey') {
      variants.add('whisky');
    }

    return variants.toList();
  }
}