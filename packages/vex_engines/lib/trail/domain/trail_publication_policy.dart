import 'trail.dart';
import 'trail_publication_readiness.dart';
import 'trail_status.dart';
import 'trail_stop_order_policy.dart';

/// Publication readiness matching mobile `TrailPublishWorkflow.evaluate`.
abstract final class TrailPublicationPolicy {
  static TrailPublicationReadiness evaluate(Trail trail) {
    final routeValidation = TrailStopOrderPolicy.validateRoute(trail.stops);
    final hasName = trail.name.trim().isNotEmpty;
    final hasBanner = trail.bannerImageUrl.trim().isNotEmpty;
    final hasVenues = trail.effectiveVenueCount > 0;
    final validAvailability = trail.availabilityEnd.isAfter(
      trail.availabilityStart,
    );
    final validStatus =
        trail.status == TrailStatus.draft ||
        trail.status == TrailStatus.published;

    final warnings = <String>[];
    if (routeValidation.hasDuplicateOrders) {
      warnings.add('Duplicate stop orders detected.');
    }
    if (routeValidation.hasMissingOrders) {
      warnings.add('Missing or zero stop orders detected.');
    }

    final checks = [
      TrailPublicationCheck(
        id: TrailPublicationCheckId.name,
        label: 'Trail Name',
        passed: hasName,
        failureMessage: hasName
            ? null
            : 'Trail name missing — add a name before publishing.',
      ),
      TrailPublicationCheck(
        id: TrailPublicationCheckId.banner,
        label: 'Banner',
        passed: hasBanner,
        failureMessage: hasBanner
            ? null
            : 'Banner missing — choose a banner before publishing.',
      ),
      TrailPublicationCheck(
        id: TrailPublicationCheckId.venues,
        label: 'Venues',
        passed: hasVenues,
        failureMessage: hasVenues
            ? null
            : 'No venues added — add at least one venue to this trail.',
      ),
      TrailPublicationCheck(
        id: TrailPublicationCheckId.availability,
        label: 'Availability',
        passed: validAvailability,
        failureMessage: validAvailability
            ? null
            : 'Invalid availability — check the start and end times.',
      ),
      TrailPublicationCheck(
        id: TrailPublicationCheckId.status,
        label: 'Trail Status',
        passed: validStatus,
        failureMessage: validStatus
            ? null
            : 'Trail status is not valid for publishing.',
      ),
    ];

    return TrailPublicationReadiness(
      checks: checks,
      isReady: checks.every((check) => check.passed),
      warnings: warnings,
      normalisedStopOrders: routeValidation.sortedStops
          .map((stop) => stop.order)
          .toList(),
    );
  }

  static bool isReady(Trail trail) => evaluate(trail).isReady;
}
