import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../auth/services/user_role_service.dart';
import '../../venues/models/image_position_metadata.dart';
import '../models/media_library_tab.dart';
import '../models/media_subscription_limits.dart';
import '../models/venue_media_item.dart';
import '../models/venue_media_type.dart';
import '../services/venue_media_access_service.dart';
import 'venue_media_repository.dart';
import 'venue_media_storage_service.dart';
import 'venue_media_upload_errors.dart';

/// Orchestrates venue-scoped uploads to Storage + Firestore metadata.
class VenueMediaUploadService {
  VenueMediaUploadService({
    VenueMediaRepository? repository,
    VenueMediaStorageService? storageService,
  }) : _repository = repository ?? VenueMediaRepository(),
       _storageService = storageService ?? VenueMediaStorageService();

  static const maxFileSizeBytes = 10 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

  final VenueMediaRepository _repository;
  final VenueMediaStorageService _storageService;

  Future<List<VenueMediaItem>> uploadLibraryImages({
    required String venueId,
    required String uploadedByUid,
    required MediaLibraryTab tab,
    required List<({Uint8List bytes, String fileName})> files,
    required UserRoleProfile profile,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
    int startingSortOrder = 0,
    String subscriptionPlanId = '',
    Map<String, int> customMediaLimits = const {},
    int currentItemCount = 0,
    String category = 'other',
    String caption = '',
  }) async {
    _assertActiveVenue(venueId);
    _assertAccess(
      userId: uploadedByUid,
      venueId: venueId,
      profile: profile,
      venueOwnerId: venueOwnerId,
      accessibleVenueIds: accessibleVenueIds,
    );

    final uploadLimit = MediaSubscriptionLimits.limitFor(
      planId: subscriptionPlanId,
      tab: tab,
      customLimits: customMediaLimits,
    );
    if (!MediaSubscriptionLimits.hasMediaCentreAccess(subscriptionPlanId)) {
      throw VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.uploadLimitExceeded,
        userMessage: 'Upgrade to Professional to upload ${tab.emptyUnit}.',
        devDetails: 'subscription=$subscriptionPlanId tab=${tab.name}',
      );
    }
    if (currentItemCount + files.length > uploadLimit) {
      final remaining = (uploadLimit - currentItemCount).clamp(0, uploadLimit);
      throw VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.uploadLimitExceeded,
        userMessage: remaining == 0
            ? 'You have reached your ${tab.label.toLowerCase()} limit ($uploadLimit).'
            : 'You can only upload $remaining more ${tab.emptyUnit} on your plan.',
        devDetails:
            'limit=$uploadLimit current=$currentItemCount selected=${files.length}',
      );
    }

    final validatedFiles = _validateFiles(files);

    final mediaType = tab.mediaType;
    final uploaded = <VenueMediaItem>[];

    for (var i = 0; i < validatedFiles.length; i++) {
      final file = validatedFiles[i];
      final mediaId = VenueMediaRepository.generateId();
      final storagePath = VenueMediaPaths.objectPath(
        venueId: venueId,
        mediaType: mediaType,
        mediaId: mediaId,
        extension: file.extension,
      );
      final firestorePath = 'venues/$venueId/media/$mediaId';

      String? downloadUrl;
      try {
        final stored = await _storageService.uploadBytes(
          storagePath: storagePath,
          bytes: file.bytes,
          contentType: file.contentType,
        );
        downloadUrl = stored.downloadUrl.trim();
        if (downloadUrl.isEmpty) {
          throw VenueMediaUploadException(
            kind: VenueMediaUploadFailureKind.missingDownloadUrl,
            userMessage: 'Upload succeeded but no download URL was returned.',
            devDetails: 'storagePath=$storagePath',
          );
        }

        final item = VenueMediaItem(
          id: mediaId,
          venueId: venueId,
          mediaType: mediaType,
          imageUrl: downloadUrl,
          fileName: file.fileName,
          contentType: file.contentType,
          sizeBytes: file.bytes.length,
          uploadedByUid: uploadedByUid,
          category: category,
          caption: caption,
          status: 'active',
          visible: true,
          featured:
              tab == MediaLibraryTab.venueGallery &&
              startingSortOrder == 0 &&
              i == 0,
          sortOrder: startingSortOrder + i,
          storagePath: storagePath,
          uploadedAt: DateTime.now(),
        );

        try {
          await _repository.saveMediaItem(venueId: venueId, item: item);
        } catch (error, stackTrace) {
          await _rollbackStorage(storagePath: storagePath, error: error);
          throw _mapMetadataFailure(
            error,
            stackTrace: stackTrace,
            firestorePath: firestorePath,
          );
        }

        uploaded.add(item);
      } on VenueMediaUploadException {
        rethrow;
      } on FirebaseException catch (error, stackTrace) {
        throw VenueMediaUploadException.fromFirebase(
          error,
          stackTrace: stackTrace,
          context: 'storagePath=$storagePath',
        );
      } catch (error, stackTrace) {
        if (downloadUrl != null) {
          await _rollbackStorage(storagePath: storagePath, error: error);
        }
        throw VenueMediaUploadException.fromObject(
          error,
          stackTrace: stackTrace,
          context: 'storagePath=$storagePath firestorePath=$firestorePath',
        );
      }
    }

    if (tab == MediaLibraryTab.venueGallery && uploaded.isNotEmpty) {
      await _trySetInitialCover(venueId: venueId, tab: tab, uploaded: uploaded);
    }

    return uploaded;
  }

  Future<VenueMediaItem> replaceLibraryImage({
    required VenueMediaItem existingItem,
    required String uploadedByUid,
    required ({Uint8List bytes, String fileName}) file,
    required UserRoleProfile profile,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
    String? category,
    String? caption,
  }) async {
    _assertActiveVenue(existingItem.venueId);
    _assertAccess(
      userId: uploadedByUid,
      venueId: existingItem.venueId,
      profile: profile,
      venueOwnerId: venueOwnerId,
      accessibleVenueIds: accessibleVenueIds,
    );

    final validated = _validateFiles([file]).single;
    final storagePath = VenueMediaPaths.objectPath(
      venueId: existingItem.venueId,
      mediaType: existingItem.mediaType,
      mediaId: existingItem.id,
      extension: validated.extension,
    );
    final firestorePath =
        'venues/${existingItem.venueId}/media/${existingItem.id}';

    try {
      final stored = await _storageService.uploadBytes(
        storagePath: storagePath,
        bytes: validated.bytes,
        contentType: validated.contentType,
      );
      final downloadUrl = stored.downloadUrl.trim();
      if (downloadUrl.isEmpty) {
        throw VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.missingDownloadUrl,
          userMessage: 'Upload succeeded but no download URL was returned.',
          devDetails: 'storagePath=$storagePath',
        );
      }

      final updated = existingItem.copyWith(
        imageUrl: downloadUrl,
        thumbnailUrl: null,
        fileName: validated.fileName,
        contentType: validated.contentType,
        sizeBytes: validated.bytes.length,
        uploadedByUid: uploadedByUid,
        category: category,
        caption: caption,
        status: 'active',
        visible: true,
        storagePath: storagePath,
        updatedAt: DateTime.now(),
      );
      await _repository.saveMediaItem(
        venueId: existingItem.venueId,
        item: updated,
      );
      return updated;
    } on VenueMediaUploadException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      throw VenueMediaUploadException.fromFirebase(
        error,
        stackTrace: stackTrace,
        context: 'storagePath=$storagePath firestorePath=$firestorePath',
      );
    } catch (error, stackTrace) {
      throw VenueMediaUploadException.fromObject(
        error,
        stackTrace: stackTrace,
        context: 'storagePath=$storagePath firestorePath=$firestorePath',
      );
    }
  }

  Future<VenueMediaItem> uploadBrandingImage({
    required String venueId,
    required String uploadedByUid,
    required VenueMediaType mediaType,
    required Uint8List bytes,
    required String fileName,
    required UserRoleProfile profile,
    ImagePositionMetadata? position,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
  }) async {
    if (mediaType != VenueMediaType.logo &&
        mediaType != VenueMediaType.banner) {
      throw ArgumentError(
        'Branding upload requires logo or banner media type.',
      );
    }

    _assertActiveVenue(venueId);
    _assertAccess(
      userId: uploadedByUid,
      venueId: venueId,
      profile: profile,
      venueOwnerId: venueOwnerId,
      accessibleVenueIds: accessibleVenueIds,
    );

    final validated = _validateFiles([
      (bytes: bytes, fileName: fileName),
    ]).single;
    final mediaId = VenueMediaRepository.generateId();
    final storagePath = VenueMediaPaths.objectPath(
      venueId: venueId,
      mediaType: mediaType,
      mediaId: mediaId,
      extension: validated.extension,
    );
    final firestorePath = 'venues/$venueId/media/$mediaId';

    String? downloadUrl;
    var metadataSaved = false;
    try {
      final stored = await _storageService.uploadBytes(
        storagePath: storagePath,
        bytes: validated.bytes,
        contentType: validated.contentType,
      );
      downloadUrl = stored.downloadUrl.trim();
      if (downloadUrl.isEmpty) {
        throw VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.missingDownloadUrl,
          userMessage: 'Upload succeeded but no download URL was returned.',
          devDetails: 'storagePath=$storagePath',
        );
      }

      final item = VenueMediaItem(
        id: mediaId,
        venueId: venueId,
        mediaType: mediaType,
        imageUrl: downloadUrl,
        fileName: validated.fileName,
        contentType: validated.contentType,
        sizeBytes: validated.bytes.length,
        uploadedByUid: uploadedByUid,
        visible: true,
        isCurrent: true,
        storagePath: storagePath,
        crop: VenueMediaCropMetadata.fromPosition(position),
        uploadedAt: DateTime.now(),
      );

      try {
        await _repository.saveMediaItem(venueId: venueId, item: item);
        metadataSaved = true;

        await _repository.setCurrentBrandingMedia(
          venueId: venueId,
          mediaType: mediaType,
          mediaId: mediaId,
          imageUrl: downloadUrl,
          position: position,
        );
      } catch (error, stackTrace) {
        await _rollbackBrandingUpload(
          venueId: venueId,
          mediaId: mediaId,
          storagePath: storagePath,
          metadataSaved: metadataSaved,
          error: error,
        );
        throw _mapMetadataFailure(
          error,
          stackTrace: stackTrace,
          firestorePath: firestorePath,
        );
      }

      return item;
    } on VenueMediaUploadException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      throw VenueMediaUploadException.fromFirebase(
        error,
        stackTrace: stackTrace,
        context: 'storagePath=$storagePath',
      );
    } catch (error, stackTrace) {
      if (downloadUrl != null) {
        await _rollbackBrandingUpload(
          venueId: venueId,
          mediaId: mediaId,
          storagePath: storagePath,
          metadataSaved: metadataSaved,
          error: error,
        );
      }
      throw VenueMediaUploadException.fromObject(
        error,
        stackTrace: stackTrace,
        context: 'storagePath=$storagePath firestorePath=$firestorePath',
      );
    }
  }

  List<
    ({Uint8List bytes, String fileName, String extension, String contentType})
  >
  _validateFiles(List<({Uint8List bytes, String fileName})> files) {
    if (files.isEmpty) {
      throw VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.unknown,
        userMessage: 'No image files were selected.',
        devDetails: 'files.isEmpty',
      );
    }

    final validated =
        <
          ({
            Uint8List bytes,
            String fileName,
            String extension,
            String contentType,
          })
        >[];

    for (final file in files) {
      if (file.bytes.isEmpty) {
        throw VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.unknown,
          userMessage: 'Selected file "${file.fileName}" has no readable data.',
          devDetails: 'Empty bytes for ${file.fileName}',
        );
      }

      final extension = VenueMediaPaths.extensionFromFileName(file.fileName);
      if (!allowedExtensions.contains(extension)) {
        throw VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.unsupportedFileType,
          userMessage:
              'Unsupported file type ".$extension". Use JPG, PNG, WEBP, or GIF.',
          devDetails: 'fileName=${file.fileName} extension=$extension',
        );
      }

      if (file.bytes.length > maxFileSizeBytes) {
        final sizeMb = (file.bytes.length / (1024 * 1024)).toStringAsFixed(1);
        throw VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.fileTooLarge,
          userMessage:
              'File "${file.fileName}" is too large ($sizeMb MB). Maximum size is 10 MB.',
          devDetails: 'sizeBytes=${file.bytes.length} max=$maxFileSizeBytes',
        );
      }

      validated.add((
        bytes: file.bytes,
        fileName: file.fileName,
        extension: extension,
        contentType: VenueMediaPaths.contentTypeForExtension(extension),
      ));
    }

    return validated;
  }

  Future<void> _trySetInitialCover({
    required String venueId,
    required MediaLibraryTab tab,
    required List<VenueMediaItem> uploaded,
  }) async {
    try {
      final allGallery = await _repository
          .watchMediaItems(venueId: venueId, tab: tab)
          .first;
      if (allGallery.any((item) => item.featured)) return;

      await _repository.setCoverPhoto(
        venueId: venueId,
        itemId: uploaded.first.id,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaUpload] cover photo sync failed (upload still succeeded): $error',
        );
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _rollbackBrandingUpload({
    required String venueId,
    required String mediaId,
    required String storagePath,
    required bool metadataSaved,
    required Object? error,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[VenueMediaUpload] rollback cleanup skipped '
        'venueId=$venueId mediaId=$mediaId storagePath=$storagePath '
        'metadataSaved=$metadataSaved cause=$error',
      );
    }
  }

  Future<void> _rollbackStorage({
    required String storagePath,
    required Object? error,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[VenueMediaUpload] storage rollback delete skipped for $storagePath '
        '(cause: $error)',
      );
    }
  }

  VenueMediaUploadException _mapMetadataFailure(
    Object error, {
    StackTrace? stackTrace,
    required String firestorePath,
  }) {
    if (error is VenueMediaUploadException) return error;
    if (error is FirebaseException) {
      final mapped = VenueMediaUploadException.fromFirebase(
        error,
        stackTrace: stackTrace,
        context: 'firestorePath=$firestorePath',
      );
      if (mapped.kind ==
          VenueMediaUploadFailureKind.firestorePermissionDenied) {
        return mapped;
      }
      return VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.metadataWriteFailed,
        userMessage: 'Image uploaded but saving media metadata failed.',
        devDetails: mapped.devDetails,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return VenueMediaUploadException(
      kind: VenueMediaUploadFailureKind.metadataWriteFailed,
      userMessage: 'Image uploaded but saving media metadata failed.',
      devDetails: VenueMediaUploadException.fromObject(
        error,
        stackTrace: stackTrace,
        context: 'firestorePath=$firestorePath',
      ).devDetails,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  void _assertActiveVenue(String venueId) {
    if (venueId.trim().isEmpty) {
      throw VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.noActiveVenue,
        userMessage: 'No active venue selected. Choose a venue and try again.',
        devDetails: 'venueId is empty',
      );
    }
  }

  void _assertAccess({
    required String userId,
    required String venueId,
    required UserRoleProfile profile,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
  }) {
    if (userId.trim().isEmpty) {
      throw VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.notSignedIn,
        userMessage: 'You must be signed in to upload media.',
        devDetails: 'uploadedByUid is empty',
      );
    }

    final allowed = VenueMediaAccessService.canManageMediaForVenue(
      userId: userId,
      venueId: venueId,
      profile: profile,
      venueOwnerId: venueOwnerId,
      accessibleVenueIds: accessibleVenueIds,
    );
    if (!allowed) {
      throw VenueMediaAccessDeniedException(
        'You do not have permission to manage media for this venue.',
      );
    }
  }
}
