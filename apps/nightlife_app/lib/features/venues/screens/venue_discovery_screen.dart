import 'dart:async';
import 'package:flutter/material.dart';

import '../models/venue_filter_model.dart';
import '../models/venue_model.dart';
import '../services/venue_search_service.dart';
import '../../trending/widgets/trending_venues_section.dart';
import 'venue_details_screen.dart';

class VenueDiscoveryScreen extends StatefulWidget {
  const VenueDiscoveryScreen({super.key});

  @override
  State<VenueDiscoveryScreen> createState() => _VenueDiscoveryScreenState();
}

class _VenueDiscoveryScreenState extends State<VenueDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  VenueFilterModel _filter = const VenueFilterModel();
  List<VenueModel> _venues = [];
  bool _loading = true;
  Timer? _debounce;

  static const List<String> _categories = ['Bar', 'Club', 'Pub'];
  static const List<String> _crowdLevels = [
    'quiet',
    'moderate',
    'busy',
    'packed',
  ];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    setState(() => _loading = true);

    try {
      final results = await VenueSearchService.searchVenues(_filter);

      if (!mounted) return;

      setState(() {
        _venues = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load venues: $e')),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _filter = _filter.copyWith(searchText: value);
      });
      _loadVenues();
    });
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _filter = const VenueFilterModel();
    });
    _loadVenues();
  }

  String _displayCrowdLevel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Venues'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search whisky, beer, 2 for 1, club...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filter.searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filter = _filter.copyWith(searchText: '');
                          });
                          _loadVenues();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                    label: Text(_filter.category ?? 'Category'),
                    selected: _filter.category != null,
                    onSelected: (_) => _showCategoryPicker(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                    label: Text(
                      _filter.crowdLevel != null
                          ? _displayCrowdLevel(_filter.crowdLevel!)
                          : 'Crowd',
                    ),
                    selected: _filter.crowdLevel != null,
                    onSelected: (_) => _showCrowdPicker(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                    label: const Text('Deals'),
                    selected: _filter.dealsOnly,
                    onSelected: (value) {
                      setState(() {
                        _filter = _filter.copyWith(dealsOnly: value);
                      });
                      _loadVenues();
                    },
                  ),
                ),
                if (_filter.hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                      label: const Text('Clear all'),
                      onPressed: _clearAllFilters,
                    ),
                  ),
              ],
            ),
          ),
          const TrendingVenuesSection(),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _venues.isEmpty
                    ? const Center(child: Text('No venues found'))
                    : RefreshIndicator(
                        onRefresh: _loadVenues,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _venues.length,
                          itemBuilder: (context, index) {
                            final venue = _venues[index];
                            return _VenueCard(venue: venue);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    final value = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Select category')),
            ListTile(
              title: const Text('All'),
              onTap: () => Navigator.pop(context, null),
            ),
            ..._categories.map(
              (e) => ListTile(
                title: Text(e),
                onTap: () => Navigator.pop(context, e),
              ),
            ),
          ],
        ),
      ),
    );

    if (value == null) {
      setState(() {
        _filter = _filter.copyWith(clearCategory: true);
      });
    } else {
      setState(() {
        _filter = _filter.copyWith(category: value);
      });
    }

    _loadVenues();
  }

  Future<void> _showCrowdPicker() async {
    final value = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Select crowd level')),
            ListTile(
              title: const Text('All'),
              onTap: () => Navigator.pop(context, null),
            ),
            ..._crowdLevels.map(
              (e) => ListTile(
                title: Text(_displayCrowdLevel(e)),
                onTap: () => Navigator.pop(context, e),
              ),
            ),
          ],
        ),
      ),
    );

    if (value == null) {
      setState(() {
        _filter = _filter.copyWith(clearCrowdLevel: true);
      });
    } else {
      setState(() {
        _filter = _filter.copyWith(crowdLevel: value);
      });
    }

    _loadVenues();
  }
}

class _VenueCard extends StatelessWidget {
  final VenueModel venue;

  const _VenueCard({required this.venue});

  String _displayCrowdLevel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VenueDetailsScreen(venueId: venue.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: venue.category),
                  _InfoChip(label: _displayCrowdLevel(venue.crowdLevel)),
                  if (venue.hasDeals) const _InfoChip(label: 'Deals'),
                ],
              ),
              if ((venue.address ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  venue.address!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (venue.matchReasons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Matches: ${venue.matchReasons.join(' • ')}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF9D28FF).withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}