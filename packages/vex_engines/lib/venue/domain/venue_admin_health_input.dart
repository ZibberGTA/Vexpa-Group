/// Engine-neutral admin venue health input.
final class VenueAdminHealthInput {
  const VenueAdminHealthInput({
    required this.logoUrl,
    required this.bannerUrl,
    required this.description,
    required this.address,
    required this.city,
    required this.website,
    required this.openingHours,
    required this.isVerified,
    required this.isClaimed,
    required this.galleryImagesCount,
    required this.drinksCount,
    required this.dealsCount,
    required this.eventsCount,
    this.emptySentinel = '—',
  });

  final String logoUrl;
  final String bannerUrl;
  final String description;
  final String address;
  final String city;
  final String website;
  final Map<String, dynamic> openingHours;
  final bool isVerified;
  final bool isClaimed;
  final int galleryImagesCount;
  final int drinksCount;
  final int dealsCount;
  final int eventsCount;
  final String emptySentinel;
}
