import 'package:vex_engines/venue/application/venue_admin_health_service.dart';
import 'package:vex_engines/venue/domain/venue_admin_health.dart';
import 'package:vex_engines/venue/domain/venue_admin_health_input.dart';

import '../models/admin_venue_crm.dart';

/// Admin adapter facade for Venue Engine health and quality scoring.
final class AdminVenueHealthSupport {
  AdminVenueHealthSupport._();

  static const _engine = VenueAdminHealthService();

  static AdminVenueHealth calculateHealth({
    required AdminVenueCrmView profile,
    int drinksCount = 0,
    int dealsCount = 0,
    int eventsCount = 0,
    int? galleryImagesCount,
  }) {
    final result = _engine.calculate(_inputFromProfile(
      profile: profile,
      drinksCount: drinksCount,
      dealsCount: dealsCount,
      eventsCount: eventsCount,
      galleryImagesCount: galleryImagesCount ?? profile.galleryImagesCount,
    ));
    return _mapHealth(result);
  }

  static AdminVenueHealth estimateTableHealth(AdminVenueCrmView profile) {
    final result = _engine.calculateTableEstimate(
      input: _inputFromProfile(
      profile: profile,
      drinksCount: 0,
      dealsCount: 0,
      eventsCount: 0,
      galleryImagesCount: profile.galleryImagesCount,
      ),
    );
    return _mapHealth(result);
  }

  static VenueHealthAccentTier accentTier(int scorePercent) =>
      _engine.accentTier(scorePercent);

  static VenueAdminHealthInput _inputFromProfile({
    required AdminVenueCrmView profile,
    required int drinksCount,
    required int dealsCount,
    required int eventsCount,
    required int galleryImagesCount,
  }) {
    final openingHours = profile.row.data['openingHours'];
    return VenueAdminHealthInput(
      logoUrl: profile.logoUrl,
      bannerUrl: profile.bannerUrl,
      description: profile.description,
      address: profile.address,
      city: profile.city,
      website: profile.website,
      openingHours: openingHours is Map<String, dynamic>
          ? openingHours
          : openingHours is Map
              ? Map<String, dynamic>.from(openingHours)
              : const {},
      isVerified: profile.isVerified,
      isClaimed: profile.isClaimed,
      galleryImagesCount: galleryImagesCount,
      drinksCount: drinksCount,
      dealsCount: dealsCount,
      eventsCount: eventsCount,
    );
  }

  static AdminVenueHealth _mapHealth(VenueAdminHealth health) {
    return AdminVenueHealth(
      scorePercent: health.scorePercent,
      passedCount: health.passedCount,
      totalCount: health.totalCount,
      items: health.items
          .map(
            (item) => AdminVenueHealthItem(
              label: item.label,
              passed: item.passed,
            ),
          )
          .toList(growable: false),
    );
  }
}
