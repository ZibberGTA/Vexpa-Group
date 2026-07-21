import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/discover/models/discover_models.dart';
import 'package:nightlife_app/features/discover/models/discover_presentation_state.dart';

void main() {
  group('DiscoverPresentationState', () {
    test(
      'results panel visible only with active filter and no venue preview',
      () {
        const withFilter = DiscoverPresentationState(
          selectedFilter: DiscoverFilter.deals,
        );
        expect(withFilter.resultsPanelVisible, isTrue);
        expect(withFilter.shouldHideMapControls, isTrue);

        const withPreview = DiscoverPresentationState(
          selectedFilter: DiscoverFilter.deals,
          venuePreviewOpen: true,
        );
        expect(withPreview.resultsPanelVisible, isFalse);
        expect(withPreview.shouldHideMapControls, isTrue);

        const idle = DiscoverPresentationState();
        expect(idle.resultsPanelVisible, isFalse);
        expect(idle.shouldHideMapControls, isFalse);
      },
    );

    test('panelShown gates visible results while filter remains active', () {
      const dismissing = DiscoverPresentationState(
        selectedFilter: DiscoverFilter.deals,
        panelShown: false,
      );
      expect(dismissing.hasActiveFilter, isTrue);
      expect(dismissing.resultsPanelVisible, isFalse);
      expect(dismissing.shouldHideMapControls, isTrue);
    });

    test('hasSelectedVenueInResults reflects active result list', () {
      const withSelection = DiscoverPresentationState(
        selectedFilter: DiscoverFilter.events,
        selectedVenueId: 'v2',
        loadState: DiscoverLoadState(
          status: DiscoverLoadStatus.success,
          results: [
            DiscoverVenueResult(venueId: 'v1', venueName: 'A', venueData: {}),
            DiscoverVenueResult(venueId: 'v2', venueName: 'B', venueData: {}),
          ],
        ),
      );

      expect(withSelection.hasSelectedVenueInResults, isTrue);
      expect(
        withSelection
            .copyWith(selectedVenueId: 'missing')
            .hasSelectedVenueInResults,
        isFalse,
      );
    });

    test('cleared returns default presentation state', () {
      const active = DiscoverPresentationState(
        selectedFilter: DiscoverFilter.venues,
        panelExpanded: false,
        selectedVenueId: 'v1',
        venuePreviewOpen: true,
      );

      expect(active.cleared(), const DiscoverPresentationState());
    });

    test('copyWith can clear filter and selected venue', () {
      const active = DiscoverPresentationState(
        selectedFilter: DiscoverFilter.events,
        selectedVenueId: 'v1',
      );

      final cleared = active.copyWith(
        clearSelectedFilter: true,
        clearSelectedVenueId: true,
      );

      expect(cleared.selectedFilter, isNull);
      expect(cleared.selectedVenueId, isNull);
    });

    test('presentation state remains stable without map-area stale flag', () {
      const afterCameraMove = DiscoverPresentationState(
        selectedFilter: DiscoverFilter.venues,
        loadState: DiscoverLoadState(
          status: DiscoverLoadStatus.success,
          results: [
            DiscoverVenueResult(venueId: 'v1', venueName: 'A', venueData: {}),
          ],
        ),
      );

      expect(afterCameraMove.resultsPanelVisible, isTrue);
      expect(afterCameraMove.hasActiveFilter, isTrue);
    });
  });
}
