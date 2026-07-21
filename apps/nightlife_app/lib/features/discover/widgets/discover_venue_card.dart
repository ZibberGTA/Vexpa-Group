import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/distance_formatter.dart';
import '../models/discover_models.dart';

class DiscoverVenueCard extends StatelessWidget {
  const DiscoverVenueCard({
    super.key,
    required this.result,
    required this.filter,
    required this.selected,
    required this.onTap,
    required this.onFavouriteTap,
    this.cardWidth = 176,
    this.isFavourite = false,
  });

  static const Key cardKey = Key('discover-venue-card');

  static double cardWidthForViewport(double viewportWidth) {
    return (viewportWidth * 0.44).clamp(168.0, 176.0);
  }

  final DiscoverVenueResult result;
  final DiscoverFilter filter;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;
  final double cardWidth;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = result.distanceMeters == null
        ? null
        : DistanceFormatter.formatMeters(result.distanceMeters!);

    return Semantics(
      button: true,
      label: result.venueName,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: cardWidth,
          height: cardWidth * 1.19,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.purpleSoft.withOpacity(0.9)
                  : Colors.white.withOpacity(0.08),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? 0.34 : 0.22),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 118,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(21),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if ((result.imageUrl ?? '').isNotEmpty)
                        Image.network(
                          result.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withOpacity(0.42),
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onFavouriteTap,
                            icon: Icon(
                              isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavourite
                                  ? AppColors.pink
                                  : AppColors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _contextLine(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.purpleSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (distanceLabel != null || result.isOpen != null) ...[
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (distanceLabel != null)
                              _chip(Icons.place_outlined, distanceLabel),
                            if (result.isOpen != null)
                              _chip(
                                Icons.schedule,
                                result.isOpen! ? 'Open' : 'Closed',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contextLine() {
    switch (filter) {
      case DiscoverFilter.deals:
        return [
          if ((result.dealTitle ?? '').isNotEmpty) result.dealTitle,
          if ((result.dealAvailability ?? '').isNotEmpty)
            result.dealAvailability,
        ].whereType<String>().join(' • ');
      case DiscoverFilter.events:
        return [
          if ((result.eventTitle ?? '').isNotEmpty) result.eventTitle,
          if ((result.eventStatusLabel ?? '').isNotEmpty)
            result.eventStatusLabel,
        ].whereType<String>().join(' • ');
      case DiscoverFilter.venues:
        return [
          if ((result.category ?? '').isNotEmpty) result.category,
          if (result.isOpen != null) result.isOpen! ? 'Open now' : 'Closed now',
        ].whereType<String>().join(' • ');
    }
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront_outlined, color: AppColors.muted),
    );
  }
}
