/// Engine-neutral gallery image used for ordering and public presentation.
final class ExperienceGalleryImage {
  const ExperienceGalleryImage({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.category = 'other',
    this.isCover = false,
    this.sortOrder = 0,
    this.visible = true,
  });

  final String id;
  final String imageUrl;
  final String? thumbnailUrl;
  final String category;
  final bool isCover;
  final int sortOrder;
  final bool visible;
}

/// Engine-neutral media row for gallery and brand-asset ordering rules.
final class ExperienceMediaSortKey {
  const ExperienceMediaSortKey({
    required this.id,
    this.featured = false,
    this.sortOrder = 0,
    this.uploadedAt,
    this.isCurrent = false,
    this.mediaKind = 'gallery',
    this.status = 'active',
    this.visible = true,
    this.imageUrl = '',
  });

  final String id;
  final bool featured;
  final int sortOrder;
  final DateTime? uploadedAt;
  final bool isCurrent;
  final String mediaKind;
  final String status;
  final bool visible;
  final String imageUrl;

  bool get isActiveMedia => status == 'active' && visible;
}

/// Summary counts for venue-published content dashboards.
final class ExperienceContentMetrics {
  const ExperienceContentMetrics({
    required this.total,
    required this.featured,
    this.available = 0,
    this.categories = 0,
    this.active = 0,
    this.scheduled = 0,
    this.expired = 0,
    this.paused = 0,
    this.draft = 0,
    this.live = 0,
    this.ended = 0,
    this.upcoming = 0,
    this.galleryImages = 0,
    this.hasGalleryCover = false,
  });

  final int total;
  final int featured;
  final int available;
  final int categories;
  final int active;
  final int scheduled;
  final int expired;
  final int paused;
  final int draft;
  final int live;
  final int ended;
  final int upcoming;
  final int galleryImages;
  final bool hasGalleryCover;
}

/// Recent activity line for management dashboards.
final class ExperienceContentActivity {
  const ExperienceContentActivity({
    required this.title,
    required this.timestampLabel,
    required this.kind,
  });

  final String title;
  final String timestampLabel;
  final String kind;
}
