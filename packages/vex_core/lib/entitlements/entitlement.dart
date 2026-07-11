/// Subscription-controlled capabilities referenced by apps today.
enum EntitlementFeature {
  /// Gallery / media centre uploads (web venue portal).
  mediaCentreAccess,

  /// Mobile owner per-venue analytics breakdown (Owner Pro).
  analyticsVenueBreakdown,

  /// Mobile artist chat after accepted application.
  artistChatAccess,

  /// Mobile venue messaging with accepted artists (Venue Pro).
  venueMessagingAccess,

  /// Mobile venue booking feature flag (Venue Pro).
  venueBookingFeature,
}

/// Media library limit keys aligned with web `MediaLibraryTab.customLimitKey`.
abstract final class MediaLibraryLimitKey {
  static const venueGallery = 'venueGallery';
  static const brandAssets = 'brandAssets';
  static const dealImages = 'dealImages';
  static const eventImages = 'eventImages';
}
