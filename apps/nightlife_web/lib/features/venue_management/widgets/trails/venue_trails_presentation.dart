import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/venue_profile_completion.dart';

/// Venue-side trail relationship state used for action labelling.
enum VenueTrailVenueState {
  eligible,
  alreadyIncluded,
  notEligible,
  requestAccess,
  requestPending,
}

/// Resolved trail action for a UI control.
final class VenueTrailAction {
  const VenueTrailAction({
    required this.label,
    required this.enabled,
    this.useFilledStyle = false,
  });

  final String label;
  final bool enabled;
  final bool useFilledStyle;
}

/// Maps trail relationship state to a single primary action label.
abstract final class VenueTrailActionResolver {
  static VenueTrailAction discoveryJoinAction(VenueTrailVenueState state) {
    return switch (state) {
      VenueTrailVenueState.alreadyIncluded => const VenueTrailAction(
        label: 'Already Included',
        enabled: false,
      ),
      VenueTrailVenueState.notEligible => const VenueTrailAction(
        label: 'Not Eligible',
        enabled: false,
      ),
      VenueTrailVenueState.eligible => const VenueTrailAction(
        label: 'Join Trail',
        enabled: true,
        useFilledStyle: true,
      ),
      VenueTrailVenueState.requestAccess => const VenueTrailAction(
        label: 'Request Access',
        enabled: true,
        useFilledStyle: true,
      ),
      VenueTrailVenueState.requestPending => const VenueTrailAction(
        label: 'View Request',
        enabled: true,
      ),
    };
  }

  static VenueTrailAction opportunityAction(VenueTrailVenueState state) {
    return switch (state) {
      VenueTrailVenueState.alreadyIncluded => const VenueTrailAction(
        label: 'Already Included',
        enabled: false,
      ),
      VenueTrailVenueState.notEligible => const VenueTrailAction(
        label: 'Not Eligible',
        enabled: false,
      ),
      VenueTrailVenueState.eligible => const VenueTrailAction(
        label: 'Request to Join',
        enabled: true,
      ),
      VenueTrailVenueState.requestAccess => const VenueTrailAction(
        label: 'Request Access',
        enabled: true,
      ),
      VenueTrailVenueState.requestPending => const VenueTrailAction(
        label: 'View Request',
        enabled: true,
      ),
    };
  }

  static String eligibilityStatusLabel(VenueTrailVenueState state) {
    return switch (state) {
      VenueTrailVenueState.eligible => 'Eligible',
      VenueTrailVenueState.alreadyIncluded => 'Already included',
      VenueTrailVenueState.notEligible => 'Not eligible',
      VenueTrailVenueState.requestAccess => 'Request access',
      VenueTrailVenueState.requestPending => 'Request pending',
    };
  }

  static String eligibilityStatusBadge(VenueTrailVenueState state) {
    return switch (state) {
      VenueTrailVenueState.eligible => 'ELIGIBLE',
      VenueTrailVenueState.alreadyIncluded => 'INCLUDED',
      VenueTrailVenueState.notEligible => 'NOT ELIGIBLE',
      VenueTrailVenueState.requestAccess => 'REQUEST ACCESS',
      VenueTrailVenueState.requestPending => 'REQUEST PENDING',
    };
  }
}

final class VenueTrailDiscoveryItem {
  const VenueTrailDiscoveryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.distance,
    required this.venueCountLabel,
    required this.type,
    required this.startInfo,
    required this.venueState,
    required this.artworkGradient,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String distance;
  final String venueCountLabel;
  final String type;
  final String startInfo;
  final VenueTrailVenueState venueState;
  final List<Color> artworkGradient;
}

final class VenueTrailParticipationItem {
  const VenueTrailParticipationItem({
    required this.id,
    required this.name,
    required this.status,
    required this.positionLabel,
    required this.availabilityLabel,
    required this.actionLabel,
    this.iconColor = AppColors.primaryPink,
  });

  final String id;
  final String name;
  final String status;
  final String positionLabel;
  final String availabilityLabel;
  final String actionLabel;
  final Color iconColor;
}

final class VenueTrailOpportunityItem {
  const VenueTrailOpportunityItem({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    required this.venueState,
    this.icon = Icons.groups_outlined,
  });

  final String id;
  final String name;
  final String description;
  final List<String> criteria;
  final VenueTrailVenueState venueState;
  final IconData icon;
}

/// Static presentation data until venue trail repositories are connected.
abstract final class VenueTrailsPresentation {
  static const trailsSubtitle =
      'Join local trails, increase exposure and attract more customers.';

  static bool shouldShowProfileReadinessCallout(
    VenueProfileCompletion completion,
  ) {
    return completion.completedSteps < completion.totalSteps;
  }

