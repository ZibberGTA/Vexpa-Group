/// Text fields used when rebuilding venue search terms during profile updates.
final class VenueProfileSearchContext {
  const VenueProfileSearchContext({
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.crowdLevel,
  });

  final String name;
  final String description;
  final String address;
  final String category;
  final String crowdLevel;
}
