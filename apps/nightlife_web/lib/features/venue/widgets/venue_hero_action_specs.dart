import 'package:flutter/material.dart';

import '../../../shared/components/drinkspot_button.dart';

/// Identifies a venue hero action for wiring callbacks independently of labels.
enum VenueHeroActionId {
  directions,
  phone,
  saved,
  viewVenue,
  saveVenue,
  share,
  viewOnMap,
}

/// Visual configuration for a hero action button.
class VenueHeroActionSpec {
  const VenueHeroActionSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.variant,
  });

  final VenueHeroActionId id;
  final String label;
  final IconData icon;
  final DrinkSpotButtonVariant variant;
}

/// Approved action configurations for customer and public web hero surfaces.
abstract final class VenueHeroActionConfigs {
  /// Mobile customer-facing hero actions shown in venue management preview.
  static const customerHeroActions = <VenueHeroActionSpec>[
    VenueHeroActionSpec(
      id: VenueHeroActionId.directions,
      label: 'Directions',
      icon: Icons.directions_walk_rounded,
      variant: DrinkSpotButtonVariant.secondary,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.phone,
      label: 'Phone',
      icon: Icons.phone_outlined,
      variant: DrinkSpotButtonVariant.secondary,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.saved,
      label: 'Saved',
      icon: Icons.favorite_border_rounded,
      variant: DrinkSpotButtonVariant.secondary,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.viewVenue,
      label: 'View Venue',
      icon: Icons.storefront_outlined,
      variant: DrinkSpotButtonVariant.primary,
    ),
  ];

  /// Public web venue page hero actions.
  static const publicWebHeroActions = <VenueHeroActionSpec>[
    VenueHeroActionSpec(
      id: VenueHeroActionId.directions,
      label: 'Get directions',
      icon: Icons.directions_outlined,
      variant: DrinkSpotButtonVariant.primary,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.saveVenue,
      label: 'Save venue',
      icon: Icons.bookmark_border_rounded,
      variant: DrinkSpotButtonVariant.secondary,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.share,
      label: 'Share',
      icon: Icons.ios_share_rounded,
      variant: DrinkSpotButtonVariant.ghost,
    ),
    VenueHeroActionSpec(
      id: VenueHeroActionId.viewOnMap,
      label: 'View on map',
      icon: Icons.map_outlined,
      variant: DrinkSpotButtonVariant.ghost,
    ),
  ];
}
