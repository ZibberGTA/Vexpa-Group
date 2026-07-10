/// Engine-neutral venue profile fields used for completion scoring.
final class VenueProfileCompletionInput {
  const VenueProfileCompletionInput({
    required this.name,
    required this.address,
    required this.city,
    required this.area,
    required this.category,
    required this.venueType,
    required this.logoUrl,
    required this.bannerImageUrl,
    required this.openingHours,
    required this.featureTags,
    required this.features,
    required this.phone,
    required this.website,
    required this.drinkCount,
  });

  final String name;
  final String address;
  final String city;
  final String area;
  final String category;
  final String venueType;
  final String logoUrl;
  final String bannerImageUrl;
  final Map<String, dynamic> openingHours;
  final List<String> featureTags;
  final List<String> features;
  final String phone;
  final String website;
  final int drinkCount;
}
