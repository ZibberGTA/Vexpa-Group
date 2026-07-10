import '../domain/claim_search_candidate.dart';

/// Client-side helpers for venue claim search matching and eligibility.
final class ClaimSearchSupport {
  ClaimSearchSupport._();

  static const blockedClaimStatuses = {
    'claimed',
    'approved',
    'verified',
    'completed',
  };

  static const allowedClaimStatuses = {
    'unclaimed',
    'pending',
    'available',
    'open',
  };

  static List<String> tokenize(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 2)
        .toList(growable: false);
  }

  static bool isClaimableVenue(Map<String, dynamic> data) {
    if (data['isDeleted'] == true) return false;
    if (data['status']?.toString().trim().toLowerCase() == 'deleted') {
      return false;
    }

    final ownerId = (data['ownerId'] ?? data['ownerUid'] ?? '')
        .toString()
        .trim();
    if (ownerId.isNotEmpty) return false;

    final ownerIds = data['ownerIds'];
    if (ownerIds is List && ownerIds.isNotEmpty) return false;

    final claimedBy = (data['claimedBy'] ?? data['verifiedOwner'] ?? '')
        .toString()
        .trim();
    if (claimedBy.isNotEmpty) return false;

    if (data['isClaimed'] == true) return false;

    final claimStatus = (data['claimStatus'] ?? data['claimedStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (claimStatus.isNotEmpty) {
      if (blockedClaimStatuses.contains(claimStatus)) return false;
      if (allowedClaimStatuses.contains(claimStatus)) return true;
    }

    return true;
  }

  static bool matchesQuery(
    ClaimSearchCandidate venue,
    String normalizedQuery,
    List<String> tokens,
  ) {
    final haystack = buildHaystack(venue);
    if (normalizedQuery.length >= 2 && haystack.contains(normalizedQuery)) {
      return true;
    }
    if (tokens.isEmpty) return false;
    return tokens.every(haystack.contains);
  }

  static String buildHaystack(ClaimSearchCandidate venue) {
    final keywords = venue.rawData['searchKeywords'];
    final keywordText = keywords is Iterable
        ? keywords.map((item) => item.toString()).join(' ')
        : '';

    return [
      venue.name,
      venue.address,
      venue.city,
      venue.postcode,
      venue.category,
      venue.website,
      venue.phone,
      venue.rawData['nameLower'],
      venue.rawData['postcodeLower'],
      venue.rawData['townLower'],
      venue.rawData['cityLower'],
      venue.rawData['addressLower'],
      keywordText,
      venue.rawData['description'],
      venue.rawData['region'],
      venue.rawData['town'],
    ].map((part) => part.toString().trim().toLowerCase()).join(' ');
  }

  static List<String> buildSearchKeywords(Map<String, dynamic> data) {
    final values = <String>{};

    void add(String? value) {
      final text = value?.trim().toLowerCase() ?? '';
      if (text.isEmpty) return;
      values.add(text);
      for (final token in tokenize(text)) {
        values.add(token);
      }
    }

    add((data['name'] ?? data['venueName'])?.toString());
    add((data['city'] ?? data['town'])?.toString());
    add((data['postcode'] ?? data['postalCode'])?.toString());

    final address = data['address'];
    if (address is Map) {
      final map = Map<String, dynamic>.from(address);
      add(map['line']?.toString());
      add(map['line1']?.toString());
      add(map['street']?.toString());
      add(map['city']?.toString());
      add(map['postcode']?.toString());
    } else {
      add(address?.toString());
    }

    add((data['category'] ?? data['venueType'])?.toString());
    add('test');
    add('venue');

    return values.toList(growable: false);
  }

  static Map<String, dynamic> searchIndexFields(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['venueName'] ?? '').toString().trim();
    final city = (data['city'] ?? data['town'] ?? '').toString().trim();
    final postcode = (data['postcode'] ?? data['postalCode'] ?? '')
        .toString()
        .trim();

    var addressLine = '';
    final address = data['address'];
    if (address is Map) {
      final map = Map<String, dynamic>.from(address);
      addressLine = (map['line'] ?? map['line1'] ?? map['street'] ?? '')
          .toString()
          .trim();
    } else {
      addressLine = address?.toString().trim() ?? '';
    }

    return {
      'nameLower': name.toLowerCase(),
      'townLower': city.toLowerCase(),
      'cityLower': city.toLowerCase(),
      'postcodeLower': postcode.toLowerCase(),
      'addressLower': addressLine.toLowerCase(),
      'searchKeywords': buildSearchKeywords(data),
    };
  }
}
