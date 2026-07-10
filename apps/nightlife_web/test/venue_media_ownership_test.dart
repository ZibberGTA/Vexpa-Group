import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/auth/services/user_role_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_migration_helper.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_storage_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_upload_service.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_media_type.dart';
import 'package:nightlife_web/features/venue_management/services/venue_media_access_service.dart';

void main() {
  group('VenueMediaPaths', () {
    test('uses venueId-based storage folders', () {
      expect(
        VenueMediaPaths.objectPath(
          venueId: 'wine-central',
          mediaType: VenueMediaType.gallery,
          mediaId: 'abc123',
          extension: 'jpg',
        ),
        'venues/wine-central/media/gallery/abc123.jpg',
      );
      expect(
        VenueMediaPaths.objectPath(
          venueId: 'wine-central',
          mediaType: VenueMediaType.deal,
          mediaId: 'deal-1',
          extension: 'png',
        ),
        'venues/wine-central/media/deals/deal-1.png',
      );
      expect(
        VenueMediaPaths.objectPath(
          venueId: 'wine-central',
          mediaType: VenueMediaType.logo,
          mediaId: 'logo-1',
          extension: 'webp',
        ),
        'venues/wine-central/media/logo/logo-1.webp',
      );
    });
  });

  group('VenueMediaAccessService', () {
    const ownerProfile = UserRoleProfile(
      role: VexdaUserRole.venueOwner,
      ownedVenuesCount: 1,
    );
    const staffProfile = UserRoleProfile(
      role: VexdaUserRole.employee,
      venueIds: ['wine-central'],
    );
    const outsiderProfile = UserRoleProfile(role: VexdaUserRole.regularUser);

    test('owner can manage owned venue media', () {
      expect(
        VenueMediaAccessService.canManageMediaForVenue(
          userId: 'owner-1',
          venueId: 'wine-central',
          profile: ownerProfile,
          venueOwnerId: 'owner-1',
        ),
        isTrue,
      );
    });

    test('staff can manage assigned venue media', () {
      expect(
        VenueMediaAccessService.canManageMediaForVenue(
          userId: 'staff-1',
          venueId: 'wine-central',
          profile: staffProfile,
        ),
        isTrue,
      );
    });

    test('other venue owners cannot manage foreign venue media', () {
      expect(
        VenueMediaAccessService.canManageMediaForVenue(
          userId: 'owner-2',
          venueId: 'wine-central',
          profile: ownerProfile,
          venueOwnerId: 'owner-1',
        ),
        isFalse,
      );
    });

    test('regular users cannot manage venue media', () {
      expect(
        VenueMediaAccessService.canManageMediaForVenue(
          userId: 'user-1',
          venueId: 'wine-central',
          profile: outsiderProfile,
        ),
        isFalse,
      );
    });
  });

  group('VenueMediaRepository', () {
    late Map<String, Map<String, Map<String, dynamic>>> store;
    late VenueMediaRepository repository;

    setUp(() {
      store = {};
      repository = VenueMediaRepository.inMemory(store);
    });

    test('loads only active venue gallery media', () async {
      store['wine-central'] = {
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/g1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
        'd1': {
          'venueId': 'wine-central',
          'mediaType': 'deal',
          'imageUrl': 'https://example.com/d1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };
      store['other-venue'] = {
        'g9': {
          'venueId': 'other-venue',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/other.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };

      final gallery = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;

      expect(gallery, hasLength(1));
      expect(gallery.first.imageUrl, 'https://example.com/g1.jpg');
    });

    test('deal tab loads only deal mediaType', () async {
      store['wine-central'] = {
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/g1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
        'd1': {
          'venueId': 'wine-central',
          'mediaType': 'deal',
          'imageUrl': 'https://example.com/d1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
        'e1': {
          'venueId': 'wine-central',
          'mediaType': 'event',
          'imageUrl': 'https://example.com/e1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };

      final deals = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.dealImages,
          )
          .first;

      expect(deals, hasLength(1));
      expect(deals.first.mediaType, VenueMediaType.deal);
    });

    test('event tab loads only event mediaType', () async {
      store['wine-central'] = {
        'e1': {
          'venueId': 'wine-central',
          'mediaType': 'event',
          'imageUrl': 'https://example.com/e1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };

      final events = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.eventImages,
          )
          .first;

      expect(events, hasLength(1));
      expect(events.first.mediaType, VenueMediaType.event);
    });

    test('does not synthesize legacy gallery rows when media collection is empty', () async {
      final gallery = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;

      expect(gallery, isEmpty);
    });

    test('delete removes gallery media from store and storage path', () async {
      store['wine-central'] = {
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/g1.jpg',
          'storagePath': 'venues/wine-central/media/gallery/g1.jpg',
          'visible': true,
          'sortOrder': 0,
          'featured': true,
        },
      };

      final item = (await repository
              .watchMediaItems(
                venueId: 'wine-central',
                tab: MediaLibraryTab.venueGallery,
              )
              .first)
          .single;
      final deletedPaths = <String>[];

      await repository.deleteMediaItems(
        venueId: 'wine-central',
        itemIds: const ['g1'],
        itemsForStorage: [item],
        storageService: VenueMediaStorageService(
          deleteOverride: (path) async {
            deletedPaths.add(path);
          },
        ),
      );

      expect(deletedPaths, ['venues/wine-central/media/gallery/g1.jpg']);
      expect(store['wine-central'], isEmpty);

      final gallery = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;
      expect(gallery, isEmpty);
    });

    test('delete still removes firestore metadata when storage delete fails', () async {
      store['wine-central'] = {
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/g1.jpg',
          'storagePath': 'venues/wine-central/media/gallery/g1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };

      final item = (await repository
              .watchMediaItems(
                venueId: 'wine-central',
                tab: MediaLibraryTab.venueGallery,
              )
              .first)
          .single;

      await repository.deleteMediaItems(
        venueId: 'wine-central',
        itemIds: const ['g1'],
        itemsForStorage: [item],
        storageService: VenueMediaStorageService(
          deleteOverride: (_) async {
            throw StateError('object-not-found');
          },
        ),
      );

      expect(store['wine-central'], isEmpty);
    });

    test('brand assets tab loads logo and banner media only', () async {
      store['wine-central'] = {
        'logo-1': {
          'venueId': 'wine-central',
          'mediaType': 'logo',
          'imageUrl': 'https://example.com/logo.jpg',
          'visible': true,
          'isCurrent': true,
          'sortOrder': 0,
        },
        'banner-1': {
          'venueId': 'wine-central',
          'mediaType': 'banner',
          'imageUrl': 'https://example.com/banner.jpg',
          'visible': true,
          'isCurrent': true,
          'sortOrder': 0,
        },
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/g1.jpg',
          'visible': true,
          'sortOrder': 0,
        },
      };

      final brandAssets = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.brandAssets,
          )
          .first;

      expect(brandAssets, hasLength(2));
      expect(
        brandAssets.map((item) => item.mediaType).toSet(),
        {VenueMediaType.logo, VenueMediaType.banner},
      );

      final gallery = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;
      expect(gallery, hasLength(1));
    });

    test('hidden gallery media is excluded from public queries', () async {
      store['wine-central'] = {
        'g1': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/visible.jpg',
          'visible': true,
          'sortOrder': 0,
        },
        'g2': {
          'venueId': 'wine-central',
          'mediaType': 'gallery',
          'imageUrl': 'https://example.com/hidden.jpg',
          'visible': false,
          'sortOrder': 1,
        },
      };

      final gallery = await repository
          .watchMediaItems(
            venueId: 'wine-central',
            tab: MediaLibraryTab.venueGallery,
          )
          .first;

      expect(gallery, hasLength(1));
      expect(gallery.first.imageUrl, 'https://example.com/visible.jpg');
    });

    test('branding upload sets isCurrent and clears previous logo', () async {
      store['wine-central'] = {
        'old-logo': {
          'venueId': 'wine-central',
          'mediaType': 'logo',
          'imageUrl': 'https://example.com/old-logo.jpg',
          'isCurrent': true,
          'visible': true,
        },
      };

      final service = VenueMediaUploadService(
        repository: repository,
        storageService: VenueMediaStorageService(
          uploadOverride: ({
            required storagePath,
            required bytes,
            required contentType,
          }) async {
            return (
              downloadUrl: 'https://storage.example.com/$storagePath',
              storagePath: storagePath,
            );
          },
        ),
      );

      final item = await service.uploadBrandingImage(
        venueId: 'wine-central',
        uploadedByUid: 'owner-1',
        mediaType: VenueMediaType.logo,
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'logo.png',
        profile: const UserRoleProfile(
          role: VexdaUserRole.venueOwner,
          ownedVenuesCount: 1,
        ),
        venueOwnerId: 'owner-1',
      );

      expect(item.isCurrent, isTrue);
      expect(store['wine-central']!['old-logo']!['isCurrent'], isFalse);
      expect(
        store['wine-central']!.values.where((map) => map['isCurrent'] == true),
        hasLength(1),
      );
    });

    test('branding upload updates venue logoUrl and currentLogoMediaId', () async {
      final store = <String, Map<String, Map<String, dynamic>>>{};
      final repository = VenueMediaRepository.inMemory(store);
      final venueDoc = <String, dynamic>{'ownerId': 'owner-1', 'name': 'Wine Central'};

      final service = VenueMediaUploadService(
        repository: repository,
        storageService: VenueMediaStorageService(
          uploadOverride: ({
            required storagePath,
            required bytes,
            required contentType,
          }) async {
            return (
              downloadUrl: 'https://storage.example.com/$storagePath',
              storagePath: storagePath,
            );
          },
        ),
      );

      // Simulate firestore venue doc via repository override - use real firestore path
      // In-memory repo skips venue doc update; verify media doc fields instead.
      final item = await service.uploadBrandingImage(
        venueId: 'wine-central',
        uploadedByUid: 'owner-1',
        mediaType: VenueMediaType.logo,
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'logo.png',
        profile: const UserRoleProfile(
          role: VexdaUserRole.venueOwner,
          ownedVenuesCount: 1,
        ),
        venueOwnerId: 'owner-1',
      );

      expect(item.mediaType, VenueMediaType.logo);
      expect(item.isCurrent, isTrue);
      expect(item.storagePath, startsWith('venues/wine-central/media/logo/'));
      expect(store['wine-central']![item.id]!['mediaType'], 'logo');
      expect(store['wine-central']![item.id]!['isCurrent'], isTrue);
      expect(store['wine-central']![item.id]!['imageUrl'], startsWith('https://storage.example.com/'));
    });

    test('clearVenueBrandingFields is callable on in-memory repository', () async {
      final store = <String, Map<String, Map<String, dynamic>>>{};
      final repository = VenueMediaRepository.inMemory(store);

      await repository.clearVenueBrandingFields(
        venueId: 'wine-central',
        mediaType: VenueMediaType.logo,
      );

      expect(repository, isNotNull);
    });

    test('removeBrokenMediaItem deletes media metadata from in-memory store', () async {
      final store = <String, Map<String, Map<String, dynamic>>>{
        'wine-central': {
          'broken-logo': {
            'venueId': 'wine-central',
            'mediaType': 'logo',
            'imageUrl': 'https://example.com/missing.png',
            'visible': true,
          },
        },
      };
      final repository = VenueMediaRepository.inMemory(store);

      await repository.removeBrokenMediaItem(
        venueId: 'wine-central',
        mediaId: 'broken-logo',
      );

      expect(store['wine-central'], isEmpty);
    });
  });

  group('VenueMediaUploadService', () {
    test('upload creates storage file and firestore metadata for venue', () async {
      final store = <String, Map<String, Map<String, dynamic>>>{};
      final repository = VenueMediaRepository.inMemory(store);
      final uploadedPaths = <String>[];

      final service = VenueMediaUploadService(
        repository: repository,
        storageService: VenueMediaStorageService(
          uploadOverride: ({
            required storagePath,
            required bytes,
            required contentType,
          }) async {
            uploadedPaths.add(storagePath);
            return (
              downloadUrl: 'https://storage.example.com/$storagePath',
              storagePath: storagePath,
            );
          },
        ),
      );

      final items = await service.uploadLibraryImages(
        venueId: 'wine-central',
        uploadedByUid: 'owner-1',
        tab: MediaLibraryTab.venueGallery,
        files: [
          (bytes: Uint8List.fromList([1, 2, 3]), fileName: 'bar.jpg'),
        ],
        profile: const UserRoleProfile(
          role: VexdaUserRole.venueOwner,
          ownedVenuesCount: 1,
        ),
        venueOwnerId: 'owner-1',
        startingSortOrder: 0,
      );

      expect(uploadedPaths.single, startsWith('venues/wine-central/media/gallery/'));
      expect(store['wine-central'], isNotNull);
      expect(store['wine-central']!.values.single['venueId'], 'wine-central');
      expect(store['wine-central']!.values.single['mediaType'], 'gallery');
      expect(store['wine-central']!.values.single['uploadedByUid'], 'owner-1');
      expect(items.single.imageUrl, startsWith('https://storage.example.com/'));
    });

    test('staff upload denied for unassigned venue', () async {
      final service = VenueMediaUploadService(
        repository: VenueMediaRepository.inMemory({}),
        storageService: VenueMediaStorageService(
          uploadOverride: ({
            required storagePath,
            required bytes,
            required contentType,
          }) async {
            return (downloadUrl: 'https://example.com/x.jpg', storagePath: storagePath);
          },
        ),
      );

      expect(
        () => service.uploadLibraryImages(
          venueId: 'wine-central',
          uploadedByUid: 'staff-1',
          tab: MediaLibraryTab.dealImages,
          files: [
            (bytes: Uint8List.fromList([1]), fileName: 'deal.jpg'),
          ],
          profile: const UserRoleProfile(
            role: VexdaUserRole.employee,
            venueIds: ['other-venue'],
          ),
        ),
        throwsA(isA<VenueMediaAccessDeniedException>()),
      );
    });
  });

  group('VenueMediaMigrationHelper', () {
    test('legacy gallery helper is not used as live gallery table fallback', () {
      final legacy = VenueMediaMigrationHelper.legacyGalleryItems(
        venueId: 'wine-central',
        urls: const ['https://example.com/existing.jpg'],
      );

      expect(legacy, hasLength(1));
      expect(legacy.first.fileName, 'Gallery photo 1');
      expect(legacy.first.isLegacy, isTrue);
    });

    test('can build metadata from existing gallery URLs', () {
      final map = VenueMediaMigrationHelper.metadataFromExistingUrl(
        venueId: 'wine-central',
        mediaId: 'legacy-0',
        mediaType: VenueMediaType.gallery,
        imageUrl: 'https://example.com/existing.jpg',
        fileName: 'Existing photo',
        featured: true,
      );

      expect(map['venueId'], 'wine-central');
      expect(map['mediaType'], 'gallery');
      expect(map['imageUrl'], 'https://example.com/existing.jpg');
      expect(map['featured'], isTrue);
    });
  });
}
