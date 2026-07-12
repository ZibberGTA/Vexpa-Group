import '../domain/venue_admin_health.dart';
import '../domain/venue_admin_health_input.dart';

/// Admin CRM venue health, completeness, and quality scoring.
final class VenueAdminHealthService {
  const VenueAdminHealthService();

  static const strongHealthThreshold = 75;
  static const moderateHealthThreshold = 45;

  VenueAdminHealth calculate(VenueAdminHealthInput input) {
    final empty = input.emptySentinel;

    final items = <VenueAdminHealthItem>[
      VenueAdminHealthItem(
        label: 'Logo uploaded',
        passed: _hasText(input.logoUrl, empty: empty),
      ),
      VenueAdminHealthItem(
        label: 'Banner uploaded',
        passed: _hasText(input.bannerUrl, empty: empty),
      ),
      VenueAdminHealthItem(
        label: 'Description added',
        passed: _hasText(input.description, empty: empty),
      ),
      VenueAdminHealthItem(
        label: 'Address complete',
        passed: _hasText(input.address, empty: empty) ||
            _hasText(input.city, empty: empty),
      ),
      VenueAdminHealthItem(
        label: 'Opening hours complete',
        passed: _hasOpeningHours(input.openingHours),
      ),
      VenueAdminHealthItem(
        label: 'Drinks added',
        passed: input.drinksCount > 0,
      ),
      VenueAdminHealthItem(
        label: 'Deals live',
        passed: input.dealsCount > 0,
      ),
      VenueAdminHealthItem(
        label: 'Events live',
        passed: input.eventsCount > 0,
      ),
      VenueAdminHealthItem(
        label: 'Website added',
        passed: _hasText(input.website, empty: empty),
      ),
      VenueAdminHealthItem(
        label: 'Gallery images',
        passed: input.galleryImagesCount > 0,
      ),
      VenueAdminHealthItem(label: 'Verified', passed: input.isVerified),
      VenueAdminHealthItem(label: 'Claimed', passed: input.isClaimed),
    ];

    final passed = items.where((item) => item.passed).length;
    final total = items.length;
    final score = total == 0 ? 0 : ((passed / total) * 100).round();

    return VenueAdminHealth(
      scorePercent: score,
      passedCount: passed,
      totalCount: total,
      items: items,
    );
  }

  VenueAdminHealth calculateTableEstimate({
    required VenueAdminHealthInput input,
  }) =>
      calculate(
        input.copyWith(
          drinksCount: 0,
          dealsCount: 0,
          eventsCount: 0,
        ),
      );

  VenueHealthAccentTier accentTier(int scorePercent) {
    if (scorePercent >= strongHealthThreshold) return VenueHealthAccentTier.strong;
    if (scorePercent >= moderateHealthThreshold) {
      return VenueHealthAccentTier.moderate;
    }
    return VenueHealthAccentTier.weak;
  }

  static bool _hasText(String value, {required String empty}) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed != empty;
  }

  static bool _hasOpeningHours(Map<String, dynamic> openingHours) {
    if (openingHours.isEmpty) return false;
    return openingHours.values.any((value) {
      if (value is Map) {
        return value.values.any(
          (entry) => entry?.toString().trim().isNotEmpty ?? false,
        );
      }
      return value?.toString().trim().isNotEmpty ?? false;
    });
  }
}

extension on VenueAdminHealthInput {
  VenueAdminHealthInput copyWith({
    int? drinksCount,
    int? dealsCount,
    int? eventsCount,
  }) {
    return VenueAdminHealthInput(
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      description: description,
      address: address,
      city: city,
      website: website,
      openingHours: openingHours,
      isVerified: isVerified,
      isClaimed: isClaimed,
      galleryImagesCount: galleryImagesCount,
      drinksCount: drinksCount ?? this.drinksCount,
      dealsCount: dealsCount ?? this.dealsCount,
      eventsCount: eventsCount ?? this.eventsCount,
      emptySentinel: emptySentinel,
    );
  }
}
