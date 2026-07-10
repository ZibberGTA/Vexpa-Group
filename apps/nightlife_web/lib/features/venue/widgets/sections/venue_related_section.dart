import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/pill_tag.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../search/models/venue_search_result.dart';
import '../../data/venue_related_repository.dart';
import '../../models/venue_details_view.dart';
import '../shared/venue_section_primitives.dart';

/// Discovery section encouraging users to continue exploring Vexda.
class VenueRelatedSection extends StatefulWidget {
  const VenueRelatedSection({
    super.key,
    required this.venue,
    this.repository,
    this.anchorKey,
  });

  final VenueDetailsView venue;
  final VenueRelatedRepository? repository;
  final Key? anchorKey;

  @override
  State<VenueRelatedSection> createState() => _VenueRelatedSectionState();
}

class _VenueRelatedSectionState extends State<VenueRelatedSection> {
  late final Future<VenueRelatedSuggestions> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository ?? VenueRelatedRepository();
    _suggestionsFuture = repository.loadSuggestions(widget.venue);
  }

  @override
  Widget build(BuildContext context) {
    return VenueSectionShell(
      anchorKey: widget.anchorKey,
      title: 'Continue your night',
      subtitle: 'Discover more venues and keep exploring with Vexda.',
      child: FutureBuilder<VenueRelatedSuggestions>(
        future: _suggestionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VenueSectionLoading(lines: 3);
          }

          final suggestions = snapshot.data;
          if (suggestions == null || !suggestions.hasSuggestions) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DiscoveryPrompt(
                  onExplore: () {
                    Navigator.of(context).pushNamed(AppRouter.search);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _RelatedPlaceholderCard(
                  icon: Icons.route_outlined,
                  title: 'Trails including this venue',
                  message:
                      'Published trails that stop at ${widget.venue.name} will appear once trail recommendations are connected.',
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (suggestions.nearbyVenues.isNotEmpty) ...[
                const _Subheading(label: 'Nearby venues'),
                const SizedBox(height: AppSpacing.sm),
                _VenueSuggestionList(venues: suggestions.nearbyVenues),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (suggestions.similarVenues.isNotEmpty) ...[
                const _Subheading(label: 'Similar venues'),
                const SizedBox(height: AppSpacing.sm),
                _VenueSuggestionList(venues: suggestions.similarVenues),
                const SizedBox(height: AppSpacing.lg),
              ],
              _DiscoveryPrompt(
                onExplore: () {
                  Navigator.of(context).pushNamed(AppRouter.search);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _RelatedPlaceholderCard(
                icon: Icons.route_outlined,
                title: 'Trails including this venue',
                message:
                    'Tonight\'s Trails featuring ${widget.venue.name} will surface here in a future release.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryPink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _VenueSuggestionList extends StatelessWidget {
  const _VenueSuggestionList({required this.venues});

  final List<VenueSearchResult> venues;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < venues.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _VenueSuggestionCard(venue: venues[i]),
        ],
      ],
    );
  }
}

class _VenueSuggestionCard extends StatefulWidget {
  const _VenueSuggestionCard({required this.venue});

  final VenueSearchResult venue;

  @override
  State<_VenueSuggestionCard> createState() => _VenueSuggestionCardState();
}

class _VenueSuggestionCardState extends State<_VenueSuggestionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.venueDetails(widget.venue.id),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: GlassContainer(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.venue.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.venue.locationLabel} • ${widget.venue.venueType}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PillTag(
                    label: widget.venue.isOpen ? 'Open' : 'Closed',
                    highlighted: widget.venue.isOpen,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryPrompt extends StatelessWidget {
  const _DiscoveryPrompt({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Explore more on Vexda',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Search the map to discover drinks, deals, events and trails nearby.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            onPressed: onExplore,
            icon: const Icon(Icons.arrow_forward_rounded),
            color: AppColors.primaryPink,
            tooltip: 'Open search',
          ),
        ],
      ),
    );
  }
}

class _RelatedPlaceholderCard extends StatelessWidget {
  const _RelatedPlaceholderCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
