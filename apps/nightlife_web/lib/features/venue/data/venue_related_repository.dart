import 'package:vex_engines/discovery/application/discovery_related_venue_service.dart';
import 'package:vex_engines/discovery/domain/discovery_related_venue.dart';

import '../../search/data/search_venue_catalog.dart';
import '../../search/data/search_venue_repository.dart';
import '../../search/models/venue_search_result.dart';
import '../models/venue_details_view.dart';

/// Related venue suggestions for the venue details discovery section.
class VenueRelatedRepository {
  VenueRelatedRepository({
    SearchVenueRepository? searchRepository,
    DiscoveryRelatedVenueService? relatedVenueService,
    this._catalogOverride,
  }) : _searchRepository = searchRepository ?? SearchVenueRepository(),
       _relatedVenueService =
           relatedVenueService ?? const DiscoveryRelatedVenueService();

  VenueRelatedRepository.withCatalog(
    this._catalogOverride, {
    DiscoveryRelatedVenueService? relatedVenueService,
  }) : _searchRepository = SearchVenueRepository(),
       _relatedVenueService =
           relatedVenueService ?? const DiscoveryRelatedVenueService();

  final SearchVenueRepository _searchRepository;
  final DiscoveryRelatedVenueService _relatedVenueService;
  final SearchVenueCatalog? _catalogOverride;

  Future<VenueRelatedSuggestions> loadSuggestions(VenueDetailsView venue) async {
    final catalog =
        _catalogOverride ?? await _searchRepository.loadVenues();
    final candidates =
        catalog.venues.where((item) => item.id != venue.id).toList();

    final subject = DiscoveryRelatedVenueSubject(
      id: venue.id,
      category: venue.displayCategory,
      city: venue.city,
      tags: venue.tags,
      latitude: venue.latitude,
      longitude: venue.longitude,
    );

    final similar = _relatedVenueService.rankSimilar(
      subject: subject,
      candidates: candidates,
    );
    final nearby = _relatedVenueService.rankNearby(
      subject: subject,
      candidates: candidates,
    );

    return VenueRelatedSuggestions(
      similarVenues: similar,
      nearbyVenues: nearby,
    );
  }
}

class VenueRelatedSuggestions {
  const VenueRelatedSuggestions({
    required this.similarVenues,
    required this.nearbyVenues,
  });

  final List<VenueSearchResult> similarVenues;
  final List<VenueSearchResult> nearbyVenues;

  bool get hasSuggestions =>
      similarVenues.isNotEmpty || nearbyVenues.isNotEmpty;
}
