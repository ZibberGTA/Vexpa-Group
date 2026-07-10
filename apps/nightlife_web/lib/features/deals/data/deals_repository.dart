import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venue/data/models/deal_model.dart';
import '../../search/data/search_repository.dart';
import '../../search/models/venue_search_result.dart';

class DealBrowseItem {
  const DealBrowseItem({
    required this.deal,
    required this.venueName,
    required this.city,
    required this.drinkLabel,
  });

  final DealModel deal;
  final String venueName;
  final String city;
  final String drinkLabel;
}

/// Loads active deals grouped for the public deals browse page.
class DealsRepository {
  DealsRepository({
    FirebaseFirestore? firestore,
    SearchRepository? searchRepository,
  })  : _firestoreOverride = firestore,
        _searchRepository = searchRepository ?? SearchRepository();

  final FirebaseFirestore? _firestoreOverride;
  final SearchRepository _searchRepository;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<List<DealBrowseItem>> loadActiveDeals() async {
    final firestore = _resolveFirestore();
    final catalog = await _searchRepository.loadCatalog();
    final venueById = {
      for (final venue in catalog.venues) venue.id: venue,
    };

    if (firestore == null) {
      return _placeholderDeals(venueById);
    }

    try {
      final snapshot = await firestore
          .collection('deals')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(48)
          .get();

      final items = snapshot.docs
          .map((doc) => DealModel.fromMap(doc.id, doc.data()))
          .where((deal) => deal.isCurrentlyVisible)
          .map((deal) => _toBrowseItem(deal, venueById[deal.venueId]))
          .toList();

      if (items.isEmpty) return _placeholderDeals(venueById);
      return items;
    } on Object {
      return _placeholderDeals(venueById);
    }
  }

  DealBrowseItem _toBrowseItem(DealModel deal, VenueSearchResult? venue) {
    return DealBrowseItem(
      deal: deal,
      venueName: venue?.name ?? 'Venue',
      city: venue?.city.isNotEmpty == true ? venue!.city : (venue?.area ?? 'UK'),
      drinkLabel: _inferDrinkLabel(deal),
    );
  }

  String _inferDrinkLabel(DealModel deal) {
    final text = '${deal.title} ${deal.description}'.toLowerCase();
    const drinks = ['cocktail', 'pint', 'wine', 'spirit', 'shot', 'beer', 'prosecco'];
    for (final drink in drinks) {
      if (text.contains(drink)) {
        return drink[0].toUpperCase() + drink.substring(1);
      }
    }
    return 'Drinks';
  }

  List<DealBrowseItem> _placeholderDeals(Map<String, VenueSearchResult> venueById) {
    final venues = venueById.values.take(6).toList();
    if (venues.isEmpty) {
      return const [
        DealBrowseItem(
          deal: DealModel(
            id: 'preview-1',
            venueId: 'preview',
            title: '2-for-1 Cocktails',
            description: 'Every Thursday until close.',
            startTime: '17:00',
            endTime: '22:00',
          ),
          venueName: 'The Neon Room',
          city: 'London',
          drinkLabel: 'Cocktail',
        ),
      ];
    }

    return venues.asMap().entries.map((entry) {
      final venue = entry.value;
      return DealBrowseItem(
        deal: DealModel(
          id: 'preview-${entry.key}',
          venueId: venue.id,
          title: entry.key.isEven ? 'Happy Hour' : '2-for-1 Selected Drinks',
          description: 'Available tonight at ${venue.name}.',
          startTime: '17:00',
          endTime: '21:00',
        ),
        venueName: venue.name,
        city: venue.city.isNotEmpty ? venue.city : venue.area,
        drinkLabel: entry.key.isEven ? 'Cocktail' : 'Beer',
      );
    }).toList();
  }
}
