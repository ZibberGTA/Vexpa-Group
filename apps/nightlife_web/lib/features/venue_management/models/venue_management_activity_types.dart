/// Source areas for venue management activity records.
abstract final class VenueManagementActivitySourceAreas {
  static const venueProfile = 'venue_profile';
  static const drinks = 'drinks';
  static const deals = 'deals';
  static const events = 'events';
  static const gallery = 'gallery';
  static const trails = 'trails';
}

/// Action types persisted on venue management activity records.
abstract final class VenueManagementActivityActionTypes {
  static const updated = 'updated';
  static const brandingChanged = 'branding_changed';
  static const contactUpdated = 'contact_updated';
  static const openingHoursUpdated = 'opening_hours_updated';
  static const created = 'created';
  static const availabilityChanged = 'availability_changed';
  static const archived = 'archived';
  static const restored = 'restored';
  static const activated = 'activated';
  static const deactivated = 'deactivated';
  static const published = 'published';
  static const unpublished = 'unpublished';
  static const cancelled = 'cancelled';
  static const photoUploaded = 'photo_uploaded';
  static const photoDeleted = 'photo_deleted';
  static const galleryUpdated = 'gallery_updated';
}

/// Entity types referenced by activity records.
abstract final class VenueManagementActivityEntityTypes {
  static const venue = 'venue';
  static const drink = 'drink';
  static const deal = 'deal';
  static const event = 'event';
  static const media = 'media';
  static const trail = 'trail';
}

/// Firestore collection and schema version for venue management activity.
abstract final class VenueManagementActivityStorage {
  static const collection = 'venue_management_activity';
  static const currentVersion = 1;
}
