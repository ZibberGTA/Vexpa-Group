import 'package:vex_engines/experience/application/venue_availability_service.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';
import 'package:vex_engines/experience/application/venue_content_summary_service.dart';
import 'package:vex_engines/experience/application/venue_content_validation_service.dart';
import 'package:vex_engines/experience/application/venue_featured_content_service.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';
import 'package:vex_engines/experience/application/venue_public_presentation_service.dart';

/// Web adapter facades for Experience Engine venue content services.
final class WebExperienceContentSupport {
  WebExperienceContentSupport._();

  static const ordering = VenueContentOrderingService();
  static const availability = VenueAvailabilityService();
  static const summary = VenueContentSummaryService();
  static const validation = VenueContentValidationService();
  static const featured = VenueFeaturedContentService();
  static const presentation = VenuePresentationSupport();
  static const publicPresentation = VenuePublicPresentationService();
}
