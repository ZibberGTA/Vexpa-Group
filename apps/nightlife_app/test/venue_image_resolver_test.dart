import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/home/models/event_model.dart';
import 'package:nightlife_app/features/home/models/venue_model.dart';
import 'package:nightlife_app/features/venues/models/venue_details_model.dart';
import 'package:nightlife_app/features/venues/models/venue_media_model.dart';
import 'package:nightlife_app/features/venues/utils/venue_image_resolver.dart';

VenueDetailsModel _venue({
  String logoUrl = '',
  String coverImageUrl = '',
  List<String> galleryImageUrls = const [],
}) {
  return VenueDetailsModel(
    id: 'wine-central',
    name: 'Wine Central',
    description: '',
    venueType: 'Bar',
    category: 'Bar',
    categories: const [],
    addressLine1: '',
    addressLine2: '',
    city: '',
    postcode: '',
    country: 'UK',
    lat: 0,
    lng: 0,
    phone: '',
    website: '',
    instagram: '',
    logoUrl: logoUrl,
    coverImageUrl: coverImageUrl,
    galleryImageUrls: galleryImageUrls,
    features: const [],
    priceRange: '',
    averageRating: 0,
    reviewCount: 0,
    currentCrowdLevel: 'quiet',
    currentCrowdScore: 1,
    ownerId: 'owner-1',
    managerIds: const [],
    subscriptionPlan: 'professional',
    isVerified: false,
    isPublished: true,
    isFeatured: false,
    isDeleted: false,
    createdAt: null,
    updatedAt: null,
    crowdUpdatedAt: null,
  );
}

void main() {
  group('VenueImageResolver', () {
    test('logo prefers venue document field over current media', () {
      final venue = _venue(logoUrl: 'https://engine/logo.png');
      final media = VenueMediaModel(
        id: 'm1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.logo,
        imageUrl: 'https://media/logo.png',
        isCurrent: true,
      );

      expect(
        VenueImageResolver.resolveLogo(venue: venue, currentLogoMedia: media),
        'https://engine/logo.png',
      );
    });

    test('logo falls back to current media when venue field empty', () {
      final venue = _venue();
      final media = VenueMediaModel(
        id: 'm1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.logo,
        imageUrl: 'https://media/logo.png',
        isCurrent: true,
      );

      expect(
        VenueImageResolver.resolveLogo(venue: venue, currentLogoMedia: media),
        'https://media/logo.png',
      );
    });

    test('logo falls back to venue field when no current media', () {
      final venue = _venue(logoUrl: 'https://legacy/logo.png');

      expect(
        VenueImageResolver.resolveLogo(venue: venue),
        'https://legacy/logo.png',
      );
    });

    test('banner prefers venue document field over current media', () {
      final venue = _venue(coverImageUrl: 'https://engine/banner.png');
      final media = VenueMediaModel(
        id: 'b1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.banner,
        imageUrl: 'https://media/banner.png',
        isCurrent: true,
      );

      expect(
        VenueImageResolver.resolveBanner(venue: venue, currentBannerMedia: media),
        'https://engine/banner.png',
      );
    });

    test('banner falls back to current media when venue field empty', () {
      final venue = _venue();
      final media = VenueMediaModel(
        id: 'b1',
        venueId: 'wine-central',
        mediaType: VenueMediaType.banner,
        imageUrl: 'https://media/banner.png',
        isCurrent: true,
      );

      expect(
        VenueImageResolver.resolveBanner(venue: venue, currentBannerMedia: media),
        'https://media/banner.png',
      );
    });

    test('gallery uses visible media and excludes hidden items', () {
      final venue = _venue(galleryImageUrls: ['https://legacy/g1.jpg']);
      final galleryMedia = [
        VenueMediaModel(
          id: 'g1',
          venueId: 'wine-central',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'https://engine/g1.jpg',
          featured: true,
          sortOrder: 1,
        ),
        VenueMediaModel(
          id: 'g2',
          venueId: 'wine-central',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'https://engine/hidden.jpg',
          visible: false,
          sortOrder: 0,
        ),
      ];

      expect(
        VenueImageResolver.resolveGalleryUrls(
          venue: venue,
          galleryMedia: galleryMedia,
        ),
        ['https://engine/g1.jpg'],
      );
    });

    test('gallery falls back to venue galleryImageUrls', () {
      final venue = _venue(galleryImageUrls: ['https://legacy/g1.jpg']);

      expect(
        VenueImageResolver.resolveGalleryUrls(venue: venue, galleryMedia: const []),
        ['https://legacy/g1.jpg'],
      );
    });

    test('deal image resolves by linkedDealId', () {
      final dealMedia = [
        VenueMediaModel(
          id: 'd1',
          venueId: 'wine-central',
          mediaType: VenueMediaType.deal,
          imageUrl: 'https://engine/deal-1.jpg',
          linkedDealId: 'deal-1',
        ),
      ];

      expect(
        VenueImageResolver.dealImageUrl(dealId: 'deal-1', dealMedia: dealMedia),
        'https://engine/deal-1.jpg',
      );
      expect(
        VenueImageResolver.dealImageUrl(dealId: 'deal-2', dealMedia: dealMedia),
        isNull,
      );
    });

    test('event image prefers linked media over event.imageUrl', () {
      final event = EventModel(
        id: 'event-1',
        venueId: 'wine-central',
        title: 'Live DJ',
        description: '',
        startDateTime: DateTime(2026, 7, 1, 20),
        endDateTime: DateTime(2026, 7, 1, 23),
        createdAt: DateTime(2026, 6, 1),
        category: 'Music',
        imageUrl: 'https://legacy/event.jpg',
        isDeleted: false,
      );

      final eventMedia = [
        VenueMediaModel(
          id: 'e1',
          venueId: 'wine-central',
          mediaType: VenueMediaType.event,
          imageUrl: 'https://engine/event.jpg',
          linkedEventId: 'event-1',
        ),
      ];

      expect(
        VenueImageResolver.resolveEventImage(event: event, eventMedia: eventMedia),
        'https://engine/event.jpg',
      );
    });
  });

  group('VenueMediaBundle', () {
    test('sorts gallery featured first then sortOrder', () {
      final bundle = VenueMediaBundle.fromItems([
        VenueMediaModel(
          id: 'g2',
          venueId: 'v1',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'second',
          sortOrder: 1,
        ),
        VenueMediaModel(
          id: 'g1',
          venueId: 'v1',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'cover',
          featured: true,
          sortOrder: 5,
        ),
      ]);

      expect(bundle.galleryItems.map((item) => item.imageUrl), ['cover', 'second']);
    });
    test('venue card model reads denormalized logo and banner fields', () {
      final venue = VenueModel.fromMap('wine-central', {
        'logoUrl': 'https://engine/logo.png',
        'bannerImageUrl': 'https://engine/banner.png',
      });

      expect(venue.logoUrl, 'https://engine/logo.png');
      expect(venue.bannerImageUrl, 'https://engine/banner.png');
    });
  });
}
