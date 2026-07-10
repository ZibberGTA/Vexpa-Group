import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/premium_scaffold.dart';
import '../../../core/theme/app_colors.dart';

import '../../venues/screens/venue_details_screen.dart';
import '../services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  static const int _minimumQueryLength = 2;
  static const int _initialVisibleResults = 10;
  static const int _resultsIncrement = 10;

  int _visibleResultLimit = _initialVisibleResults;
  bool _hasSearched = false;

  String selectedCategory = 'All';
  String selectedCrowdLevel = 'All';
  String selectedQuickFilter = 'All';
  String selectedPrice = 'All';
  String selectedVenueType = 'All';
  String selectedWhen = 'Any time';

  bool isLoading = false;
  List<Map<String, dynamic>> results = [];

  final categories = const [
    'All',
    'beer',
    'cocktail',
    'wine',
    'spirit',
    'shot',
    'mocktail',
    'soft_drink',
  ];

  final crowdLevels = const [
    'All',
    'quiet',
    'steady',
    'medium',
    'busy',
    'packed',
  ];

  final quickFilters = const [
    'All',
    'Drinks',
    'Events',
    'Deals',
    'Busy now',
  ];

  Future<void> _runSearch({bool resetVisibleLimit = true}) async {
    final query = _searchController.text.trim();

    if (query.length < _minimumQueryLength) {
      _searchDebounce?.cancel();
      if (!mounted) return;
      setState(() {
        results = [];
        isLoading = false;
        _hasSearched = false;
        _visibleResultLimit = _initialVisibleResults;
      });
      return;
    }

    setState(() {
      isLoading = true;
      _hasSearched = true;
      if (resetVisibleLimit) {
        _visibleResultLimit = _initialVisibleResults;
      }
    });

    final data = await SearchService.searchVenueResults(
      query: query,
      category: selectedCategory,
      crowdLevel: selectedCrowdLevel,
      quickFilter: selectedQuickFilter == 'Busy now' ? 'All' : selectedQuickFilter,
      busyOnly: selectedQuickFilter == 'Busy now',
      venueType: selectedVenueType,
      priceBand: selectedPrice,
      resultLimit: 40,
    );

    if (!mounted) return;

    setState(() {
      results = data;
      isLoading = false;
    });
  }

  void _queueSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _runSearch();
    });
  }

  void _loadMoreResults() {
    setState(() {
      _visibleResultLimit += _resultsIncrement;
    });
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '';

    if (rawPrice is num) {
      return rawPrice.toStringAsFixed(2);
    }

    return rawPrice.toString();
  }

  void _openAdvancedFilters() {
    var tempCategory = selectedCategory;
    var tempCrowd = selectedCrowdLevel;
    var tempPrice = selectedPrice;
    var tempVenueType = selectedVenueType;
    var tempWhen = selectedWhen;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget dropdown({
              required String label,
              required String value,
              required List<String> items,
              required ValueChanged<String> onChanged,
            }) {
              return DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() => onChanged(value));
                },
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Refine by drink, venue, price, time and crowd.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    dropdown(
                      label: 'Drink type',
                      value: tempCategory,
                      items: categories,
                      onChanged: (value) => tempCategory = value,
                    ),
                    const SizedBox(height: 12),
                    dropdown(
                      label: 'Crowd vibe',
                      value: tempCrowd,
                      items: crowdLevels,
                      onChanged: (value) => tempCrowd = value,
                    ),
                    const SizedBox(height: 12),
                    dropdown(
                      label: 'Price',
                      value: tempPrice,
                      items: const ['All', '£', '££', '£££'],
                      onChanged: (value) => tempPrice = value,
                    ),
                    const SizedBox(height: 12),
                    dropdown(
                      label: 'Venue type',
                      value: tempVenueType,
                      items: const ['All', 'bar', 'pub', 'club', 'restaurant'],
                      onChanged: (value) => tempVenueType = value,
                    ),
                    const SizedBox(height: 12),
                    dropdown(
                      label: 'When',
                      value: tempWhen,
                      items: const ['Any time', 'Now', 'Tonight', 'Weekend'],
                      onChanged: (value) => tempWhen = value,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = 'All';
                                selectedCrowdLevel = 'All';
                                selectedPrice = 'All';
                                selectedVenueType = 'All';
                                selectedWhen = 'Any time';
                              });
                              Navigator.pop(context);
                              _runSearch();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = tempCategory;
                                selectedCrowdLevel = tempCrowd;
                                selectedPrice = tempPrice;
                                selectedVenueType = tempVenueType;
                                selectedWhen = tempWhen;
                              });
                              Navigator.pop(context);
                              _runSearch();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openAdvancedFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drinks, venues, deals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _runSearch,
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onChanged: (_) => _queueSearch(),
              onSubmitted: (_) => _runSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickFilters.map((filter) {
                final selected = selectedQuickFilter == filter;

                return ChoiceChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    filter,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: selected,
                  avatar: Icon(
                    switch (filter) {
                      'Events' => Icons.event_available_outlined,
                      'Deals' => Icons.local_offer_outlined,
                      'Busy now' => Icons.local_fire_department_outlined,
                      'Drinks' => Icons.local_bar_outlined,
                      _ => Icons.auto_awesome_outlined,
                    },
                    size: 16,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedQuickFilter = filter;
                    });
                    _runSearch();
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (selectedCategory != 'All') _ActiveFilter(label: selectedCategory),
                if (selectedCrowdLevel != 'All') _ActiveFilter(label: selectedCrowdLevel),
                if (selectedPrice != 'All') _ActiveFilter(label: selectedPrice),
                if (selectedVenueType != 'All') _ActiveFilter(label: selectedVenueType),
                if (selectedWhen != 'Any time') _ActiveFilter(label: selectedWhen),
              ],
            ),
          ),
          if (!isLoading && _hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  results.isEmpty
                      ? 'No results found'
                      : '${results.length} result${results.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const PremiumEmptyState(
                        icon: Icons.search_rounded,
                        title: 'Search DrinkSpot',
                        subtitle: 'Type at least 2 letters to find venues by drinks, ingredients, deals or events.',
                      )
                    : results.isEmpty
                        ? const PremiumEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matches yet',
                            subtitle: 'Try a different drink, venue, deal or filter.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: (results.length > _visibleResultLimit
                                    ? _visibleResultLimit
                                    : results.length) +
                                (results.length > _visibleResultLimit ? 1 : 0),
                            itemBuilder: (context, index) {
                              final visibleCount = results.length > _visibleResultLimit
                                  ? _visibleResultLimit
                                  : results.length;

                              if (index >= visibleCount) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                                  child: OutlinedButton(
                                    onPressed: _loadMoreResults,
                                    child: const Text('Load more results'),
                                  ),
                                );
                              }

                              final item = results[index];
                              return _VenueSearchResultCard(item: item);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}


