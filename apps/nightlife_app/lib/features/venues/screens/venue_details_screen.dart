import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vex_engines/experience/application/experience_drink_grouper.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_scaffold.dart';

import '../../favourites/services/favourites_service.dart';
import '../../analytics/services/analytics_service.dart';
import '../../crowd/utils/crowd_decay.dart';
import '../../crowd/services/smart_crowd_service.dart';
import '../services/venue_details_service.dart';
import '../services/venue_media_service.dart';
import '../utils/venue_image_resolver.dart';
import '../models/venue_details_model.dart';
import '../models/venue_media_model.dart';
import '../../home/models/event_model.dart';
import '../../home/models/deal_model.dart';
import '../../home/services/event_service.dart';
import '../../home/services/deal_service.dart';
import '../../venues/screens/apply_to_perform_screen.dart';
import '../../artists/services/artist_service.dart';
import '../../monetisation/screens/artist_subscription_required_screen.dart';
import '../../monetisation/services/subscription_service.dart';


class VenueDetailsScreen extends StatefulWidget {
  final String venueId;

  const VenueDetailsScreen({
    super.key,
    required this.venueId,
  });

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  final VenueMediaService _venueMediaService = VenueMediaService();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logVenueView(widget.venueId);
    DealService.deactivateExpiredDealsForVenue(widget.venueId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PremiumBackground(
        child: StreamBuilder(
        stream: VenueDetailsService.venueStream(widget.venueId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorScreen(message: 'Error loading venue:\n${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _VenueSkeletonList();
          }

          final venue = snapshot.data;

          if (venue == null) {
            return const _ErrorScreen(message: 'Venue not found');
          }

          final bannerUrl = venue.coverImageUrl.trim();
          final logoUrl = venue.logoUrl.trim();

          return StreamBuilder<VenueMediaBundle>(
            stream: _venueMediaService.watchPublicMedia(widget.venueId),
            builder: (context, mediaSnapshot) {
              final media = mediaSnapshot.data ?? VenueMediaBundle.empty();
              final galleryUrls = VenueImageResolver.resolveGalleryUrls(
                venue: venue,
                galleryMedia: media.galleryItems,
              );

              return DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 300,
                    collapsedHeight: kToolbarHeight,
                    pinned: true,
                    stretch: false,
                    backgroundColor: AppColors.background,
                    foregroundColor: Colors.white,
                    actions: [
                      _FavouriteButton(
                        venueId: widget.venueId,
                        venueName: venue.name,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 16,
                      ),
                      title: Text(
                        venue.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      collapseMode: CollapseMode.pin,
                      background: SizedBox.expand(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            bannerUrl.isNotEmpty
                                ? Image.network(
                                    bannerUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 240,
                                    errorBuilder: (_, __, ___) {
                                      return _HeaderPlaceholder(venueName: venue.name);
                                    },
                                  )
                                : _HeaderPlaceholder(venueName: venue.name),
                            Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.background,
                                ],
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _VenueHeroCard(
                            venue: venue,
                            venueId: widget.venueId,
                            logoUrl: logoUrl,
                          ),
                  ),
                  if (galleryUrls.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _VenueGallery(imageUrls: galleryUrls),
                    ),
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
                  _DrinksTab(venueId: widget.venueId),
                  _DealsTab(
                    venueId: widget.venueId,
                    dealMedia: media.dealImages,
                  ),
                  _EventsTab(
                    venueId: widget.venueId,
                    eventMedia: media.eventImages,
                  ),
                  _InfoTab(venue: venue),
                ],
              ),
            ),
          );
            },
          );
        },
      ),
      ),
    );
  }
}


class _VenueGallery extends StatelessWidget {
  final List<String> imageUrls;

  const _VenueGallery({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final visibleImages = imageUrls
        .where((url) => url.trim().isNotEmpty)
        .take(8)
        .toList();

    if (visibleImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 16, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: AppColors.primaryPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Venue gallery',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = visibleImages[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 230,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primaryPurple.withOpacity(0.32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.40),
                              ],
                            ),
                          ),
                        ),
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


class _VenueHeroCard extends StatelessWidget {
  final VenueDetailsModel venue;
  final String venueId;
  final String logoUrl;

