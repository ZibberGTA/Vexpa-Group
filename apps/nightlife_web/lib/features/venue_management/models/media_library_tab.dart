import 'venue_media_type.dart';

/// Media library tabs within the Gallery / Media Centre page.
enum MediaLibraryTab {
  venueGallery,
  brandAssets,
  dealImages,
  eventImages,
}

extension MediaLibraryTabX on MediaLibraryTab {
  String get label => switch (this) {
        MediaLibraryTab.venueGallery => 'Venue Gallery',
        MediaLibraryTab.brandAssets => 'Brand Assets',
        MediaLibraryTab.dealImages => 'Deal Images',
        MediaLibraryTab.eventImages => 'Event Images',
      };

  String get usageLabel => switch (this) {
        MediaLibraryTab.venueGallery => 'Photos Used',
        MediaLibraryTab.brandAssets => 'Assets',
        MediaLibraryTab.dealImages => 'Images Used',
        MediaLibraryTab.eventImages => 'Images Used',
      };

  String get emptyUnit => switch (this) {
        MediaLibraryTab.venueGallery => 'photos',
        MediaLibraryTab.brandAssets => 'brand assets',
        MediaLibraryTab.dealImages => 'images',
        MediaLibraryTab.eventImages => 'images',
      };

  String get customLimitKey => switch (this) {
        MediaLibraryTab.venueGallery => 'venueGallery',
        MediaLibraryTab.brandAssets => 'brandAssets',
        MediaLibraryTab.dealImages => 'dealImages',
        MediaLibraryTab.eventImages => 'eventImages',
      };

  /// Brand assets are uploaded from Venue Profile and do not count toward limits.
  bool get countsTowardSubscriptionLimit => this != MediaLibraryTab.brandAssets;

  /// Upload for logo/banner happens on the Venue Profile page.
  bool get supportsDirectUpload => this != MediaLibraryTab.brandAssets;

  VenueMediaType get mediaType => VenueMediaTypeX.fromLibraryTab(this);
}
