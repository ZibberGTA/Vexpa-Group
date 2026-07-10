/// Frame types used by venue image reposition tools.
enum ImageFrameKind {
  logo,
  banner,
  galleryCover,
  eventBanner,
  searchCardBanner,
}

extension ImageFrameKindX on ImageFrameKind {
  /// Target aspect ratio (width / height) for the preview frame.
  double get aspectRatio => switch (this) {
    ImageFrameKind.logo => 1,
    ImageFrameKind.banner => 2.85,
    ImageFrameKind.galleryCover => 1.35,
    ImageFrameKind.eventBanner => 2.4,
    ImageFrameKind.searchCardBanner => 4.8,
  };

  bool get isCircular => this == ImageFrameKind.logo;

  String get firestoreKey => switch (this) {
    ImageFrameKind.logo => 'logoImagePosition',
    ImageFrameKind.banner => 'bannerImagePosition',
    ImageFrameKind.galleryCover => 'galleryCoverImagePosition',
    ImageFrameKind.eventBanner => 'eventBannerImagePosition',
    ImageFrameKind.searchCardBanner => 'searchCardBannerImagePosition',
  };

  String get label => switch (this) {
    ImageFrameKind.logo => 'Logo',
    ImageFrameKind.banner => 'Banner',
    ImageFrameKind.galleryCover => 'Gallery cover',
    ImageFrameKind.eventBanner => 'Event banner',
    ImageFrameKind.searchCardBanner => 'Search card banner',
  };
}

/// Crop / focal-point metadata stored alongside the original image URL.
final class ImagePositionMetadata {
  const ImagePositionMetadata({
    this.focalPointX = 0.5,
    this.focalPointY = 0.5,
    this.scale = 1,
    this.cropX = 0.5,
    this.cropY = 0.5,
    this.aspectRatio,
  });

  final double focalPointX;
  final double focalPointY;
  final double scale;
  final double cropX;
  final double cropY;
  final double? aspectRatio;

  static const defaults = ImagePositionMetadata();

  ImagePositionMetadata copyWith({
    double? focalPointX,
    double? focalPointY,
    double? scale,
    double? cropX,
    double? cropY,
    double? aspectRatio,
  }) {
    return ImagePositionMetadata(
      focalPointX: focalPointX ?? this.focalPointX,
      focalPointY: focalPointY ?? this.focalPointY,
      scale: scale ?? this.scale,
      cropX: cropX ?? this.cropX,
      cropY: cropY ?? this.cropY,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'focalPointX': focalPointX,
      'focalPointY': focalPointY,
      'scale': scale,
      'cropX': cropX,
      'cropY': cropY,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
    };
  }

  factory ImagePositionMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return defaults;

    double readDouble(String key, double fallback) {
      final value = map[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return ImagePositionMetadata(
      focalPointX: readDouble('focalPointX', 0.5),
      focalPointY: readDouble('focalPointY', 0.5),
      scale: readDouble('scale', 1).clamp(1, 4),
      cropX: readDouble('cropX', readDouble('focalPointX', 0.5)),
      cropY: readDouble('cropY', readDouble('focalPointY', 0.5)),
      aspectRatio: map['aspectRatio'] is num
          ? (map['aspectRatio'] as num).toDouble()
          : double.tryParse(map['aspectRatio']?.toString() ?? ''),
    );
  }
}
