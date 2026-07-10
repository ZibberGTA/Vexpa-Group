/// Firebase-free public drink entity for venue menu reads.
final class VenueDrink {
  const VenueDrink({
    required this.id,
    required this.venueId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.available,
    required this.featured,
    required this.isDeleted,
  });

  final String id;
  final String venueId;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool available;
  final bool featured;
  final bool isDeleted;
}