  const _VenueHeroCard({
    required this.venue,
    required this.venueId,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final description = venue.description.trim();
    final heroTags = VenueProfileFieldCodec.displayFeatureTags(
      featureTags: venue.featureTags,
      features: venue.features,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.88),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _VenueLogo(venueName: venue.name, logoUrl: logoUrl),
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
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (venue.venueType.toString().isNotEmpty) venue.venueType.toString(),
                            if (venue.addressLine1.toString().isNotEmpty) venue.addressLine1.toString(),
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

              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in heroTags)
                    _Pill(icon: Icons.label_outline_rounded, label: tag),
                  _SmartCrowdPill(
                    venueId: venueId,
                    level: venue.currentCrowdLevel.toString(),
                    updatedAt: venue.crowdUpdatedAt ?? venue.updatedAt,
                  ),
                  if (venue.isPublished == true)
                    const _Pill(
                      icon: Icons.verified,
                      label: 'Live',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              _ApplyToPerformGate(
                venueId: venueId,
                venueName: venue.name,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _VenueLogo extends StatelessWidget {
  final String venueName;
  final String logoUrl;

  const _VenueLogo({required this.venueName, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final firstLetter = venueName.trim().isNotEmpty ? venueName.trim()[0].toUpperCase() : '?';

    return Container(
      width: 58,
      height: 58,
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
  final String letter;

  const _LogoFallback({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
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

class _ApplyToPerformGate extends StatelessWidget {
  final String venueId;
  final String venueName;

  const _ApplyToPerformGate({
    required this.venueId,
    required this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    // Do not subscribe to the artist profile stream when no user is signed in.
    // ArtistService.artistProfileStream() throws for logged-out users, which
    // causes a red Flutter exception box on the public venue page.
    if (ArtistService.currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ArtistService.artistProfileStream(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return const SizedBox.shrink();
        }

        final profileExists = profileSnapshot.data?.exists ?? false;

        if (!profileExists) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<bool>(
          future: SubscriptionService.isArtistSubscriptionActive(),
          builder: (context, subscriptionSnapshot) {
            final subscriptionActive = subscriptionSnapshot.data ?? false;

            if (!subscriptionActive) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Artist Pro required to apply'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArtistSubscriptionRequiredScreen(),
                      ),
                    );
                  },
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.music_note),
                label: const Text('Apply to Perform'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplyToPerformScreen(
                        venueId: venueId,
                        venueName: venueName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _DrinksTab extends StatefulWidget {
  final String venueId;

  const _DrinksTab({required this.venueId});

  @override
  State<_DrinksTab> createState() => _DrinksTabState();
}

class _DrinksTabState extends State<_DrinksTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _focusedCategory;
  static const _presentation = VenuePresentationSupport();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic rawPrice) =>
      _presentation.formatPricePlainFromRaw(rawPrice);

  String _normaliseCategory(dynamic rawCategory) =>
      ExperienceDrinkGrouper.normaliseCategory(rawCategory?.toString());

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupDrinks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> drinks,
  ) {
    return ExperienceDrinkGrouper.groupByCategory(
      drinks,
      category: (drink) => drink.data()['category']?.toString() ?? '',
      name: (drink) => drink.data()['name']?.toString() ?? '',
      available: (drink) => drink.data()['available'] == true,
    );
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cocktail') || lower.contains('mocktail')) return Icons.local_bar;
    if (lower.contains('beer') || lower.contains('lager') || lower.contains('ale')) return Icons.sports_bar;
    if (lower.contains('wine') || lower.contains('sparkling') || lower.contains('champagne')) return Icons.wine_bar;
    if (lower.contains('spirit') || lower.contains('whisky') || lower.contains('vodka') || lower.contains('gin') || lower.contains('rum') || lower.contains('tequila')) return Icons.liquor;
    if (lower.contains('soft')) return Icons.local_drink;
    return Icons.local_bar;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDrinks(List<QueryDocumentSnapshot<Map<String, dynamic>>> drinks) {
    final query = _query.trim().toLowerCase();
    return drinks.where((doc) {
      final data = doc.data();
      final category = _normaliseCategory(data['category']);
      if (_focusedCategory != null && category != _focusedCategory) return false;
      if (query.isEmpty) return true;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      return name.contains(query) || description.contains(query) || category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('drinks')
          .where('venueId', isEqualTo: widget.venueId)
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InlineError(message: 'Error loading drinks:\n${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _VenueSkeletonList();
        }

        final drinks = snapshot.data?.docs ?? [];

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
        final trendingDrinks = drinks.where((doc) => doc.data()['available'] == true).take(4).toList();

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
                        formatPrice: _formatPrice,
                        onDrinkTap: (doc) {
                          final data = doc.data();
                          AnalyticsService.logDrinkView(
                            venueId: widget.venueId,
                            drinkId: doc.id,
                            drinkName: data['name']?.toString() ?? 'Drink',
                          );
                        },
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
                      final category = entry.key;
                      final items = entry.value;

                      return _DrinkCategorySection(
                        title: category,
                        count: items.length,
                        icon: _categoryIcon(category),
                        initiallyExpanded: _focusedCategory == category || _query.trim().isNotEmpty,
                        children: items.map((doc) {
                          final data = doc.data();

                          final name = data['name']?.toString() ?? 'Unknown drink';
                          final available = data['available'] == true;
                          final priceText = _formatPrice(data['price']);
                          final description = data['description']?.toString() ?? '';

                          return _DrinkMenuItem(
                            name: name,
                            description: description,
                            available: available,
                            priceText: priceText,
                            onTap: () => AnalyticsService.logDrinkView(
                              venueId: widget.venueId,
                              drinkId: doc.id,
                              drinkName: name,
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
  const _TrendingDrinksStrip({required this.drinks, required this.formatPrice, required this.onDrinkTap});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> drinks;
  final String Function(dynamic rawPrice) formatPrice;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onDrinkTap;

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
                final doc = drinks[index];
                final data = doc.data();
                final name = data['name']?.toString() ?? 'Drink';
                final price = formatPrice(data['price']);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onDrinkTap(doc),
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
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
                        if (price.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text('£$price', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
                        ],
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

class _DrinkCategorySection extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _DrinkCategorySection({
    required this.title,
    required this.count,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

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
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.95),
                          AppColors.primaryPink.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.55)),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textPrimary,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(children: widget.children),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _DrinkMenuItem extends StatelessWidget {
  final String name;
  final String description;
  final bool available;
  final String priceText;
  final VoidCallback onTap;

  const _DrinkMenuItem({
    required this.name,
    required this.description,
    required this.available,
    required this.priceText,
    required this.onTap,
  });

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
          border: Border.all(
            color: available
                ? AppColors.primaryPurple.withOpacity(0.22)
                : AppColors.muted.withOpacity(0.18),
          ),
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
                boxShadow: available
                    ? [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: available ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (!available) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Currently unavailable',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (priceText.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                '£$priceText',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  final String venueId;
  final List<VenueMediaModel> dealMedia;

  const _DealsTab({
    required this.venueId,
    this.dealMedia = const [],
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DealModel>>(
      stream: DealService.getDealsForVenue(venueId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InlineError(message: 'Error loading deals:\n${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _VenueSkeletonList();
        }

        final deals = snapshot.data ?? [];

        if (deals.isEmpty) {
          return const _EmptyState(
            icon: Icons.local_offer,
            title: 'No active deals',
            message: 'Current deals will appear here. Expired deals are hidden automatically.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            final imageUrl = VenueImageResolver.dealImageUrl(
              dealId: deal.id,
              dealMedia: dealMedia,
            );

            return _PremiumListCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            backgroundColor: AppColors.primaryPurple.withOpacity(0.16),
                            child: const Icon(Icons.local_offer, color: AppColors.primaryPurple),
                          ),
                        ),
                      )
                    : CircleAvatar(
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
                onTap: () => AnalyticsService.logDealView(
                  venueId: venueId,
                  dealId: deal.id,
                  dealTitle: deal.title,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  final String venueId;
  final List<VenueMediaModel> eventMedia;

  const _EventsTab({
    required this.venueId,
    this.eventMedia = const [],
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getEventsForVenue(venueId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InlineError(message: 'Error loading events:\n${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _VenueSkeletonList();
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return const _EmptyState(
            icon: Icons.event,
            title: 'No upcoming events yet',
            message: 'Upcoming events will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final imageUrl = VenueImageResolver.resolveEventImage(
              event: event,
              eventMedia: eventMedia,
            );

            final day = event.startDateTime.day.toString().padLeft(2, '0');
            final month = event.startDateTime.month.toString().padLeft(2, '0');
            final time = '${_formatTime(event.startDateTime)} - ${_formatTime(event.endDateTime)}';

            return InkWell(
              onTap: () => AnalyticsService.logEventView(
                venueId: venueId,
                eventId: event.id,
                eventTitle: event.title,
              ),
              child: _PremiumListCard(
                margin: const EdgeInsets.only(bottom: 14),
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const SizedBox.shrink();
                      },
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${event.category} • $time',
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                event.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
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
  final dynamic venue;

  const _InfoTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PremiumListCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.store, title: 'Name', value: venue.name),
                _InfoRow(icon: Icons.category, title: 'Type', value: venue.venueType),
                _InfoRow(icon: Icons.groups, title: 'Crowd', value: _venueCrowdLabel(CrowdDecay.displayLevel(level: venue.currentCrowdLevel, updatedAt: venue.crowdUpdatedAt ?? venue.updatedAt))),
                _InfoRow(icon: Icons.speed, title: 'Score', value: venue.currentCrowdScore.toString()),
                if (venue.city.toString().isNotEmpty)
                  _InfoRow(icon: Icons.location_city, title: 'City', value: venue.city),
                if (venue.postcode.toString().isNotEmpty)
                  _InfoRow(icon: Icons.pin_drop, title: 'Postcode', value: venue.postcode),
                if (venue.phone.toString().isNotEmpty)
                  _InfoRow(icon: Icons.phone, title: 'Phone', value: venue.phone),
                if (venue.website.toString().isNotEmpty)
                  _InfoRow(icon: Icons.language, title: 'Website', value: venue.website),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderPlaceholder extends StatelessWidget {
  final String venueName;

  const _HeaderPlaceholder({required this.venueName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepPurpleBackground,
      child: Center(
        child: Text(
          venueName.isNotEmpty ? venueName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 84,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartCrowdPill extends StatelessWidget {
  const _SmartCrowdPill({required this.venueId, required this.level, required this.updatedAt});

  final String venueId;
  final String level;
  final dynamic updatedAt;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SmartCrowdSnapshot>(
      stream: SmartCrowdService.venueCrowdStream(
        venueId: venueId,
        manualLevel: level,
        updatedAt: updatedAt,
      ),
      builder: (context, snapshot) {
        final value = snapshot.data?.level ?? CrowdDecay.displayLevel(level: level, updatedAt: updatedAt);
        return _CrowdPill(level: value);
      },
    );
  }
}

String _venueCrowdLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'quiet':
      return 'Relaxed';
    case 'medium':
    case 'steady':
      return 'Steady';
    case 'busy':
      return 'Buzzing';
    case 'packed':
      return 'Lively';
    default:
      if (value.isEmpty) return 'Unknown';
      return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class _CrowdPill extends StatelessWidget {
  final String level;

  const _CrowdPill({required this.level});

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

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.65, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.65),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups, size: 18, color: color),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  child: Text(
                    _venueCrowdLabel(level),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

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
          if (overlapsContent)
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            SizedBox(
              width: 82,
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
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
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primaryPurple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
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
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}


class _PremiumListCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  const _PremiumListCard({
    required this.child,
    this.margin,
    this.padding = EdgeInsets.zero,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Venue')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  final String venueId;
  final String venueName;

  const _FavouriteButton({
    required this.venueId,
    required this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FavouritesService.isFavouriteStream(venueId),
      builder: (context, snapshot) {
        final isFavourite = snapshot.data ?? false;

        return IconButton(
          tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
          icon: Icon(
            isFavourite ? Icons.favorite : Icons.favorite_border,
            color: isFavourite ? Colors.redAccent : Colors.white,
          ),
          onPressed: () async {
            try {
              await FavouritesService.toggleFavourite(
                venueId: venueId,
                venueName: venueName,
              );
            } catch (e) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          },
        );
      },
    );
  }
}