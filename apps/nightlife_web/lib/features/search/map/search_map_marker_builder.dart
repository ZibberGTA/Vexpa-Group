import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/map/map_marker_icon_factory.dart';
import '../../../core/map/vexda_map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/venue_search_result.dart';
import 'search_map_marker_request.dart';

/// Builds Google Maps markers using the same architecture as the mobile map screen.
class SearchMapMarkerBuilder {
  Future<Set<Marker>>? _markersFuture;
  String? _markersFutureKey;

  Future<Set<Marker>> markersFor({
    required List<VenueSearchResult> venues,
    required List<int> visibleVenueIndices,
    required int selectedIndex,
    required ValueChanged<int> onVenueSelected,
  }) {
    final key = _cacheKey(
      venues: venues,
      visibleVenueIndices: visibleVenueIndices,
      selectedIndex: selectedIndex,
    );
    if (_markersFuture != null && _markersFutureKey == key) {
      return _markersFuture!;
    }

    _markersFutureKey = key;
    _markersFuture = _buildMarkers(
      venues: venues,
      requests: _requestsFromVenues(
        venues: venues,
        visibleVenueIndices: visibleVenueIndices,
        selectedIndex: selectedIndex,
      ),
      onVenueSelected: onVenueSelected,
    );
    return _markersFuture!;
  }

  static String _cacheKey({
    required List<VenueSearchResult> venues,
    required List<int> visibleVenueIndices,
    required int selectedIndex,
  }) {
    final imageKey = visibleVenueIndices
        .map((index) {
          final venue = venues[index];
          final logo = venue.logoUrl?.trim() ?? '';
          final banner = venue.bannerImageUrl?.trim() ?? '';
          return '${venue.id}:$logo:$banner';
        })
        .join('|');
    return '${visibleVenueIndices.join(',')}|selected:$selectedIndex|images:$imageKey';
  }

  static List<SearchMapMarkerRequest> _requestsFromVenues({
    required List<VenueSearchResult> venues,
    required List<int> visibleVenueIndices,
    required int selectedIndex,
  }) {
    return visibleVenueIndices.map((index) {
      final venue = venues[index];
      final selected = index == selectedIndex;

      return SearchMapMarkerRequest(
        venueId: venue.id,
        venueName: venue.name,
        position: venue.position,
        sourceIndex: index,
        logoUrl: venue.logoUrl,
        bannerImageUrl: venue.bannerImageUrl,
        selected: selected,
        glow: selected,
        glowColor: selected ? AppColors.primaryPink : null,
      );
    }).toList();
  }

  Future<Set<Marker>> _buildMarkers({
    required List<VenueSearchResult> venues,
    required List<SearchMapMarkerRequest> requests,
    required ValueChanged<int> onVenueSelected,
  }) async {
    final markers = <Marker>{};

    for (final request in requests) {
      final markerImageUrl = _markerImageUrl(request);

      final markerCacheKey =
          '${request.venueId}|$markerImageUrl|glow:${request.glow}|selected:${request.selected}';

      final markerIcon = await MapMarkerIconFactory.descriptorFor(
        cacheKey: markerCacheKey,
        venueId: request.venueId,
        venueName: request.venueName,
        imageUrl: markerImageUrl,
        glow: request.glow,
        glowColor: request.glowColor,
      );

      markers.add(
        Marker(
          markerId: MarkerId(request.venueId),
          position: request.position,
          icon: markerIcon,
          anchor: const Offset(
            VexdaMapConstants.markerAnchorX,
            VexdaMapConstants.markerAnchorY,
          ),
          infoWindow: InfoWindow.noText,
          zIndexInt: request.selected ? 2 : 1,
          onTap: () => onVenueSelected(request.sourceIndex),
        ),
      );
    }

    return markers;
  }

  static String? _markerImageUrl(SearchMapMarkerRequest request) {
    final logo = request.logoUrl?.trim() ?? '';
    if (logo.isNotEmpty) return logo;
    final banner = request.bannerImageUrl?.trim() ?? '';
    return banner.isNotEmpty ? banner : null;
  }
}
