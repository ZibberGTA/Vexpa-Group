/// Firebase-free public event entity for venue event reads.
final class VenueEvent {
  const VenueEvent({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.category,
    required this.imageUrl,
    required this.artist,
    required this.isActive,
    required this.featured,
    required this.isDeleted,
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String category;
  final String imageUrl;
  final String artist;
  final bool isActive;
  final bool featured;
  final bool isDeleted;
}
