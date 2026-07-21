import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vex_engines/experience/application/experience_drink_grouper.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../models/deal_model.dart';
import '../models/drink_model.dart';
import '../models/event_model.dart';
import '../models/venue_model.dart';
import '../services/deal_service.dart';
import '../services/drink_service.dart';
import '../services/event_service.dart';
import '../../analytics/services/analytics_service.dart';

class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({
    super.key,
    required this.venue,
  });

  final VenueModel venue;

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logVenueView(widget.venue.id);
    DealService.deactivateExpiredDealsForVenue(widget.venue.id);
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: PremiumBackground(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 310,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.background,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                    title: Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    background: _VenueHeroImage(venue: venue),
                  ),
                ),
                SliverToBoxAdapter(child: _VenueHeroCard(venue: venue)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    const TabBar(
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primaryPink,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Drinks'),
                        Tab(text: 'Deals'),
                        Tab(text: 'Events'),
                        Tab(text: 'Info'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _DrinksTab(venue: venue),
                _DealsTab(venue: venue),
                _EventsTab(venue: venue),
                _InfoTab(venue: venue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueHeroImage extends StatelessWidget {
  const _VenueHeroImage({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    final imageUrl = venue.bannerImageUrl.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _HeaderPlaceholder(venueName: venue.name),
          )
        else
          _HeaderPlaceholder(venueName: venue.name),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.12),
                Colors.black.withOpacity(0.35),
                AppColors.background.withOpacity(0.98),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VenueHeroCard extends StatelessWidget {
  const _VenueHeroCard({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    final heroTags = VenueProfileFieldCodec.displayFeatureTags(
      featureTags: venue.featureTags,
      features: const [],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: _PremiumListCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _VenueLogo(venueName: venue.name, logoUrl: venue.logoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (venue.category.trim().isNotEmpty) venue.category.trim(),
                          if (venue.address.trim().isNotEmpty) venue.address.trim(),
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (venue.description.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                venue.description.trim(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in heroTags)
                  _Pill(icon: Icons.label_outline_rounded, label: tag),
                _CrowdPill(level: venue.crowdLevel),
                if (venue.hasDeals)
                  const _Pill(icon: Icons.local_offer, label: 'Deals'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueLogo extends StatelessWidget {
  const _VenueLogo({required this.venueName, required this.logoUrl});

  final String venueName;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final firstLetter = venueName.trim().isNotEmpty ? venueName.trim()[0].toUpperCase() : '?';

    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.trim().isNotEmpty
            ? Container(
                color: AppColors.background,
                child: Image.network(
                  logoUrl.trim(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _LogoFallback(letter: firstLetter),
                ),
              )
            : _LogoFallback(letter: firstLetter),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DrinksTab extends StatefulWidget {
  const _DrinksTab({required this.venue});

  final VenueModel venue;

  @override
  State<_DrinksTab> createState() => _DrinksTabState();
}

class _DrinksTabState extends State<_DrinksTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _focusedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normaliseCategory(String rawCategory) =>
      ExperienceDrinkGrouper.normaliseCategory(rawCategory);

  Map<String, List<DrinkModel>> _groupDrinks(List<DrinkModel> drinks) =>
      ExperienceDrinkGrouper.groupByCategory(
        drinks,
        category: (drink) => drink.category,
        name: (drink) => drink.name,
        available: (drink) => drink.available,
      );

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cocktail') || lower.contains('mocktail')) return Icons.local_bar;
    if (lower.contains('beer') || lower.contains('lager') || lower.contains('ale')) return Icons.sports_bar;
    if (lower.contains('wine') || lower.contains('sparkling') || lower.contains('champagne')) return Icons.wine_bar;
    if (lower.contains('spirit') || lower.contains('whisky') || lower.contains('vodka') || lower.contains('gin') || lower.contains('rum') || lower.contains('tequila')) return Icons.liquor;
    if (lower.contains('soft')) return Icons.local_drink;
    return Icons.local_bar;
  }

  List<DrinkModel> _filterDrinks(List<DrinkModel> drinks) =>
      ExperienceDrinkGrouper.filterDrinks(
        drinks: drinks,
        query: _query,
        category: (drink) => drink.category,
        name: (drink) => drink.name,
        description: (drink) => drink.description,
        focusedCategory: _focusedCategory,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DrinkModel>>(
      stream: DrinkService.getDrinksForVenue(widget.venue.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _InlineError(message: 'Error loading drinks:\n${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const _VenueSkeletonList();

        final drinks = snapshot.data ?? [];
        if (drinks.isEmpty) {
          return const _EmptyState(
            icon: Icons.local_bar,
            title: 'No drinks yet',
            message: 'This venue has not added drinks yet.',
          );
        }

        final allGroupedDrinks = _groupDrinks(drinks);
        final filteredDrinks = _filterDrinks(drinks);
        final groupedDrinks = _groupDrinks(filteredDrinks);
        final trendingDrinks = ExperienceDrinkGrouper.trendingDrinks(
          drinks,
          available: (drink) => drink.available,
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PremiumDrinkSearch(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                    if (trendingDrinks.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _TrendingDrinksStrip(
                        drinks: trendingDrinks,
                        onDrinkTap: (drink) => AnalyticsService.logDrinkView(
                          venueId: widget.venue.id,
                          drinkId: drink.id,
                          drinkName: drink.name,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '${filteredDrinks.length} drinks across ${groupedDrinks.length} categories',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryPillHeaderDelegate(
                child: _StickyCategoryPills(
                  categories: allGroupedDrinks.keys.toList(),
                  selectedCategory: _focusedCategory,
                  onSelected: (category) {
                    setState(() {
                      _focusedCategory = _focusedCategory == category ? null : category;
                    });
                  },
                ),
              ),
            ),
            if (groupedDrinks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(icon: Icons.search_off, title: 'No matching drinks', message: 'Try a different drink name or category.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    groupedDrinks.entries.map((entry) {
                      return _DrinkCategorySection(
                        title: entry.key,
                        count: entry.value.length,
                        icon: _categoryIcon(entry.key),
                        initiallyExpanded: _focusedCategory == entry.key || _query.trim().isNotEmpty,
                        children: entry.value.map((drink) {
                          return _DrinkMenuItem(
                            name: drink.name,
                            description: drink.description,
                            available: drink.available,
                            priceText: drink.formattedPrice,
                            onTap: () => AnalyticsService.logDrinkView(
                              venueId: widget.venue.id,
                              drinkId: drink.id,
                              drinkName: drink.name,
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DrinkCategorySection extends StatefulWidget {
  const _DrinkCategorySection({required this.title, required this.count, required this.icon, required this.children, this.initiallyExpanded = false});

  final String title;
  final int count;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_DrinkCategorySection> createState() => _DrinkCategorySectionState();
}

class _DrinkCategorySectionState extends State<_DrinkCategorySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _DrinkCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded && widget.initiallyExpanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumListCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryPurple.withOpacity(0.95), AppColors.primaryPink.withOpacity(0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.55)),
                    ),
                    child: Text('${widget.count}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 26),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(padding: const EdgeInsets.only(top: 10), child: Column(children: widget.children)),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}


class _PremiumDrinkSearch extends StatelessWidget {
  const _PremiumDrinkSearch({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Search drinks in this venue...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
          suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: onClear),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class _TrendingDrinksStrip extends StatelessWidget {
  const _TrendingDrinksStrip({required this.drinks, required this.onDrinkTap});

  final List<DrinkModel> drinks;
  final ValueChanged<DrinkModel> onDrinkTap;

  @override
  Widget build(BuildContext context) {
    return _PremiumListCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: AppColors.primaryPink, size: 19),
              SizedBox(width: 7),
              Text('Trending drinks', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: drinks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final drink = drinks[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onDrinkTap(drink),
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [AppColors.primaryPurple.withOpacity(0.28), AppColors.primaryPink.withOpacity(0.14), AppColors.surface.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.38)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(drink.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(drink.formattedPrice, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCategoryPills extends StatelessWidget {
  const _StickyCategoryPills({required this.categories, required this.selectedCategory, required this.onSelected});

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.96),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          return ChoiceChip(
            selected: selected,
            label: Text(category),
            onSelected: (_) => onSelected(category),
            selectedColor: AppColors.primaryPurple.withOpacity(0.30),
            backgroundColor: AppColors.card.withOpacity(0.94),
            side: BorderSide(color: selected ? AppColors.primaryPink : AppColors.primaryPurple.withOpacity(0.65), width: 1.2),
            labelStyle: TextStyle(color: selected ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }
}

class _CategoryPillHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryPillHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _CategoryPillHeaderDelegate oldDelegate) => false;
}

class _DrinkMenuItem extends StatelessWidget {
  const _DrinkMenuItem({required this.name, required this.description, required this.available, required this.priceText, required this.onTap});

  final String name;
  final String description;
  final bool available;
  final String priceText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: available ? AppColors.primaryPurple.withOpacity(0.22) : AppColors.muted.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: available ? AppColors.success : AppColors.muted,
                boxShadow: available ? [BoxShadow(color: AppColors.success.withOpacity(0.35), blurRadius: 8)] : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: available ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 15.5, fontWeight: FontWeight.w800)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3)),
                  ],
                  if (!available) ...[
                    const SizedBox(height: 6),
                    const Text('Currently unavailable', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(priceText, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DealModel>>(
      stream: DealService.getDealsForVenue(venue.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _InlineError(message: 'Error loading deals:\n${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const _VenueSkeletonList();

        final deals = snapshot.data ?? [];
        if (deals.isEmpty) {
          return const _EmptyState(icon: Icons.local_offer, title: 'No active deals', message: 'Current deals will appear here.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            return _PremiumListCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.16),
                  child: const Icon(Icons.local_offer, color: AppColors.primaryPurple),
                ),
                title: Text(deal.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text([
                    if (deal.description.isNotEmpty) deal.description,
                    if (deal.startTime.isNotEmpty || deal.endTime.isNotEmpty) '${deal.startTime} - ${deal.endTime}',
                  ].join(' • ')),
                ),
                onTap: () => AnalyticsService.logDealView(venueId: venue.id, dealId: deal.id, dealTitle: deal.title),
              ),
            );
          },
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.venue});

  final VenueModel venue;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getEventsForVenue(venue.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _InlineError(message: 'Error loading events:\n${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const _VenueSkeletonList();

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const _EmptyState(icon: Icons.event, title: 'No upcoming events yet', message: 'Upcoming events will appear here.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final day = event.startDateTime.day.toString().padLeft(2, '0');
            final month = event.startDateTime.month.toString().padLeft(2, '0');
            final time = '${_formatTime(event.startDateTime)} - ${_formatTime(event.endDateTime)}';

            return InkWell(
              onTap: () => AnalyticsService.logEventView(venueId: venue.id, eventId: event.id, eventTitle: event.title),
              child: _PremiumListCard(
                margin: const EdgeInsets.only(bottom: 14),
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.imageUrl.isNotEmpty)
                      Image.network(event.imageUrl, height: 170, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 58,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              children: [
                                Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text(month, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('${event.category} • $time', style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(event.description, style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


String _normaliseWebsiteUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  return 'https://$trimmed';
}

String _formatWebsiteUrl(String value) {
  return value
      .trim()
      .replaceFirst('https://', '')
      .replaceFirst('http://', '')
      .replaceAll(RegExp(r'/$'), '');
}

Future<void> _openWebsite(BuildContext context, String value) async {
  final normalised = _normaliseWebsiteUrl(value);

  if (normalised.isEmpty) return;

  final uri = Uri.tryParse(normalised);

  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Website link is not valid.')),
    );
    return;
  }

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open website.')),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PremiumListCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoRow(icon: Icons.store, title: 'Name', value: venue.name),
              _InfoRow(icon: Icons.category, title: 'Type', value: venue.category),

          if (venue.websiteUrl.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.language_rounded,
              title: 'Website',
              value: _formatWebsiteUrl(venue.websiteUrl),
              onTap: () => _openWebsite(context, venue.websiteUrl),
            ),

              _InfoRow(icon: Icons.location_on, title: 'Address', value: venue.address),
              _InfoRow(icon: Icons.groups, title: 'Crowd', value: venue.crowdLevel),
              if (venue.description.trim().isNotEmpty) _InfoRow(icon: Icons.info_outline, title: 'About', value: venue.description),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder({required this.venueName});

  final String venueName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepPurpleBackground,
      child: Center(
        child: Text(
          venueName.isNotEmpty ? venueName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryPurple),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CrowdPill extends StatelessWidget {
  const _CrowdPill({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final cleanLevel = level.toLowerCase();
    final color = switch (cleanLevel) {
      'quiet' => Colors.green,
      'steady' => Colors.lightGreen,
      'medium' => Colors.orange,
      'busy' => Colors.deepOrange,
      'packed' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups, size: 18, color: color),
          const SizedBox(width: 6),
          Text(cleanLevel.isEmpty ? 'UNKNOWN' : cleanLevel.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.94),
        border: Border(
          top: BorderSide(color: AppColors.primaryPurple.withOpacity(0.18)),
          bottom: BorderSide(color: AppColors.primaryPurple.withOpacity(0.28)),
        ),
        boxShadow: [
          if (overlapsContent) BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.value, this.onTap});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            SizedBox(width: 82, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: onTap == null ? AppColors.textSecondary : AppColors.primaryPink,
                  fontWeight: onTap == null ? FontWeight.normal : FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _PremiumListCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.primaryPurple),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}


class _VenueSkeletonList extends StatefulWidget {
  const _VenueSkeletonList();

  @override
  State<_VenueSkeletonList> createState() => _VenueSkeletonListState();
}

class _VenueSkeletonListState extends State<_VenueSkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.35);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: index == 0 ? 92 : 72,
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(opacity),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.16)),
            ),
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _PremiumListCard extends StatelessWidget {
  const _PremiumListCard({required this.child, this.margin, this.padding = EdgeInsets.zero, this.clipBehavior = Clip.none});

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: padding,
        child: Theme(
          data: Theme.of(context).copyWith(
            listTileTheme: const ListTileThemeData(
              textColor: AppColors.textPrimary,
              iconColor: AppColors.primaryPurple,
              subtitleTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
