import '../../venues/models/image_position_metadata.dart';
import '../models/venue_media_item.dart';
import '../models/venue_media_type.dart';

/// Optional helpers for creating media metadata from legacy URL fields.
class VenueMediaMigrationHelper {
  VenueMediaMigrationHelper._();

  static List<VenueMediaItem> legacyGalleryItems({
    required String venueId,
    required List<String> urls,
    Map<String, ImagePositionMetadata> positions = const {},
  }) {
    final items = <VenueMediaItem>[];
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i].trim();
      if (url.isEmpty) continue;
      final id = 'legacy-$i';
      items.add(
        VenueMediaItem(
          id: id,
          venueId: venueId,
          mediaType: VenueMediaType.gallery,
          imageUrl: url,
          sortOrder: i,
          featured: i == 0,
          fileName: 'Gallery photo ${i + 1}',
          crop: VenueMediaCropMetadata.fromPosition(
            positions['$i'] ?? positions[id] ?? positions[url],
          ),
          isLegacy: true,
        ),
      );
    }
    return items;
  }

  /// Builds a media metadata map from an existing URL without uploading storage.
  static Map<String, dynamic> metadataFromExistingUrl({
    required String venueId,
    required String mediaId,
    required VenueMediaType mediaType,
    required String imageUrl,
    String fileName = '',
    ImagePositionMetadata? position,
    bool featured = false,
    int sortOrder = 0,
  }) {
    final item = VenueMediaItem(
      id: mediaId,
      venueId: venueId,
      mediaType: mediaType,
      imageUrl: imageUrl,
      fileName: fileName,
      featured: featured,
      sortOrder: sortOrder,
      crop: VenueMediaCropMetadata.fromPosition(position),
      uploadedAt: DateTime.now(),
    );
    return item.toMap();
  }
}
