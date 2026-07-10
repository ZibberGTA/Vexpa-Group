import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venues/models/image_position_metadata.dart';
import '../models/media_library_tab.dart';
import '../models/venue_media_item.dart';
import '../models/venue_media_type.dart';
import 'venue_media_storage_service.dart';

/// Reads and writes venue-owned media under venues/{venueId}/media/{mediaId}.
class VenueMediaRepository {
  VenueMediaRepository({
    FirebaseFirestore? firestore,
    this._inMemoryStore,
    VenueMediaStorageService? storageService,
  }) : _firestoreOverride = firestore;

  static const mediaCollection = 'media';

  final FirebaseFirestore? _firestoreOverride;
  final Map<String, Map<String, Map<String, dynamic>>>? _inMemoryStore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (_inMemoryStore != null) return null;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> _mediaCollection(String venueId) {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }
    return firestore
        .collection('venues')
        .doc(venueId)
        .collection(mediaCollection);
  }

  /// Watches media for [venueId] filtered to [tab]. Other venues are never loaded.
  Stream<List<VenueMediaItem>> watchMediaItems({
    required String venueId,
    required MediaLibraryTab tab,
  }) {
    if (_inMemoryStore != null) {
      return Stream.value(_queryInMemory(venueId: venueId, tab: tab));
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return Stream.value(const <VenueMediaItem>[]);
    }

    return firestore
        .collection('venues')
        .doc(venueId)
        .collection(mediaCollection)
        .snapshots()
        .asyncMap((snapshot) async {
          final allowedTypes = VenueMediaTypeX.mediaTypesForTab(tab);
          final items = snapshot.docs
              .map((doc) => VenueMediaItem.fromMap(id: doc.id, map: doc.data()))
              .where(
                (item) =>
                    item.venueId == venueId &&
                    allowedTypes.contains(item.mediaType) &&
                    item.isActive,
              )
              .toList();
          _sortMediaItems(items, tab: tab);

          return items;
        });
  }

  /// Clears venue document logo/banner URL fields when Storage files are missing.
  Future<void> clearVenueBrandingFields({
    required String venueId,
    required VenueMediaType mediaType,
  }) => _clearVenueBranding(venueId: venueId, mediaType: mediaType);

  /// Removes broken logo/banner media metadata so Brand Assets does not show stale rows.
  Future<void> removeBrokenMediaItem({
    required String venueId,
    required String mediaId,
  }) async {
    if (_inMemoryStore != null) {
      _inMemoryStore[venueId]?.remove(mediaId);
      return;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) return;

    await _mediaCollection(venueId).doc(mediaId).delete();
  }

  List<VenueMediaItem> _queryInMemory({
    required String venueId,
    required MediaLibraryTab tab,
  }) {
    final store = _inMemoryStore![venueId] ?? const {};
    final allowedTypes = VenueMediaTypeX.mediaTypesForTab(tab);
    final items = store.entries
        .map((entry) => VenueMediaItem.fromMap(id: entry.key, map: entry.value))
        .where(
          (item) =>
              item.venueId == venueId &&
              allowedTypes.contains(item.mediaType) &&
              item.isActive,
        )
        .toList();
    _sortMediaItems(items, tab: tab);
    return items;
  }

  Future<void> saveMediaItem({
    required String venueId,
    required VenueMediaItem item,
  }) async {
    if (_inMemoryStore != null) {
      _inMemoryStore.putIfAbsent(venueId, () => {})[item.id] = item.toMap();
      if (item.mediaType == VenueMediaType.gallery && item.visible) {
        await _syncGalleryImageUrlsFromStore(venueId);
      }
      return;
    }

    await _mediaCollection(
      venueId,
    ).doc(item.id).set(item.toMap(), SetOptions(merge: true));

    if (item.mediaType == VenueMediaType.gallery && item.visible) {
      await _syncGalleryImageUrlsBestEffort(venueId);
    }
  }

  Future<void> _syncGalleryImageUrlsBestEffort(String venueId) async {
    try {
      await _syncGalleryImageUrls(
        venueId: venueId,
        items: await _loadGalleryItems(venueId),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaRepository] galleryImageUrls sync failed (metadata saved): $error',
        );
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _syncGalleryImageUrlsFromStore(String venueId) async {
    final items = _queryInMemory(
      venueId: venueId,
      tab: MediaLibraryTab.venueGallery,
    );
    if (_inMemoryStore == null || _resolveFirestore() == null) return;
    await _syncGalleryImageUrls(venueId: venueId, items: items);
  }

  Future<void> deleteMediaItems({
    required String venueId,
    required Iterable<String> itemIds,
    Iterable<VenueMediaItem> itemsForStorage = const [],
    VenueMediaStorageService? storageService,
  }) async {
    final ids = itemIds.toList();
    if (ids.isEmpty) return;

    final items = itemsForStorage.toList();
    final deletesGallery = items.any(
      (item) => item.mediaType == VenueMediaType.gallery,
    );
    final deletedCurrentBranding = items
        .where(
          (item) =>
              item.isCurrent &&
              (item.mediaType == VenueMediaType.logo ||
                  item.mediaType == VenueMediaType.banner),
        )
        .toList();

    if (_inMemoryStore != null) {
      final venueStore = _inMemoryStore[venueId];
      if (venueStore != null) {
        for (final id in ids) {
          final existing = venueStore[id];
          if (existing == null) continue;
          venueStore[id] = {
            ...existing,
            'visible': false,
            'status': 'deleted',
            'updatedAt': Timestamp.now(),
          };
        }
      }
      if (deletesGallery) {
        await _syncGalleryImageUrlsFromStore(venueId);
      }
      for (final item in deletedCurrentBranding) {
        await _reconcileBrandingAfterDelete(
          venueId: venueId,
          mediaType: item.mediaType,
        );
      }
      return;
    }

    final batch = _resolveFirestore()!.batch();
    for (final id in ids) {
      batch.set(_mediaCollection(venueId).doc(id), {
        'visible': false,
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();

    if (deletesGallery) {
      await _syncGalleryImageUrls(
        venueId: venueId,
        items: await _loadGalleryItems(venueId),
      );
    }
    for (final item in deletedCurrentBranding) {
      await _reconcileBrandingAfterDelete(
        venueId: venueId,
        mediaType: item.mediaType,
      );
    }
  }

  Future<void> _reconcileBrandingAfterDelete({
    required String venueId,
    required VenueMediaType mediaType,
  }) async {
    final remaining = await _loadBrandingMedia(venueId, mediaType);
    remaining.sort((a, b) {
      final aTime = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    if (remaining.isEmpty) {
      await _clearVenueBranding(venueId: venueId, mediaType: mediaType);
      return;
    }

    final next = remaining.first;
    await setCurrentBrandingMedia(
      venueId: venueId,
      mediaType: mediaType,
      mediaId: next.id,
      imageUrl: next.imageUrl,
      position: next.position,
    );
  }

  Future<void> _clearVenueBranding({
    required String venueId,
    required VenueMediaType mediaType,
  }) async {
    if (mediaType != VenueMediaType.logo &&
        mediaType != VenueMediaType.banner) {
      return;
    }

    final payload = switch (mediaType) {
      VenueMediaType.logo => {
        'logoUrl': '',
        'logoImageUrl': '',
        'currentLogoMediaId': FieldValue.delete(),
      },
      VenueMediaType.banner => {
        'bannerImageUrl': '',
        'bannerUrl': '',
        'coverImageUrl': '',
        'currentBannerMediaId': FieldValue.delete(),
      },
      _ => const <String, dynamic>{},
    };

    if (_inMemoryStore != null || _resolveFirestore() == null) return;

    await _resolveFirestore()!.collection('venues').doc(venueId).set({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCoverPhoto({
    required String venueId,
    required String itemId,
  }) async {
    final items = await _loadGalleryItems(venueId);
    final updated = items
        .map((item) => item.copyWith(featured: item.id == itemId))
        .toList();

    if (_inMemoryStore != null) {
      for (final item in updated) {
        await saveMediaItem(venueId: venueId, item: item);
      }
    } else {
      final batch = _resolveFirestore()!.batch();
      for (final item in updated) {
        batch.set(_mediaCollection(venueId).doc(item.id), {
          'featured': item.featured,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    await _syncGalleryImageUrls(venueId: venueId, items: updated);
  }

  Future<List<VenueMediaItem>> _loadGalleryItems(String venueId) async {
    if (_inMemoryStore != null) {
      return _queryInMemory(
        venueId: venueId,
        tab: MediaLibraryTab.venueGallery,
      );
    }

    final snapshot = await _mediaCollection(venueId).get();
    return snapshot.docs
        .map((doc) => VenueMediaItem.fromMap(id: doc.id, map: doc.data()))
        .where(
          (item) => item.mediaType == VenueMediaType.gallery && item.isActive,
        )
        .toList()
      ..sort(_compareMediaItems);
  }

  static void _sortMediaItems(
    List<VenueMediaItem> items, {
    MediaLibraryTab? tab,
  }) {
    if (tab == MediaLibraryTab.brandAssets) {
      items.sort(_compareBrandMediaItems);
      return;
    }
    items.sort(_compareMediaItems);
  }

  static int _compareBrandMediaItems(VenueMediaItem a, VenueMediaItem b) {
    if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
    if (a.mediaType != b.mediaType) {
      return a.mediaType == VenueMediaType.logo ? -1 : 1;
    }
    final aTime = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  static int _compareMediaItems(VenueMediaItem a, VenueMediaItem b) {
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    final aTime = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aTime.compareTo(bTime);
  }

  Future<void> _syncGalleryImageUrls({
    required String venueId,
    required List<VenueMediaItem> items,
  }) async {
    final cover = items.where((item) => item.featured).firstOrNull;
    final urls = items
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .map((item) => item.imageUrl)
        .toList();

    if (cover != null && urls.contains(cover.imageUrl)) {
      urls.remove(cover.imageUrl);
      urls.insert(0, cover.imageUrl);
    }

    final galleryImages = items
        .where((item) => item.imageUrl.trim().isNotEmpty && item.isActive)
        .map(
          (item) => {
            'imageId': item.id,
            'imageUrl': item.imageUrl,
            'thumbnailUrl': item.thumbnailUrl ?? item.imageUrl,
            'category': item.category,
            'caption': item.caption,
            'isCover': item.featured,
            'sortOrder': item.sortOrder,
            'status': item.status,
          },
        )
        .toList();

    if (_inMemoryStore != null || _resolveFirestore() == null) return;

    await _resolveFirestore()!.collection('venues').doc(venueId).set({
      'galleryImageUrls': urls,
      'galleryImages': galleryImages,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveItemPosition({
    required String venueId,
    required MediaLibraryTab tab,
    required String itemId,
    required ImagePositionMetadata metadata,
    String? galleryIndexKey,
  }) async {
    final crop = VenueMediaCropMetadata.fromPosition(metadata);

    if (_inMemoryStore != null) {
      final existing = _inMemoryStore[venueId]?[itemId];
      if (existing != null) {
        final item = VenueMediaItem.fromMap(
          id: itemId,
          map: existing,
        ).copyWith(crop: crop);
        await saveMediaItem(venueId: venueId, item: item);
      }
    } else {
      await _mediaCollection(
        venueId,
      ).doc(itemId).set(crop.toMap(), SetOptions(merge: true));
    }

    if (tab == MediaLibraryTab.venueGallery) {
      final key = galleryIndexKey ?? itemId;
      final firestore = _resolveFirestore();
      if (firestore != null) {
        await firestore.collection('venues').doc(venueId).set({
          'galleryImagePositions': {key: metadata.toMap()},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> updateSortOrder({
    required String venueId,
    required MediaLibraryTab tab,
    required List<VenueMediaItem> orderedItems,
  }) async {
    if (_inMemoryStore != null) {
      for (var i = 0; i < orderedItems.length; i++) {
        final item = orderedItems[i].copyWith(sortOrder: i);
        await saveMediaItem(venueId: venueId, item: item);
      }
      return;
    }

    final batch = _resolveFirestore()!.batch();
    for (var i = 0; i < orderedItems.length; i++) {
      batch.set(_mediaCollection(venueId).doc(orderedItems[i].id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();

    if (tab == MediaLibraryTab.venueGallery) {
      await _syncGalleryImageUrls(venueId: venueId, items: orderedItems);
    }
  }

  Future<void> setCurrentBrandingMedia({
    required String venueId,
    required VenueMediaType mediaType,
    required String mediaId,
    required String imageUrl,
    ImagePositionMetadata? position,
  }) async {
    if (mediaType != VenueMediaType.logo &&
        mediaType != VenueMediaType.banner) {
      return;
    }

    final existing = await _loadBrandingMedia(venueId, mediaType);
    if (_inMemoryStore != null) {
      for (final item in existing) {
        if (item.id == mediaId) continue;
        final updated = item.copyWith(isCurrent: false);
        _inMemoryStore[venueId]![item.id] = updated.toMap();
      }
      final current = existing.where((item) => item.id == mediaId).firstOrNull;
      if (current != null) {
        _inMemoryStore[venueId]![mediaId] = current
            .copyWith(isCurrent: true)
            .toMap();
      }
    } else {
      final batch = _resolveFirestore()!.batch();
      for (final item in existing) {
        batch.set(_mediaCollection(venueId).doc(item.id), {
          'isCurrent': item.id == mediaId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    await updateVenueBrandingUrl(
      venueId: venueId,
      mediaType: mediaType,
      imageUrl: imageUrl,
      mediaId: mediaId,
      position: position,
    );
  }

  Future<List<VenueMediaItem>> _loadBrandingMedia(
    String venueId,
    VenueMediaType mediaType,
  ) async {
    if (_inMemoryStore != null) {
      final store = _inMemoryStore[venueId] ?? const {};
      return store.entries
          .map((e) => VenueMediaItem.fromMap(id: e.key, map: e.value))
          .where((item) => item.mediaType == mediaType)
          .toList();
    }

    final snapshot = await _mediaCollection(venueId).get();
    return snapshot.docs
        .map((doc) => VenueMediaItem.fromMap(id: doc.id, map: doc.data()))
        .where((item) => item.mediaType == mediaType)
        .toList();
  }

  Future<void> saveBrandingCrop({
    required String venueId,
    required String mediaId,
    required ImagePositionMetadata metadata,
  }) async {
    final crop = VenueMediaCropMetadata.fromPosition(metadata);

    if (_inMemoryStore != null) {
      final existing = _inMemoryStore[venueId]?[mediaId];
      if (existing != null) {
        final item = VenueMediaItem.fromMap(
          id: mediaId,
          map: existing,
        ).copyWith(crop: crop);
        await saveMediaItem(venueId: venueId, item: item);
      }
      return;
    }

    await _mediaCollection(
      venueId,
    ).doc(mediaId).set(crop.toMap(), SetOptions(merge: true));
  }

  Future<void> updateVenueBrandingUrl({
    required String venueId,
    required VenueMediaType mediaType,
    required String imageUrl,
    String? mediaId,
    ImagePositionMetadata? position,
  }) async {
    if (mediaType != VenueMediaType.logo &&
        mediaType != VenueMediaType.banner) {
      return;
    }

    final fieldName = mediaType == VenueMediaType.logo
        ? 'logoUrl'
        : 'bannerImageUrl';
    final positionField = mediaType == VenueMediaType.logo
        ? 'logoImagePosition'
        : 'bannerImagePosition';
    final mediaIdField = mediaType == VenueMediaType.logo
        ? 'currentLogoMediaId'
        : 'currentBannerMediaId';

    final payload = {
      fieldName: imageUrl,
      if (mediaType == VenueMediaType.logo) ...{'logoImageUrl': imageUrl},
      if (mediaType == VenueMediaType.banner) ...{
        'bannerUrl': imageUrl,
        'coverImageUrl': imageUrl,
      },
      if (mediaId != null && mediaId.isNotEmpty) mediaIdField: mediaId,
      if (position != null) positionField: position.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_inMemoryStore != null) return;

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available for venue branding update.');
    }

    await firestore
        .collection('venues')
        .doc(venueId)
        .set(payload, SetOptions(merge: true));
  }

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String relativeTimeLabel(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  static String exportCsv(List<VenueMediaItem> items) {
    final buffer = StringBuffer('Name,URL,Cover,Uploaded\n');
    for (final item in items) {
      buffer.writeln(
        '"${item.displayName.replaceAll('"', '""')}",'
        '"${item.imageUrl.replaceAll('"', '""')}",'
        '${item.isCover ? 'Yes' : 'No'},'
        '${item.uploadedAt?.toIso8601String() ?? ''}',
      );
    }
    return buffer.toString();
  }

  @visibleForTesting
  static VenueMediaRepository inMemory(
    Map<String, Map<String, Map<String, dynamic>>> store,
  ) {
    return VenueMediaRepository(inMemoryStore: store);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
