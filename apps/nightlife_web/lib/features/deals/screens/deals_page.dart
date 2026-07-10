import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/components/section_header.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../data/deals_repository.dart';

/// Dedicated deals browse page grouped by venue, drink and city.
class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final DealsRepository _repository = DealsRepository();
  late final Future<List<DealBrowseItem>> _dealsFuture;

  @override
  void initState() {
    super.initState();
    _dealsFuture = _repository.loadActiveDeals();
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicPageHero(
            eyebrow: 'Offers',
            title: AppStrings.dealsTitle,
            subtitle: AppStrings.dealsSubtitle,
          ),
          FutureBuilder<List<DealBrowseItem>>(
            future: _dealsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 420,
                  child: PublicLoadingState(message: 'Loading deals…'),
                );
              }

              final deals = snapshot.data!;
              final byVenue = _groupBy(deals, (item) => item.venueName);
              final byDrink = _groupBy(deals, (item) => item.drinkLabel);
              final byCity = _groupBy(deals, (item) => item.city);

              return ContentContainer(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DealGroupSection(
                        title: 'By venue',
                        subtitle: 'Active offers at venues near you.',
                        groups: byVenue,
                      ),
                      const SectionDivider(),
                      _DealGroupSection(
                        title: 'By drink',
                        subtitle: 'Find the best drink deals tonight.',
                        groups: byDrink,
                      ),
                      const SectionDivider(),
                      _DealGroupSection(
                        title: 'By city',
                        subtitle: 'Browse deals across UK cities.',
                        groups: byCity,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, List<DealBrowseItem>> _groupBy(
    List<DealBrowseItem> deals,
    String Function(DealBrowseItem) keyFor,
  ) {
    final groups = <String, List<DealBrowseItem>>{};
    for (final deal in deals) {
      final key = keyFor(deal);
      groups.putIfAbsent(key, () => []).add(deal);
    }
    return groups;
  }
}

class _DealGroupSection extends StatelessWidget {
  const _DealGroupSection({
    required this.title,
    required this.subtitle,
    required this.groups,
  });

  final String title;
  final String subtitle;
  final Map<String, List<DealBrowseItem>> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.lg),
        ...groups.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: entry.value
                      .map(
                        (item) => _DealCard(
                          item: item,
                          onTap: item.deal.venueId.isNotEmpty &&
                                  !item.deal.venueId.startsWith('preview')
                              ? () => Navigator.pushNamed(
                                    context,
                                    AppRouter.venueDetails(item.deal.venueId),
                                  )
                              : () => Navigator.pushNamed(context, AppRouter.map),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.item, this.onTap});

  final DealBrowseItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.deal.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.venueName,
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.deal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.deal.expiryLabel,
                  style: TextStyle(
                    color: AppColors.trailGold.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
