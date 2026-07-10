import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/premium_scaffold.dart';
import '../../../core/theme/app_colors.dart';

import '../../crowd/utils/crowd_decay.dart';
import '../../venues/models/venue_details_model.dart';
import '../../venues/screens/venue_details_screen.dart';

enum FavouriteSortOption {
  recent,
  az,
  liveFirst,
}

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  FavouriteSortOption _sortOption = FavouriteSortOption.recent;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _favouritesStream;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _favouritesStream = FirebaseFirestore.instance
          .collection('favourites')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String get _sortLabel {
    switch (_sortOption) {
      case FavouriteSortOption.recent:
        return 'Recently saved';
      case FavouriteSortOption.az:
        return 'A-Z';
      case FavouriteSortOption.liveFirst:
        return 'Live first';
    }
  }

  Future<void> _removeFavourite({
    required BuildContext context,
    required String favouriteDocId,
    required String venueName,
  }) async {
    await FirebaseFirestore.instance
        .collection('favourites')
        .doc(favouriteDocId)
        .delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$venueName removed from saved'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAllFavourites(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> favourites,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all saved places?'),
          content: const Text(
            'This will remove all venues from your saved list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in favourites) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All saved places removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isRecentlySaved(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];

    if (createdAt is! Timestamp) return false;

    return DateTime.now().difference(createdAt.toDate()).inHours <= 24;
  }

  void _sortFavourites(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> favourites,
  ) {
    switch (_sortOption) {
      case FavouriteSortOption.recent:
        favourites.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });
        break;

      case FavouriteSortOption.az:
        favourites.sort((a, b) {
          final aName = a.data()['venueName']?.toString().toLowerCase() ?? '';
          final bName = b.data()['venueName']?.toString().toLowerCase() ?? '';
          return aName.compareTo(bName);
        });
        break;

      case FavouriteSortOption.liveFirst:
        favourites.sort((a, b) {
          final aLive = a.data()['isPublished'] == true ? 1 : 0;
          final bLive = b.data()['isPublished'] == true ? 1 : 0;
          return bLive.compareTo(aLive);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _favouritesStream == null) {
      return const PremiumScaffold(
        body: PremiumEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Log in to view saved places',
          subtitle: 'Your favourite venues and nights out will appear here.',
        ),
      );
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        actions: [
          PopupMenuButton<FavouriteSortOption>(
            tooltip: 'Sort saved places',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FavouriteSortOption.recent,
                child: Text('Recently saved'),
              ),
              PopupMenuItem(
                value: FavouriteSortOption.az,
                child: Text('A-Z'),
              ),
              PopupMenuItem(
                value: FavouriteSortOption.liveFirst,
                child: Text('Live first'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _favouritesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favourites = <QueryDocumentSnapshot<Map<String, dynamic>>>[
            ...(snapshot.data?.docs ?? []),
          ];

          _sortFavourites(favourites);

          if (favourites.isEmpty) {
            return const PremiumEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No saved places yet',
              subtitle: 'Save venues, deals and nights you want to come back to.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${favourites.length} saved ${favourites.length == 1 ? 'place' : 'places'} • $_sortLabel',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _clearAllFavourites(
                        context,
                        favourites,
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search saved places...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _searchFocusNode.requestFocus();
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: favourites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final favouriteDoc = favourites[index];
                    final data = favouriteDoc.data();

                    final venueId = data['venueId']?.toString() ?? '';
                    final fallbackName =
                        data['venueName']?.toString() ?? 'Venue';

                    return AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Dismissible(
                        key: ValueKey(favouriteDoc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          _removeFavourite(
                            context: context,
                            favouriteDocId: favouriteDoc.id,
                            venueName: fallbackName,
                          );
                        },
                        child: _FavouriteVenueCard(
                          venueId: venueId,
                          fallbackName: fallbackName,
                          searchQuery: _searchQuery,
                          recentlySaved: _isRecentlySaved(data),
                          onRemove: () {
                            _removeFavourite(
                              context: context,
                              favouriteDocId: favouriteDoc.id,
                              venueName: fallbackName,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavouriteVenueCard extends StatelessWidget {
  final String venueId;
  final String fallbackName;
  final String searchQuery;
  final bool recentlySaved;
  final VoidCallback onRemove;

  const _FavouriteVenueCard({
    required this.venueId,
    required this.fallbackName,
    required this.searchQuery,
    required this.recentlySaved,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (venueId.isEmpty) {
      return _UnavailableCard(
        title: fallbackName,
        subtitle: 'Saved venue is missing an ID',
        onRemove: onRemove,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _LoadingCard(title: fallbackName);
        }

        final doc = snapshot.data;

        if (doc == null || !doc.exists) {
          return _UnavailableCard(
            title: fallbackName,
            subtitle: 'This venue is no longer available',
            onRemove: onRemove,
          );
        }

        final venue = VenueDetailsModel.fromFirestore(doc);

        final query = searchQuery.toLowerCase().trim();

        final searchableText = [
          venue.name,
          venue.venueType,
          venue.category,
          venue.addressLine1,
          venue.addressLine2,
          venue.city,
          venue.postcode,
          venue.country,
        ].join(' ').toLowerCase();

        if (query.isNotEmpty && !searchableText.contains(query)) {
          return const SizedBox.shrink();
        }

        final address = [
          venue.addressLine1,
          venue.city,
          venue.postcode,
        ].where((part) => part.trim().isNotEmpty).join(', ');

        final crowdLevel = CrowdDecay.displayLevel(
          level: venue.currentCrowdLevel,
          updatedAt: venue.updatedAt,
        );

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VenueDetailsScreen(venueId: venue.id),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF9D28FF).withOpacity(0.45),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (venue.coverImageUrl.trim().isNotEmpty)
                    Image.network(
                      venue.coverImageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.78),
                          Colors.black.withOpacity(0.52),
                          Colors.black.withOpacity(0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      venue.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (venue.isVerified)
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: Color(0xFF9D28FF),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (address.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 15,
                                      color: Colors.white.withOpacity(0.78),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.78),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _Pill(
                                      icon: Icons.local_bar_outlined,
                                      label: venue.venueType.isNotEmpty
                                          ? venue.venueType
                                          : 'Venue',
                                      color: const Color(0xFFFF2D95),
                                    ),
                                    const SizedBox(width: 7),
                                    _Pill(
                                      icon: Icons.groups_rounded,
                                      label: crowdLevel,
                                      color: _crowdColor(crowdLevel),
                                    ),
                                    if (venue.isPublished) ...[
                                      const SizedBox(width: 7),
                                      _Pill(
                                        icon: Icons.public_rounded,
                                        label: 'Live',
                                        color: Colors.green,
                                      ),
                                    ],
                                    if (recentlySaved) ...[
                                      const SizedBox(width: 7),
                                      _Pill(
                                        icon: Icons.new_releases_outlined,
                                        label: 'New',
                                        color: Colors.blue,
                                      ),
                                    ],
                                    if (crowdLevel.toLowerCase() == 'busy' ||
                                        crowdLevel.toLowerCase() == 'packed') ...[
                                      const SizedBox(width: 7),
                                      _Pill(
                                        icon: Icons.local_fire_department_rounded,
                                        label: 'Busy now',
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                    _VenueLivePills(venueId: venue.id),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from saved',
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _crowdColor(String level) {
    switch (level.toLowerCase()) {
      case 'quiet':
        return Colors.green;
      case 'steady':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'busy':
        return Colors.deepOrange;
      case 'packed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}


class _VenueLivePills extends StatelessWidget {
  final String venueId;

  const _VenueLivePills({required this.venueId});

  Future<Map<String, int>> _loadCounts() async {
    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();

    final events = await db
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .limit(50)
        .get();

    final activeEventCount = events.docs.where((doc) {
      final data = doc.data();
      final endTimestamp = data['endDateTime'] as Timestamp?;
      final startTimestamp = data['startDateTime'] as Timestamp? ?? data['dateTime'] as Timestamp?;
      final endDate = endTimestamp?.toDate() ?? (startTimestamp == null ? null : startTimestamp.toDate().add(const Duration(hours: 24)));
      return endDate != null && endDate.isAfter(now.toDate());
    }).length;
    final deals = await db
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .limit(10)
        .get();

    return {
      'events': activeEventCount,
      'deals': deals.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _loadCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? const {'events': 0, 'deals': 0};
        final eventCount = counts['events'] ?? 0;
        final dealCount = counts['deals'] ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eventCount > 0) ...[
              const SizedBox(width: 7),
              _Pill(
                icon: Icons.event_available_outlined,
                label: '$eventCount event${eventCount == 1 ? '' : 's'}',
                color: Colors.indigo,
              ),
            ],
            if (dealCount > 0) ...[
              const SizedBox(width: 7),
              _Pill(
                icon: Icons.local_offer_outlined,
                label: '$dealCount deal${dealCount == 1 ? '' : 's'}',
                color: Colors.teal,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VenueImage extends StatelessWidget {
  final String imageUrl;
  final String venueName;

  const _VenueImage({
    required this.imageUrl,
    required this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        height: 82,
        color: Colors.grey.shade200,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        venueName.isNotEmpty ? venueName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.95), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String title;

  const _LoadingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(title),
        subtitle: const Text('Loading venue...'),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  const _UnavailableCard({
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(Icons.info_outline, color: Colors.grey.shade600),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: onRemove,
          child: const Text('Remove'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 78,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No saved venues yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on venues you like and they’ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}