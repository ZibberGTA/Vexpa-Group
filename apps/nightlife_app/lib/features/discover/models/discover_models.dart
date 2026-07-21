enum DiscoverFilter {
  deals,
  events,
  venues;

  static const int discoverQuickResultLimit = 10;

  String get label {
    switch (this) {
      case DiscoverFilter.deals:
        return 'Deals';
      case DiscoverFilter.events:
        return 'Events';
      case DiscoverFilter.venues:
        return 'Venues';
    }
  }

  String get resultsHeaderTitle {
    switch (this) {
      case DiscoverFilter.deals:
        return 'Closest deals';
      case DiscoverFilter.events:
        return 'Closest events';
      case DiscoverFilter.venues:
        return 'Closest venues';
    }
  }

  String get resultsHeaderSubtitle =>
      'Showing up to $discoverQuickResultLimit nearest venues';

  String get emptyMessage {
    switch (this) {
      case DiscoverFilter.deals:
        return 'No active deals were found near you.';
      case DiscoverFilter.events:
        return 'No upcoming events were found near you.';
      case DiscoverFilter.venues:
        return 'No venues were found near your location.';
    }
  }

  static String locationDeniedMessage =
      'Allow location access to see the closest venues.';

  static String locationDisabledMessage =
      'Turn on location services to find venues near you.';

  static String locationUnavailableMessage =
      'We couldn\'t determine your location. Please try again.';
}

enum DiscoverLoadStatus {
  idle,
  loading,
  success,
  empty,
  locationDenied,
  locationDisabled,
  locationUnavailable,
  error,
}

class DiscoverVenueResult {
  const DiscoverVenueResult({
    required this.venueId,
    required this.venueName,
    required this.venueData,
    this.distanceMeters,
    this.rating,
    this.isOpen,
    this.imageUrl,
    this.dealTitle,
    this.dealAvailability,
    this.eventTitle,
    this.eventStart,
    this.eventStatusLabel,
    this.category,
  });

  final String venueId;
  final String venueName;
  final Map<String, dynamic> venueData;
  final double? distanceMeters;
  final double? rating;
  final bool? isOpen;
  final String? imageUrl;
  final String? dealTitle;
  final String? dealAvailability;
  final String? eventTitle;
  final DateTime? eventStart;
  final String? eventStatusLabel;
  final String? category;
}

class DiscoverLoadState {
  const DiscoverLoadState({
    this.status = DiscoverLoadStatus.idle,
    this.results = const [],
    this.errorMessage,
    this.dealVenueIds = const {},
    this.eventVenueIds = const {},
  });

  final DiscoverLoadStatus status;
  final List<DiscoverVenueResult> results;
  final String? errorMessage;
  final Set<String> dealVenueIds;
  final Set<String> eventVenueIds;

  DiscoverLoadState copyWith({
    DiscoverLoadStatus? status,
    List<DiscoverVenueResult>? results,
    String? errorMessage,
    Set<String>? dealVenueIds,
    Set<String>? eventVenueIds,
  }) {
    return DiscoverLoadState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      dealVenueIds: dealVenueIds ?? this.dealVenueIds,
      eventVenueIds: eventVenueIds ?? this.eventVenueIds,
    );
  }
}
