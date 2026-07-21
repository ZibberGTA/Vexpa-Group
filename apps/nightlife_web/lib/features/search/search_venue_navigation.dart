import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import 'models/venue_search_result.dart';

/// Navigation helpers for opening public venue pages from search/map surfaces.
final class SearchVenueNavigation {
  SearchVenueNavigation._();

  /// Uses the Firestore document ID carried on [VenueSearchResult.id].
  static String? canonicalVenueId(VenueSearchResult venue) {
    final documentId = venue.id.trim();
    return documentId.isEmpty ? null : documentId;
  }

  /// Opens `/venue/{documentId}` when the catalog entry has a valid document ID.
  static bool openVenueDetails(BuildContext context, VenueSearchResult venue) {
    final venueId = canonicalVenueId(venue);
    if (venueId == null) return false;

    Navigator.of(context).pushNamed(AppRouter.venueDetails(venueId));
    return true;
  }

  /// Updates map/list selection, then opens the public venue details route.
  static bool selectAndOpen({
    required BuildContext context,
    required List<VenueSearchResult> venues,
    required int index,
    required ValueChanged<int> onSelected,
  }) {
    if (index < 0 || index >= venues.length) return false;

    onSelected(index);
    return openVenueDetails(context, venues[index]);
  }
}
