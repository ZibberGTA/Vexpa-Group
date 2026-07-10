/// Mobile-style venue filter rules shared across discovery search flows.
final class DiscoveryVenueFilterRules {
  DiscoveryVenueFilterRules._();

  static bool passesFilters({
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

    final venueCrowd =
        (venueData['crowdLevel'] ?? venueData['currentCrowdLevel'] ?? 'unknown')
            .toString();

    if (crowdLevel != null && crowdLevel != 'All' && venueCrowd != crowdLevel) {
      return false;
    }

    if (busyOnly && venueCrowd != 'busy' && venueCrowd != 'packed') {
      return false;
    }

    return true;
  }

  static bool matchesPriceBand({
    required dynamic price,
    required String priceBand,
  }) {
    if (priceBand == 'All') return true;
    if (price is! num) return true;

    return switch (priceBand) {
      '£' => price < 6,
      '££' => price >= 6 && price < 12,
      '£££' => price >= 12,
      _ => true,
    };
  }
}

/// Sorts grouped mobile search results by total matched entity count.
final class DiscoveryMobileSearchRanking {
  DiscoveryMobileSearchRanking._();

  static void sortByMatchCount(List<Map<String, dynamic>> results) {
    results.sort((a, b) {
      final aCount = _matchCount(a);
      final bCount = _matchCount(b);
      final countDiff = bCount.compareTo(aCount);
      if (countDiff != 0) return countDiff;
      return (a['venueName']?.toString() ?? '').toLowerCase().compareTo(
        (b['venueName']?.toString() ?? '').toLowerCase(),
      );
    });
  }

  static int _matchCount(Map<String, dynamic> result) {
    return ((result['matchedDrinks'] as List?)?.length ?? 0) +
        ((result['matchedDeals'] as List?)?.length ?? 0) +
        ((result['matchedEvents'] as List?)?.length ?? 0);
  }
}

/// Merges matched drinks, deals, and events into grouped mobile search results.
final class DiscoveryMobileSearchMerger {
  DiscoveryMobileSearchMerger._();

  static void upsertMatch({
    required Map<String, Map<String, dynamic>> grouped,
    required Map<String, dynamic> venueData,
    required Map<String, dynamic> Function(Map<String, dynamic> venueData)
    buildShell,
    Map<String, dynamic>? drink,
    Map<String, dynamic>? deal,
    Map<String, dynamic>? event,
  }) {
    final venueId = venueData['id']?.toString() ?? '';
    if (venueId.isEmpty) return;

    final result = grouped.putIfAbsent(venueId, () => buildShell(venueData));

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
}
