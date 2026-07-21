import 'package:flutter/material.dart';

import '../models/venue_trail_participation_presentation.dart';
import '../services/venue_trail_participation_action_resolver.dart';
import '../widgets/trails/venue_trails_presentation.dart';

/// Maps participation presentation data into venue trails UI models.
abstract final class VenueTrailParticipationPresentationMapper {
  static List<VenueTrailDiscoveryItem> mapEligibleTrails(
    List<VenueTrailEligiblePresentation> eligible,
  ) {
    return [
      for (final item in eligible)
        VenueTrailDiscoveryItem(
          id: item.trail.trailId,
          name: item.trail.name,
          description: item.trail.description,
          status: item.trail.acceptsApplications ? 'Published' : 'Unavailable',
          distance: item.trail.applicationWindowLabel.isEmpty
              ? 'Nearby'
              : item.trail.applicationWindowLabel,
          venueCountLabel: '${item.trail.stopCount} Venues',
          type: 'Trail',
          startInfo: item.trail.applicationWindowLabel.isEmpty
              ? 'Open'
              : item.trail.applicationWindowLabel,
          venueState: _venueState(item.venueState),
          artworkGradient: const [
            Color(0xFF4A1942),
            Color(0xFF8B2252),
            Color(0xFF2D1B3D),
          ],
        ),
    ];
  }

  static List<VenueTrailOpportunityItem> mapOpportunities(
    List<VenueTrailEligiblePresentation> eligible,
  ) {
    return [
      for (final item in eligible)
        VenueTrailOpportunityItem(
          id: item.trail.trailId,
          name: item.trail.name,
          description: item.trail.description,
          criteria: item.blockingReasons.isEmpty
              ? const ['Accepting venue applications']
              : item.blockingReasons,
          venueState: _venueState(item.venueState),
        ),
    ];
  }

  static List<VenueTrailParticipationItem> mapApplications(
    List<VenueTrailParticipationApplicationPresentation> applications,
  ) {
    return [
      for (final application in applications)
        VenueTrailParticipationItem(
          id: application.requestId,
          name: application.trailName,
          status: application.statusLabel,
          positionLabel: application.positionLabel,
          availabilityLabel: application.submittedAt == null
              ? 'Draft'
              : 'Updated ${application.updatedAt.day}/${application.updatedAt.month}',
          actionLabel: application.primaryAction == null
              ? 'View'
              : VenueTrailParticipationActionResolver.label(
                  application.primaryAction!,
                ),
          iconColor: application.statusColor,
        ),
    ];
  }

  static VenueTrailVenueState _venueState(VenueTrailEligibleVenueState state) {
    return switch (state) {
      VenueTrailEligibleVenueState.eligible => VenueTrailVenueState.eligible,
      VenueTrailEligibleVenueState.alreadyIncluded =>
        VenueTrailVenueState.alreadyIncluded,
      VenueTrailEligibleVenueState.notEligible =>
        VenueTrailVenueState.notEligible,
      VenueTrailEligibleVenueState.requestPending =>
        VenueTrailVenueState.requestPending,
    };
  }
}
