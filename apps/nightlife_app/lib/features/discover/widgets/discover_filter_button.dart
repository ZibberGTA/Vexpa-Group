import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/discover_models.dart';

class DiscoverFilterButton extends StatelessWidget {
  const DiscoverFilterButton({
    super.key,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  static const Key selectedIndicatorKey = Key('discover-filter-selected-dot');

  final DiscoverFilter filter;
  final bool selected;
  final VoidCallback onTap;

  static IconData iconFor(DiscoverFilter filter) {
    switch (filter) {
      case DiscoverFilter.deals:
        return Icons.local_offer_outlined;
      case DiscoverFilter.events:
        return Icons.event_outlined;
      case DiscoverFilter.venues:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          button: true,
          selected: selected,
          label: filter.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.purple.withOpacity(0.38)
                      : AppColors.surface.withOpacity(0.68),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppColors.purpleSoft.withOpacity(0.95)
                        : Colors.white.withOpacity(0.1),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.28),
                            blurRadius: 14,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      key: selected ? selectedIndicatorKey : null,
                      duration: duration,
                      width: selected ? 6 : 0,
                      height: 6,
                      margin: EdgeInsets.only(right: selected ? 6 : 0),
                      decoration: const BoxDecoration(
                        color: AppColors.purpleSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      iconFor(filter),
                      size: 16,
                      color: selected
                          ? AppColors.purpleSoft
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        filter.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: selected ? 0.15 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
