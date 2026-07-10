import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../data/models/drink_model.dart';
import '../../data/venue_drinks_grouper.dart';
import '../../data/venue_drinks_repository.dart';
import '../shared/venue_section_primitives.dart';

/// Venue drinks section with search, categories and expandable groups.
class VenueDrinksSection extends StatefulWidget {
  const VenueDrinksSection({
    super.key,
    required this.venueId,
    this.repository,
    this.anchorKey,
  });

  final String venueId;
  final VenueDrinksRepository? repository;
  final Key? anchorKey;

  @override
  State<VenueDrinksSection> createState() => _VenueDrinksSectionState();
}

class _VenueDrinksSectionState extends State<VenueDrinksSection> {
  late final VenueDrinksRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _focusedCategory;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? VenueDrinksRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VenueSectionShell(
      anchorKey: widget.anchorKey,
      title: 'Drinks',
      subtitle: 'Browse the menu, search favourites and discover tonight\'s pours.',
      child: StreamBuilder<List<DrinkModel>>(
        stream: _repository.watchDrinks(widget.venueId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return VenueEmptyState(
              icon: Icons.local_bar,
              title: 'Drinks unavailable',
              message: 'We could not load drinks for this venue right now.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VenueSectionLoading(lines: 4);
          }

          final drinks = snapshot.data ?? [];
          if (drinks.isEmpty) {
            return const VenueEmptyState(
              icon: Icons.local_bar,
              title: 'No drinks yet',
              message: 'This venue has not added drinks yet.',
            );
          }

          final filtered = VenueDrinksGrouper.filterDrinks(
            drinks: drinks,
            query: _query,
            focusedCategory: _focusedCategory,
          );
          final grouped = VenueDrinksGrouper.groupByCategory(filtered);
          final trending = VenueDrinksGrouper.trendingDrinks(drinks);
          final categories = VenueDrinksGrouper.groupByCategory(drinks).keys.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search drinks',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated.withValues(alpha: 0.65),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              if (trending.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Trending tonight',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: trending.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final drink = trending[index];
                      return _TrendingDrinkCard(drink: drink);
                    },
                  ),
                ),
              ],
              if (categories.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _focusedCategory == null,
                      onTap: () => setState(() => _focusedCategory = null),
                    ),
                    for (final category in categories)
                      _CategoryChip(
                        label: category,
                        selected: _focusedCategory == category,
                        onTap: () => setState(() => _focusedCategory = category),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (grouped.isEmpty)
                const VenueEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching drinks',
                  message: 'Try another search term or category.',
                )
              else
                Column(
                  children: grouped.entries.map((entry) {
                    final expanded = _expandedCategories[entry.key] ?? true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GlassContainer(
                        borderRadius: AppSpacing.radiusMd,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => setState(
                                () => _expandedCategories[entry.key] = !expanded,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value.length}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Icon(
                                      expanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (expanded)
                              Column(
                                children: [
                                  for (final drink in entry.value)
                                    _DrinkRow(drink: drink),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primaryPurple.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrendingDrinkCard extends StatelessWidget {
  const _TrendingDrinkCard({required this.drink});

  final DrinkModel drink;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drink.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              drink.formattedPrice.isNotEmpty ? drink.formattedPrice : 'Featured',
              style: const TextStyle(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkRow extends StatelessWidget {
  const _DrinkRow({required this.drink});

  final DrinkModel drink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drink.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (drink.description.isNotEmpty)
                  Text(
                    drink.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (drink.formattedPrice.isNotEmpty)
            Text(
              drink.formattedPrice,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            drink.available ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: drink.available ? AppColors.primaryPink : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
