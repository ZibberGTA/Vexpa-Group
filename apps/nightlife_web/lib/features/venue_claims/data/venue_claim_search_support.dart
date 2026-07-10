import 'package:vex_engines/claim/shared/claim_search_support.dart';

import '../models/venue_claim.dart';

export 'package:vex_engines/claim/shared/claim_search_support.dart'
    show ClaimSearchSupport;

/// Client-side helpers for venue claim search matching and eligibility.
class VenueClaimSearchSupport {
  VenueClaimSearchSupport._();

  static List<String> tokenize(String query) => ClaimSearchSupport.tokenize(query);

  static bool isClaimableVenue(Map<String, dynamic> data) =>
      ClaimSearchSupport.isClaimableVenue(data);

  static bool matchesQuery(
    VenueClaimSearchResult venue,
    String normalizedQuery,
    List<String> tokens,
  ) =>
      ClaimSearchSupport.matchesQuery(venue, normalizedQuery, tokens);

  static String buildHaystack(VenueClaimSearchResult venue) =>
      ClaimSearchSupport.buildHaystack(venue);

  static List<String> buildSearchKeywords(Map<String, dynamic> data) =>
      ClaimSearchSupport.buildSearchKeywords(data);

  static Map<String, dynamic> searchIndexFields(Map<String, dynamic> data) =>
      ClaimSearchSupport.searchIndexFields(data);
}