  static const discoveryTrails = <VenueTrailDiscoveryItem>[
    VenueTrailDiscoveryItem(
      id: 'manchester-cocktail-trail',
      name: 'Manchester Cocktail Trail',
      description:
          'A curated route through the city\'s best cocktail bars and speakeasies.',
      status: 'Published',
      distance: '0.4 mi away',
      venueCountLabel: '12 Venues',
      type: 'Cocktail Bars',
      startInfo: '28 Jun - 6 Jul',
      venueState: VenueTrailVenueState.alreadyIncluded,
      artworkGradient: [
        Color(0xFF4A1942),
        Color(0xFF8B2252),
        Color(0xFF2D1B3D),
      ],
    ),
    VenueTrailDiscoveryItem(
      id: 'northern-quarter-night-out',
      name: 'Northern Quarter Night Out',
      description:
          'Late-night venues, live DJs and hidden gems across the Northern Quarter.',
      status: 'Scheduled',
      distance: '0.7 mi away',
      venueCountLabel: '8 Venues',
      type: 'Nightlife',
      startInfo: '5 Jul - 12 Jul',
      venueState: VenueTrailVenueState.eligible,
      artworkGradient: [
        Color(0xFF1A1F3C),
        Color(0xFF3D2B6B),
        Color(0xFF162447),
      ],
    ),
    VenueTrailDiscoveryItem(
      id: 'live-music-weekend-route',
      name: 'Live Music Weekend Route',
      description:
          'Weekend stops featuring live bands, acoustic sets and venue showcases.',
      status: 'Draft',
      distance: '1.2 mi away',
      venueCountLabel: '6 Venues',
      type: 'Live Music',
      startInfo: '12 Jul - 14 Jul',
      venueState: VenueTrailVenueState.requestAccess,
      artworkGradient: [
        Color(0xFF3D2010),
        Color(0xFF7A3B1E),
        Color(0xFF2A1520),
      ],
    ),
    VenueTrailDiscoveryItem(
      id: 'late-night-student-trail',
      name: 'Late Night Student Trail',
      description:
          'Budget-friendly student nights with drink deals and early entry perks.',
      status: 'Closed',
      distance: 'Nearby',
      venueCountLabel: '10 Venues',
      type: 'Student Nights',
      startInfo: 'Season ended',
      venueState: VenueTrailVenueState.notEligible,
      artworkGradient: [
        Color(0xFF1E2433),
        Color(0xFF2E3450),
        Color(0xFF141824),
      ],
    ),
  ];

  static const participationTrails = <VenueTrailParticipationItem>[
    VenueTrailParticipationItem(
      id: 'manchester-cocktail-trail',
      name: 'Manchester Cocktail Trail',
      status: 'Published',
      positionLabel: 'Stop 4 of 12',
      availabilityLabel: 'Available now',
      actionLabel: 'Manage',
    ),
    VenueTrailParticipationItem(
      id: 'northern-quarter-night-out',
      name: 'Northern Quarter Night Out',
      status: 'Scheduled',
      positionLabel: 'Awaiting approval',
      availabilityLabel: 'Starts next Friday',
      actionLabel: 'View',
      iconColor: AppColors.primaryPurple,
    ),
  ];

  static const opportunityTrails = <VenueTrailOpportunityItem>[
    VenueTrailOpportunityItem(
      id: 'northern-quarter-night-out',
      name: 'Northern Quarter Night Out',
      description: 'Late-night venue trail with verified locations.',
      criteria: ['Open after 11 PM', 'Verified location', 'Banner uploaded'],
      venueState: VenueTrailVenueState.eligible,
    ),
    VenueTrailOpportunityItem(
      id: 'happy-hour-discovery-route',
      name: 'Happy Hour Discovery Route',
      description: 'Deals-led trail highlighting venues with active offers.',
      criteria: ['Active deal', 'Public profile complete'],
      venueState: VenueTrailVenueState.requestAccess,
      icon: Icons.local_offer_outlined,
    ),
    VenueTrailOpportunityItem(
      id: 'live-music-weekend-route',
      name: 'Live Music Weekend Route',
      description: 'Weekend live music trail with curated venue stops.',
      criteria: ['Live music listing', 'Weekend hours'],
      venueState: VenueTrailVenueState.requestPending,
      icon: Icons.music_note_outlined,
    ),
    VenueTrailOpportunityItem(
      id: 'late-night-student-trail',
      name: 'Late Night Student Trail',
      description: 'Student-focused trail with budget-friendly venues.',
      criteria: ['Student-friendly pricing', 'Late opening hours'],
      venueState: VenueTrailVenueState.notEligible,
    ),
  ];
}