class _VenueSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _VenueSearchResultCard({required this.item});

  String _joinNames(List<dynamic> items, String key, {int max = 2}) {
    final names = items
        .map((entry) {
          if (entry is Map<String, dynamic>) {
            return entry[key]?.toString() ?? '';
          }
          if (entry is Map) {
            return entry[key]?.toString() ?? '';
          }
          return '';
        })
        .where((value) => value.trim().isNotEmpty)
        .take(max)
        .toList();

    return names.join(', ');
  }

  String _buildMatchLine() {
    final drinks = (item['matchedDrinks'] as List?) ?? const [];
    final deals = (item['matchedDeals'] as List?) ?? const [];
    final events = (item['matchedEvents'] as List?) ?? const [];

    if (drinks.isNotEmpty) {
      final names = _joinNames(drinks, 'name');
      final extra = drinks.length > 2 ? ' +${drinks.length - 2} more' : '';
      return '${drinks.length == 1 ? 'Matched drink' : 'Matched drinks'}: $names$extra';
    }

    if (events.isNotEmpty) {
      final names = _joinNames(events, 'title');
      final extra = events.length > 2 ? ' +${events.length - 2} more' : '';
      return '${events.length == 1 ? 'Matched event' : 'Matched events'}: $names$extra';
    }

    if (deals.isNotEmpty) {
      final names = _joinNames(deals, 'title');
      final extra = deals.length > 2 ? ' +${deals.length - 2} more' : '';
      return '${deals.length == 1 ? 'Matched deal' : 'Matched deals'}: $names$extra';
    }

    return 'Venue match';
  }

  String _buildSecondaryLine() {
    final drinks = (item['matchedDrinks'] as List?) ?? const [];
    if (drinks.isNotEmpty) {
      final anyAvailable = drinks.any((entry) {
        if (entry is Map) return entry['available'] == true;
        return false;
      });
      return anyAvailable ? 'Available' : '';
    }

    final crowd = item['crowdLevel']?.toString() ?? '';
    final category = item['venueCategory']?.toString() ?? '';
    return [category, crowd].where((value) => value.isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final venueId = item['venueId']?.toString() ?? '';
    final venueName = item['venueName']?.toString() ?? 'Unknown venue';
    final bannerImageUrl = item['bannerImageUrl']?.toString() ?? '';
    final matchLine = _buildMatchLine();
    final secondaryLine = _buildSecondaryLine();

    return GestureDetector(
      onTap: venueId.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VenueDetailsScreen(venueId: venueId),
                ),
              );
            },
      child: Container(
        height: 112,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.45),
            width: 1,
          ),
          color: const Color(0xFF181925),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerImageUrl.isNotEmpty)
              Image.network(
                bannerImageUrl,
                fit: BoxFit.cover,
                cacheWidth: 700,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 44, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    venueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    matchLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (secondaryLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ResultPill(secondaryLine),
                  ],
                ],
              ),
            ),
            const Positioned(
              right: 12,
              bottom: 12,
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilter extends StatelessWidget {
  final String label;

  const _ActiveFilter({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
      visualDensity: VisualDensity.compact,
      label: Text(label),
      avatar: const Icon(Icons.check_circle_outline, size: 16),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final String label;

  const _ResultPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
