import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/venue_details_mapper.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_repository.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_media_item.dart';
import 'package:nightlife_web/features/venue_management/models/venue_media_type.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('VenueMediaItem featured selection', () {
    test('canBeFeatured requires active gallery photo with URL', () {
      const valid = VenueMediaItem(
        id: 'g1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.gallery,
        imageUrl: 'https://example.com/g1.jpg',
      );
      const deleted = VenueMediaItem(
        id: 'g2',
        venueId: 'wine-central',
        mediaType: VenueMediaType.gallery,
        imageUrl: 'https://example.com/g2.jpg',
        status: 'deleted',
        visible: false,
      );
      const deal = VenueMediaItem(
        id: 'd1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.deal,
        imageUrl: 'https://example.com/d1.jpg',
      );
      const emptyUrl = VenueMediaItem(
        id: 'g3',
        venueId: 'wine-central',
        mediaType: VenueMediaType.gallery,
        imageUrl: '',
      );

      expect(valid.canBeFeatured, isTrue);
      expect(deleted.canBeFeatured, isFalse);
      expect(deal.canBeFeatured, isFalse);
      expect(emptyUrl.canBeFeatured, isFalse);
    });

    test('isCover requires featured gallery media', () {
      const featuredGallery = VenueMediaItem(
        id: 'g1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.gallery,
        imageUrl: 'https://example.com/g1.jpg',
        featured: true,
      );
      const featuredDeal = VenueMediaItem(
        id: 'd1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.deal,
        imageUrl: 'https://example.com/d1.jpg',
        featured: true,
      );

      expect(featuredGallery.isCover, isTrue);
      expect(featuredDeal.isCover, isFalse);
    });
  });

  group('VenueMediaRepository.setCoverPhoto', () {
    late Map<String, Map<String, Map<String, dynamic>>> store;
    late VenueMediaRepository repository;

    setUp(() {
      store = {
        'wine-central': {
          'g1': {
            'venueId': 'wine-central',
            'mediaType': 'gallery',
            'imageUrl': 'https://example.com/g1.jpg',
            'visible': true,
            'sortOrder': 0,
            'featured': true,
          },
          'g2': {
            'venueId': 'wine-central',
            'mediaType': 'gallery',
            'imageUrl': 'https://example.com/g2.jpg',
            'visible': true,
            'sortOrder': 1,
          },
          'd1': {
            'venueId': 'wine-central',
            'mediaType': 'deal',
            'imageUrl': 'https://example.com/d1.jpg',
            'visible': true,
            'sortOrder': 0,
          },
        },
      };
      repository = VenueMediaRepository.inMemory(store);
    });

    Future<List<VenueMediaItem>> galleryItems() {
      return repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;
    }

    test(
      'selecting a gallery image marks it featured and clears others',
      () async {
        await repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g2');

        final items = await galleryItems();
        expect(items.where((item) => item.featured), hasLength(1));
        expect(items.firstWhere((item) => item.id == 'g2').isCover, isTrue);
        expect(items.firstWhere((item) => item.id == 'g1').isCover, isFalse);
      },
    );

    test('only one featured image exists after replacement', () async {
      await repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g2');
      await repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g1');

      final items = await galleryItems();
      expect(items.where((item) => item.featured), hasLength(1));
      expect(items.firstWhere((item) => item.id == 'g1').isCover, isTrue);
    });

    test('rejects deal images', () async {
      expect(
        () => repository.setCoverPhoto(venueId: 'wine-central', itemId: 'd1'),
        throwsStateError,
      );
    });

    test('rejects deleted gallery images', () async {
      store['wine-central']!['g3'] = {
        'venueId': 'wine-central',
        'mediaType': 'gallery',
        'imageUrl': 'https://example.com/g3.jpg',
        'visible': false,
        'status': 'deleted',
      };

      expect(
        () => repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g3'),
        throwsStateError,
      );
    });

    test('rejects gallery images without URLs', () async {
      store['wine-central']!['g4'] = {
        'venueId': 'wine-central',
        'mediaType': 'gallery',
        'imageUrl': '',
        'visible': true,
      };

      expect(
        () => repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g4'),
        throwsStateError,
      );
    });

    test('featured gallery image sorts first in watch stream', () async {
      await repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g2');

      final items = await galleryItems();
      expect(items.first.id, 'g2');
      expect(items.first.isCover, isTrue);
    });

    test('legacy gallery docs without status can be featured', () async {
      store['wine-central']!['g1'] = {
        'venueId': 'wine-central',
        'mediaType': 'gallery',
        'imageUrl': 'https://example.com/g1.jpg',
        'visible': true,
        'sortOrder': 0,
        'featured': true,
      };
      store['wine-central']!['g3'] = {
        'venueId': 'wine-central',
        'mediaType': 'gallery',
        'imageUrl': 'https://example.com/g3.jpg',
        'visible': true,
        'sortOrder': 2,
      };

      await repository.setCoverPhoto(venueId: 'wine-central', itemId: 'g2');

      expect(store['wine-central']!['g2']!['featured'], isTrue);
      expect(store['wine-central']!['g2']!['status'], 'active');
      expect(store['wine-central']!['g1']!['featured'], isFalse);
      expect(store['wine-central']!['g3']!.containsKey('status'), isFalse);
    });
  });

  group('VenueModel gallery parsing', () {
    test('featured gallery image is ordered first without duplication', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'galleryImages': [
          {
            'imageId': 'g1',
            'imageUrl': 'https://example.com/g1.jpg',
            'sortOrder': 1,
          },
          {
            'imageId': 'g2',
            'imageUrl': 'https://example.com/g2.jpg',
            'sortOrder': 0,
            'isCover': true,
          },
          {
            'imageId': 'g3',
            'imageUrl': 'https://example.com/g3.jpg',
            'sortOrder': 2,
          },
        ],
      });

      expect(venue.galleryImages, hasLength(3));
      expect(venue.galleryImages.first.imageId, 'g2');
      expect(venue.galleryImages.first.isCover, isTrue);
      expect(venue.galleryImages.map((image) => image.imageId), [
        'g2',
        'g1',
        'g3',
      ]);
    });

    test('reads legacy featured flag on gallery image metadata', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'galleryImages': [
          {
            'imageId': 'g1',
            'imageUrl': 'https://example.com/g1.jpg',
            'featured': true,
            'sortOrder': 2,
          },
          {
            'imageId': 'g2',
            'imageUrl': 'https://example.com/g2.jpg',
            'sortOrder': 0,
          },
        ],
      });

      expect(venue.galleryImages.first.imageId, 'g1');
      expect(venue.galleryImages.first.isCover, isTrue);
    });

    test('filters deleted gallery images from public model', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'galleryImages': [
          {
            'imageId': 'g1',
            'imageUrl': 'https://example.com/g1.jpg',
            'status': 'deleted',
          },
          {
            'imageId': 'g2',
            'imageUrl': 'https://example.com/g2.jpg',
            'isCover': true,
          },
        ],
      });

      expect(venue.galleryImages, hasLength(1));
      expect(venue.galleryImages.single.imageId, 'g2');
    });
  });

  group('VenueDetailsMapper featured gallery', () {
    test('uses featured gallery image for hero banner when available', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'bannerImageUrl': 'https://example.com/banner.jpg',
        'galleryImages': [
          {
            'imageId': 'g1',
            'imageUrl': 'https://example.com/featured.jpg',
            'isCover': true,
          },
          {'imageId': 'g2', 'imageUrl': 'https://example.com/other.jpg'},
        ],
      });

      final view = VenueDetailsMapper.fromVenueModel(venue);

      expect(view.bannerImageUrl, 'https://example.com/featured.jpg');
      expect(view.galleryImages.first.isCover, isTrue);
    });
  });
}
