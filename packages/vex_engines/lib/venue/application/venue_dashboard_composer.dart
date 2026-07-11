import '../domain/venue_dashboard_models.dart';
import '../domain/venue_profile_completion.dart';

/// Setup-focused dashboard highlights when analytics are unavailable.
final class VenueDashboardSetupHighlights {
  const VenueDashboardSetupHighlights();

  List<VenueDashboardHighlight> build({int maxHighlights = 4}) {
    return const [
      VenueDashboardHighlight(
        message: 'Add more photos to improve visibility.',
        buttonLabel: 'Add Photos',
        targetTabKey: VenueDashboardTabKey.gallery,
        accentKey: 'blue',
        iconKey: 'photo_library_outlined',
      ),
      VenueDashboardHighlight(
        message: 'Add drinks so customers can discover your venue.',
        buttonLabel: 'Add Drinks',
        targetTabKey: VenueDashboardTabKey.drinks,
        accentKey: 'gold',
        iconKey: 'local_bar_outlined',
      ),
      VenueDashboardHighlight(
        message: 'Create a deal to attract more customers.',
        buttonLabel: 'Create Deal',
        targetTabKey: VenueDashboardTabKey.deals,
        accentKey: 'pink',
        iconKey: 'local_offer_outlined',
      ),
      VenueDashboardHighlight(
        message: 'Add an event to increase engagement.',
        buttonLabel: 'Add Event',
        targetTabKey: VenueDashboardTabKey.events,
        accentKey: 'emerald',
        iconKey: 'event_outlined',
      ),
    ].take(maxHighlights).toList();
  }
}

/// Builds ordered “what should I do next?” actions for venue owners.
final class VenueWhatsNextComposer {
  const VenueWhatsNextComposer();

  List<VenueWhatsNextAction> compose({
    required VenueDashboardVenueSnapshot venue,
    required VenueProfileCompletion profileCompletion,
    required VenueDashboardContentCounts counts,
    int maxActions = 4,
  }) {
    final actions = <VenueWhatsNextAction>[];

    if (!venue.hasGalleryImages) {
      actions.add(
        const VenueWhatsNextAction(
          title: 'Add more photos',
          message: 'Venues with more photos get more views.',
          buttonLabel: 'Upload photos',
          targetTabKey: VenueDashboardTabKey.gallery,
          iconKey: 'photo_library_outlined',
        ),
      );
    }

    if (counts.dealCount == 0) {
      actions.add(
        const VenueWhatsNextAction(
          title: 'Create a new deal',
          message: 'Deals increase customer engagement.',
          buttonLabel: 'Create deal',
          targetTabKey: VenueDashboardTabKey.deals,
          iconKey: 'local_offer_outlined',
        ),
      );
    }

    if (!counts.hasUpcomingEvent) {
      actions.add(
        const VenueWhatsNextAction(
          title: 'Add an upcoming event',
          message: 'Events bring more people through the door.',
          buttonLabel: 'Add event',
          targetTabKey: VenueDashboardTabKey.events,
          iconKey: 'event_outlined',
        ),
      );
    }

    if (profileCompletion.completedSteps < profileCompletion.totalSteps) {
      actions.add(
        VenueWhatsNextAction(
          title: 'Complete your profile',
          message:
              'Finish ${profileCompletion.totalSteps - profileCompletion.completedSteps} more steps to boost visibility.',
          buttonLabel: 'Go to profile',
          targetTabKey: VenueDashboardTabKey.venueProfile,
          iconKey: 'storefront_outlined',
        ),
      );
    }

    if (counts.drinkCount == 0) {
      actions.add(
        const VenueWhatsNextAction(
          title: 'Add your drinks menu',
          message: 'Help customers discover what you serve.',
          buttonLabel: 'Add drinks',
          targetTabKey: VenueDashboardTabKey.drinks,
          iconKey: 'local_bar_outlined',
        ),
      );
    }

    return actions.take(maxActions).toList();
  }
}

/// Merges analytics highlights with setup guidance up to the dashboard limit.
final class VenueDashboardHighlightComposer {
  const VenueDashboardHighlightComposer({
    VenueDashboardSetupHighlights? setupHighlights,
  }) : _setupHighlights = setupHighlights ?? const VenueDashboardSetupHighlights();

  final VenueDashboardSetupHighlights _setupHighlights;

  List<VenueDashboardHighlight> compose({
    required bool analyticsAvailable,
    List<VenueDashboardHighlight> analyticsHighlights = const [],
    int maxHighlights = 4,
  }) {
    if (!analyticsAvailable) {
      return _setupHighlights.build(maxHighlights: maxHighlights);
    }

    final highlights = [...analyticsHighlights];
    if (highlights.length < maxHighlights) {
      highlights.addAll(
        _setupHighlights
            .build(maxHighlights: maxHighlights)
            .take(maxHighlights - highlights.length),
      );
    }

    return highlights.take(maxHighlights).toList();
  }
}
