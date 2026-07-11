import 'package:flutter/material.dart';
import 'package:vex_engines/discovery/application/discovery_search_result_rules.dart';
import 'package:vex_engines/discovery/shared/discovery_map_geometry.dart';

import '../../../core/theme/app_colors.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_search_result.dart';
import 'search_preview_data.dart';
import 'search_venue_open_status.dart';

/// Maps Firestore venue documents to search UI models.
class SearchVenueMapper {
  SearchVenueMapper._();

  static const _gradientPresets = <List<Color>>[
    [Color(0xFF3D1054), Color(0xFFFF2D95)],
    [Color(0xFF1A0B2E), Color(0xFF9D28FF)],
    [Color(0xFF2A1538), AppColors.primaryPink],
    [Color(0xFF1E1030), Color(0xFF9D28FF)],
    [Color(0xFF2A1538), Color(0xFFD4AF37)],
    [Color(0xFF251838), AppColors.primaryPurple],
  ];

  /// Preview mapping for venue profile dashboard cards (coordinates optional).
  static VenueSearchResult previewFromVenueModel(VenueModel venue) {
    final latitude = venue.latitude ?? venue.location?.latitude ?? 0;
    final longitude = venue.longitude ?? venue.location?.longitude ?? 0;
    final gradients = _gradientsFor(venue.id);
    final tags = DiscoverySearchResultRules.resolveTags(
      featureTags: venue.featureTags,
      venueType: venue.venueType.isNotEmpty ? venue.venueType : venue.category,
      category: venue.category,
    );
    final openStatus = SearchVenueOpenStatus.fromOpeningHours(
      venue.openingHours,
    );
    final bannerUrl = venue.bannerImageUrl.trim();
    final logoUrl = venue.logoUrl.trim();

    return VenueSearchResult(
      id: venue.id,
      name: venue.name,
      area: venue.area,
      city: venue.city,
      postcode: venue.postcode,
      venueType: venue.venueType.isNotEmpty ? venue.venueType : venue.category,
      rating: DiscoverySearchResultRules.resolveRating(venue.averageRating),
      tags: tags,
      bannerGradient: gradients,
      logoGradient: gradients,
      resultReason: DiscoverySearchResultRules.resultReasonFor(
        hasDeals: venue.hasDeals,
        featureTags: venue.featureTags,
        venueType: venue.venueType,
        category: venue.category,
      ),
      isOpen: openStatus.isOpen,
      latitude: latitude,
      longitude: longitude,
      bannerImageUrl: bannerUrl.isNotEmpty ? bannerUrl : null,
      logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
      bannerImagePosition: venue.bannerImagePosition,
      logoImagePosition: venue.logoImagePosition,
    );
  }

  /// Returns null when the venue has no valid coordinates for the map.
  static VenueSearchResult? fromVenueModel(VenueModel venue) {
    final latitude = venue.latitude ?? venue.location?.latitude;
    final longitude = venue.longitude ?? venue.location?.longitude;
    if (!DiscoveryMapGeometry.isValidCoordinate(latitude, longitude)) {
      return null;
    }

    final gradients = _gradientsFor(venue.id);
    final tags = DiscoverySearchResultRules.resolveTags(
      featureTags: venue.featureTags,
      venueType: venue.venueType.isNotEmpty ? venue.venueType : venue.category,
      category: venue.category,
    );
    final openStatus = SearchVenueOpenStatus.fromOpeningHours(
      venue.openingHours,
    );
    final bannerUrl = venue.bannerImageUrl.trim();
    final logoUrl = venue.logoUrl.trim();
    final resolvedLogoUrl = logoUrl.isNotEmpty ? logoUrl : null;

    return VenueSearchResult(
      id: venue.id,
      name: venue.name,
      area: venue.area,
      city: venue.city,
      postcode: venue.postcode,
      venueType: venue.venueType.isNotEmpty ? venue.venueType : venue.category,
      rating: DiscoverySearchResultRules.resolveRating(venue.averageRating),
      tags: tags,
      bannerGradient: gradients,
      logoGradient: gradients,
      resultReason: DiscoverySearchResultRules.resultReasonFor(
        hasDeals: venue.hasDeals,
        featureTags: venue.featureTags,
        venueType: venue.venueType,
        category: venue.category,
      ),
      isOpen: openStatus.isOpen,
      latitude: latitude!,
      longitude: longitude!,
      bannerImageUrl: bannerUrl.isNotEmpty ? bannerUrl : null,
      logoUrl: resolvedLogoUrl,
      bannerImagePosition: venue.bannerImagePosition,
      logoImagePosition: venue.logoImagePosition,
    );
  }

  static List<VenueSearchResult> fallbackVenues() => SearchPreviewData.venues;

  static List<Color> _gradientsFor(String venueId) {
    final index = venueId.hashCode.abs() % _gradientPresets.length;
    return _gradientPresets[index];
  }
}
