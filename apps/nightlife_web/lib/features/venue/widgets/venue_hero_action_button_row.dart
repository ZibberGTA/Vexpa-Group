import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import 'venue_hero_action_specs.dart';

/// Shared hero action button row — appearance only, callbacks supplied separately.
class VenueHeroActionButtonRow extends StatelessWidget {
  const VenueHeroActionButtonRow({
    super.key,
    required this.actions,
    this.onAction,
    this.previewOnly = false,
  });

  final List<VenueHeroActionSpec> actions;
  final ValueChanged<VenueHeroActionId>? onAction;
  final bool previewOnly;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    final row = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in actions)
          DrinkSpotButton(
            label: action.label,
            icon: action.icon,
            variant: action.variant,
            compact: isMobile,
            onPressed: previewOnly
                ? () {}
                : onAction == null
                ? null
                : () => onAction!(action.id),
          ),
      ],
    );

    if (previewOnly) {
      return AbsorbPointer(child: row);
    }

    return row;
  }
}
