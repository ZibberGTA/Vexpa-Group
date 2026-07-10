import '../../venues/models/image_position_metadata.dart';
import 'media_library_tab.dart';

/// Purpose of a venue-owned media asset.
enum VenueMediaType {
  gallery,
  deal,
  event,
  logo,
  banner,
}

extension VenueMediaTypeX on VenueMediaType {
  String get firestoreValue => name;

  String get storageFolder => switch (this) {
        VenueMediaType.gallery => 'gallery',
        VenueMediaType.deal => 'deals',
        VenueMediaType.event => 'events',
        VenueMediaType.logo => 'logo',
        VenueMediaType.banner => 'banner',
      };

  String get label => switch (this) {
        VenueMediaType.gallery => 'Gallery',
        VenueMediaType.deal => 'Deal',
        VenueMediaType.event => 'Event',
        VenueMediaType.logo => 'Logo',
        VenueMediaType.banner => 'Banner',
      };

  static VenueMediaType? fromFirestore(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final type in VenueMediaType.values) {
      if (type.firestoreValue == normalized) return type;
    }
    return null;
  }

  static VenueMediaType fromLibraryTab(MediaLibraryTab tab) {
    return switch (tab) {
      MediaLibraryTab.venueGallery => VenueMediaType.gallery,
      MediaLibraryTab.brandAssets => VenueMediaType.logo,
      MediaLibraryTab.dealImages => VenueMediaType.deal,
      MediaLibraryTab.eventImages => VenueMediaType.event,
    };
  }

  static List<VenueMediaType> mediaTypesForTab(MediaLibraryTab tab) {
    return switch (tab) {
      MediaLibraryTab.brandAssets => const [
          VenueMediaType.logo,
          VenueMediaType.banner,
        ],
      MediaLibraryTab.venueGallery => const [VenueMediaType.gallery],
      MediaLibraryTab.dealImages => const [VenueMediaType.deal],
      MediaLibraryTab.eventImages => const [VenueMediaType.event],
    };
  }

  MediaLibraryTab? get libraryTab => switch (this) {
        VenueMediaType.gallery => MediaLibraryTab.venueGallery,
        VenueMediaType.deal => MediaLibraryTab.dealImages,
        VenueMediaType.event => MediaLibraryTab.eventImages,
        VenueMediaType.logo => MediaLibraryTab.brandAssets,
        VenueMediaType.banner => MediaLibraryTab.brandAssets,
      };
}

/// Firebase Storage paths for venue-scoped media.
class VenueMediaPaths {
  VenueMediaPaths._();

  static String objectPath({
    required String venueId,
    required VenueMediaType mediaType,
    required String mediaId,
    required String extension,
  }) {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return 'venues/$venueId/media/${mediaType.storageFolder}/$mediaId$ext';
  }

  static String extensionFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) return 'jpg';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String contentTypeForExtension(String extension) {
    final ext = extension.replaceAll('.', '').toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      _ => 'image/jpeg',
    };
  }
}

/// Crop / focal metadata stored on media documents.
class VenueMediaCropMetadata {
  const VenueMediaCropMetadata({
    this.cropX = 0.5,
    this.cropY = 0.5,
    this.cropScale = 1,
    this.focalPointX = 0.5,
    this.focalPointY = 0.5,
    this.aspectRatio,
  });

  final double cropX;
  final double cropY;
  final double cropScale;
  final double focalPointX;
  final double focalPointY;
  final double? aspectRatio;

  factory VenueMediaCropMetadata.fromPosition(ImagePositionMetadata? metadata) {
    if (metadata == null) return const VenueMediaCropMetadata();
    return VenueMediaCropMetadata(
      cropX: metadata.cropX,
      cropY: metadata.cropY,
      cropScale: metadata.scale,
      focalPointX: metadata.focalPointX,
      focalPointY: metadata.focalPointY,
      aspectRatio: metadata.aspectRatio,
    );
  }

  ImagePositionMetadata toPositionMetadata() {
    return ImagePositionMetadata(
      focalPointX: focalPointX,
      focalPointY: focalPointY,
      scale: cropScale,
      cropX: cropX,
      cropY: cropY,
      aspectRatio: aspectRatio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropX': cropX,
      'cropY': cropY,
      'cropScale': cropScale,
      'focalPointX': focalPointX,
      'focalPointY': focalPointY,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
    };
  }

  factory VenueMediaCropMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const VenueMediaCropMetadata();

    double read(String key, double fallback) {
      final value = map[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return VenueMediaCropMetadata(
      cropX: read('cropX', read('focalPointX', 0.5)),
      cropY: read('cropY', read('focalPointY', 0.5)),
      cropScale: read('cropScale', read('scale', 1)).clamp(1, 4),
      focalPointX: read('focalPointX', 0.5),
      focalPointY: read('focalPointY', 0.5),
      aspectRatio: map['aspectRatio'] is num
          ? (map['aspectRatio'] as num).toDouble()
          : double.tryParse(map['aspectRatio']?.toString() ?? ''),
    );
  }
}

/// Maps branding frame kinds to unified media types.
extension ImageFrameKindMediaX on ImageFrameKind {
  VenueMediaType? get venueMediaType => switch (this) {
        ImageFrameKind.logo => VenueMediaType.logo,
        ImageFrameKind.banner => VenueMediaType.banner,
        ImageFrameKind.galleryCover => VenueMediaType.gallery,
        ImageFrameKind.eventBanner => VenueMediaType.event,
        ImageFrameKind.searchCardBanner => null,
      };
}
