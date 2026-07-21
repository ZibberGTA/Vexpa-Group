import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/theme/app_colors.dart';
import 'package:nightlife_app/core/theme/app_decorations.dart';
import 'package:nightlife_app/features/discover/models/discover_models.dart';
import 'package:nightlife_app/features/discover/utils/discover_carousel_scroll.dart';
import 'package:nightlife_app/features/discover/widgets/discover_filter_button.dart';
import 'package:nightlife_app/features/discover/widgets/discover_results_panel.dart';
import 'package:nightlife_app/features/discover/widgets/discover_venue_card.dart';
import 'package:nightlife_app/features/discover/widgets/trails_navigation_button.dart';
import 'package:nightlife_app/features/navigation/main_bottom_navigation_bar.dart';
import 'package:nightlife_app/features/trails/models/trail_model.dart';
import 'package:nightlife_app/features/trails/services/trail_nav_glow_service.dart';

void main() {
  group('MainBottomNavigationBar', () {
    Future<void> pumpBar(WidgetTester tester, {int selectedIndex = 0}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(430, 932)),
            child: Scaffold(
              bottomNavigationBar: MainBottomNavigationBar(
                selectedIndex: selectedIndex,
                trailGlowState: TrailNavGlowState.idle,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders Discover Search Trails Saved Account in order', (
      tester,
    ) async {
      await pumpBar(tester);

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Trails'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Map'), findsNothing);
    });

    testWidgets('Trails button is centred between side tabs', (tester) async {
      await pumpBar(tester, selectedIndex: MainNavTab.trailsIndex);

      final discover = tester.getCenter(find.text('Discover'));
      final search = tester.getCenter(find.text('Search'));
      final trails = tester.getCenter(
        find.byKey(TrailsNavigationButton.buttonKey),
      );
      final saved = tester.getCenter(find.text('Saved'));
      final account = tester.getCenter(find.text('Account'));

      expect(trails.dx, greaterThan(search.dx));
      expect(trails.dx, lessThan(saved.dx));
      expect((discover.dx + account.dx) / 2, closeTo(trails.dx, 40));
    });
  });

  group('TrailsNavigationButton', () {
    testWidgets('default state renders Trails label without pulse', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrailsNavigationButton(
                selected: false,
                shouldGlow: false,
                onTap: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Trails'), findsOneWidget);
    });

    testWidgets('active trail state renders with glow enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrailsNavigationButton(
                selected: true,
                shouldGlow: true,
                onTap: _noop,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(TrailsNavigationButton.buttonKey), findsOneWidget);
    });

    testWidgets('reduced motion disables pulse animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: TrailsNavigationButton(
                  selected: false,
                  shouldGlow: true,
                  onTap: _noop,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(TrailsNavigationButton.buttonKey), findsOneWidget);
    });
  });

  group('TrailNavGlowService', () {
    test('glows for active joined trail', () {
      final trail = _trail(
        start: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final progress = TrailProgressModel(
        trailId: trail.id,
        started: true,
        completed: false,
        currentStop: 1,
        checkedInStops: const {0},
      );

      final state = TrailNavGlowService.resolveGlowState(
        trail: trail,
        progress: progress,
      );

      expect(state.shouldGlow, isTrue);
      expect(state.hasActiveTrail, isTrue);
    });

    test('does not glow for upcoming joined trail', () {
      final start = DateTime.now().add(const Duration(hours: 2));
      final trail = _trail(start: start);
      final progress = TrailProgressModel(
        trailId: trail.id,
        started: false,
        completed: false,
        currentStop: 0,
        checkedInStops: const {},
      );

      final state = TrailNavGlowService.resolveGlowState(
        trail: trail,
        progress: progress,
      );

      expect(state.shouldGlow, isFalse);
      expect(state.hasActiveTrail, isFalse);
    });

    test('does not glow for completed trail', () {
      final trail = _trail(
        start: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final progress = TrailProgressModel(
        trailId: trail.id,
        started: true,
        completed: true,
        currentStop: 2,
        checkedInStops: const {0, 1},
      );

      final state = TrailNavGlowService.resolveGlowState(
        trail: trail,
        progress: progress,
      );

      expect(state.shouldGlow, isFalse);
    });

    test('does not glow without joined progress', () {
      final trail = _trail(start: DateTime.now().add(const Duration(hours: 2)));

      final state = TrailNavGlowService.resolveGlowState(trail: trail);

      expect(state.shouldGlow, isFalse);
    });
  });

  group('Discover UI', () {
    Future<void> setTallSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    testWidgets('filter labels are Deals Events Venues', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: DiscoverFilter.values
                  .map(
                    (filter) => DiscoverFilterButton(
                      filter: filter,
                      selected: false,
                      onTap: _noop,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      expect(find.text('Deals'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('Nearby'), findsNothing);
    });

    testWidgets('discover chrome has no duplicate page title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Discover',
              child: Row(
                children: DiscoverFilter.values
                    .map(
                      (filter) => DiscoverFilterButton(
                        filter: filter,
                        selected: false,
                        onTap: _noop,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Discover'), findsNothing);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('selected filter shows stronger decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                DiscoverFilterButton(
                  filter: DiscoverFilter.deals,
                  selected: true,
                  onTap: _noop,
                ),
                DiscoverFilterButton(
                  filter: DiscoverFilter.events,
                  selected: false,
                  onTap: _noop,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(DiscoverFilterButton.selectedIndicatorKey),
        findsOneWidget,
      );
    });

    testWidgets('results panel opens for deals filter', (tester) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      await setTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.deals,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.success,
                      results: [
                        DiscoverVenueResult(
                          venueId: 'v1',
                          venueName: 'Harbour Bar',
                          venueData: {},
                          dealTitle: '2-for-1 cocktails',
                        ),
                      ],
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: 'v1',
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DiscoverResultsPanel.panelKey), findsOneWidget);
      expect(
        find.byKey(DiscoverResultsPanel.slideTransitionKey),
        findsOneWidget,
      );
      expect(find.text('Harbour Bar'), findsOneWidget);
      expect(find.textContaining('2-for-1 cocktails'), findsOneWidget);
    });

    testWidgets('results panel respects reduced motion on entry', (
      tester,
    ) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      await setTallSurface(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              size: Size(400, 800),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.deals,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.empty,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: null,
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(DiscoverResultsPanel.slideTransitionKey),
        findsOneWidget,
      );
    });

    testWidgets('results panel hide callback fires under reduced motion', (
      tester,
    ) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      var hidden = false;
      final hostKey = GlobalKey<_PanelVisibilityHostState>();
      await setTallSurface(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              size: Size(400, 800),
            ),
            child: _PanelVisibilityHost(
              key: hostKey,
              carouselController: carouselController,
              onHidden: () => hidden = true,
            ),
          ),
        ),
      );
      await tester.pump();
      hostKey.currentState!.hide();
      await tester.pump();

      expect(hidden, isTrue);
    });

    testWidgets('results panel uses Vexda card decoration', (tester) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.venues,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.empty,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: null,
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final decoration = tester.widget<DecoratedBox>(
        find.byKey(DiscoverResultsPanel.panelDecorationKey),
      );
      final boxDecoration = decoration.decoration! as BoxDecoration;

      expect(boxDecoration, AppDecorations.heroCard);
      expect(
        boxDecoration.borderRadius,
        BorderRadius.circular(AppDecorations.heroCardBorderRadius),
      );
      expect(boxDecoration.border, isNotNull);
      expect(boxDecoration.color, AppDecorations.heroCardBackgroundColor);
    });

    testWidgets(
      'carousel controller stays attached to one scroll view during filter changes',
      (tester) async {
        final carouselController = ScrollController();
        addTearDown(carouselController.dispose);

        const dealsSuccess = DiscoverLoadState(
          status: DiscoverLoadStatus.success,
          results: [
            DiscoverVenueResult(
              venueId: 'v1',
              venueName: 'Harbour Bar',
              venueData: {},
              dealTitle: '2-for-1 cocktails',
            ),
          ],
        );
        const eventsLoading = DiscoverLoadState(
          status: DiscoverLoadStatus.loading,
        );
        const eventsSuccess = DiscoverLoadState(
          status: DiscoverLoadStatus.success,
          results: [
            DiscoverVenueResult(
              venueId: 'v2',
              venueName: 'Canal Club',
              venueData: {},
              eventTitle: 'Live DJ',
            ),
          ],
        );

        Future<void> pumpPanel({
          required DiscoverFilter filter,
          required DiscoverLoadState loadState,
        }) {
          return tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: Scaffold(
                  body: Stack(
                    children: [
                      DiscoverResultsPanel(
                        filter: filter,
                        loadState: loadState,
                        expanded: true,
                        visible: true,
                        bottomInset: 96,
                        selectedVenueId: null,
                        favouriteVenueIds: const {},
                        carouselController: carouselController,
                        onToggleExpanded: () {},
                        onVenueOpen: (_) {},
                        onFavouriteTap: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        await pumpPanel(filter: DiscoverFilter.deals, loadState: dealsSuccess);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(carouselController.positions.length, 1);
        expect(find.byKey(DiscoverResultsPanel.carouselKey), findsOneWidget);

        await pumpPanel(
          filter: DiscoverFilter.events,
          loadState: eventsLoading,
        );
        await tester.pump();
        expect(carouselController.positions.length, 1);
        expect(find.byKey(DiscoverResultsPanel.carouselKey), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
        expect(carouselController.positions.length, 1);

        await pumpPanel(
          filter: DiscoverFilter.events,
          loadState: eventsSuccess,
        );
        await tester.pump();
        expect(carouselController.positions.length, 1);

        await tester.pump(const Duration(milliseconds: 300));
        expect(carouselController.positions.length, 1);
        expect(find.byKey(DiscoverResultsPanel.carouselKey), findsOneWidget);
      },
    );

    testWidgets('carousel uses permanently inset clipped viewport', (
      tester,
    ) async {
      const viewportWidth = 390.0;
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);

      final results = List.generate(
        5,
        (index) => DiscoverVenueResult(
          venueId: 'v$index',
          venueName: 'Venue $index',
          venueData: const {},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(viewportWidth, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.venues,
                    loadState: DiscoverLoadState(
                      status: DiscoverLoadStatus.success,
                      results: results,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: null,
                    favouriteVenueIds: const {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(carouselController.positions.length, 1);
      expect(
        find.byKey(DiscoverResultsPanel.carouselViewportPaddingKey),
        findsOneWidget,
      );
      expect(
        find.byKey(DiscoverResultsPanel.carouselViewportClipKey),
        findsOneWidget,
      );

      final padding = tester.widget<Padding>(
        find.byKey(DiscoverResultsPanel.carouselViewportPaddingKey),
      );
      expect(
        padding.padding,
        const EdgeInsets.symmetric(
          horizontal: DiscoverCarouselScroll.panelContentPadding,
        ),
      );

      final clipHost = tester.widget<ClipRRect>(
        find.byKey(DiscoverResultsPanel.carouselViewportClipKey),
      );
      expect(clipHost.child, isA<ListView>());

      final listView = tester.widget<ListView>(
        find.byKey(DiscoverResultsPanel.carouselKey),
      );
      expect(listView.padding, const EdgeInsets.symmetric(vertical: 4));
      expect(listView.clipBehavior, Clip.hardEdge);

      final panelRect = tester.getRect(
        find.byKey(DiscoverResultsPanel.panelKey),
      );
      final firstCardRect = tester.getRect(
        find.byKey(const ValueKey('discover-card-v0')),
      );
      final footerRect = tester.getRect(
        find.text('Looking for more? Use Search'),
      );
      final viewportLeft = footerRect.left;
      final viewportRight =
          panelRect.right - DiscoverCarouselScroll.panelContentPadding;

      expect(
        firstCardRect.left - panelRect.left,
        closeTo(DiscoverCarouselScroll.panelContentPadding, 1),
      );
      expect(firstCardRect.left, closeTo(viewportLeft, 1));

      await tester.drag(
        find.byKey(DiscoverResultsPanel.carouselKey),
        const Offset(-220, 0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      final scrolledCardRect = tester.getRect(
        find.byKey(const ValueKey('discover-card-v1')),
      );
      expect(scrolledCardRect.left, greaterThanOrEqualTo(viewportLeft - 1));
      expect(scrolledCardRect.right, lessThanOrEqualTo(viewportRight + 1));

      carouselController.jumpTo(carouselController.position.maxScrollExtent);
      await tester.pump();

      final lastCardRect = tester.getRect(
        find.byKey(const ValueKey('discover-card-v4')),
      );
      expect(lastCardRect.right, lessThanOrEqualTo(viewportRight + 1));
      expect(
        panelRect.right - lastCardRect.right,
        closeTo(DiscoverCarouselScroll.panelContentPadding, 1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('portrait venue cards use responsive width with peek', (
      tester,
    ) async {
      const viewportWidth = 400.0;
      final cardWidth = DiscoverVenueCard.cardWidthForViewport(viewportWidth);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(viewportWidth, 800)),
            child: Scaffold(
              body: SizedBox(
                width: viewportWidth - 28,
                height: 260,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    DiscoverVenueCard(
                      key: const ValueKey('discover-card-v1'),
                      cardWidth: cardWidth,
                      result: const DiscoverVenueResult(
                        venueId: 'v1',
                        venueName: 'Harbour Bar',
                        venueData: {},
                      ),
                      filter: DiscoverFilter.venues,
                      selected: false,
                      onTap: _noop,
                      onFavouriteTap: _noop,
                    ),
                    DiscoverVenueCard(
                      cardWidth: cardWidth,
                      result: const DiscoverVenueResult(
                        venueId: 'v2',
                        venueName: 'Canal Club',
                        venueData: {},
                      ),
                      filter: DiscoverFilter.venues,
                      selected: false,
                      onTap: _noop,
                      onFavouriteTap: _noop,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final cardSize = tester.getSize(
        find.byKey(const ValueKey('discover-card-v1')),
      );
      expect(cardSize.width, closeTo(cardWidth, 13));
      expect(cardWidth, lessThan(viewportWidth * 0.5));
      expect(cardWidth, lessThan(cardSize.height));
      expect(find.text('Canal Club'), findsOneWidget);

      final firstCardRight = tester
          .getTopRight(find.byKey(const ValueKey('discover-card-v1')))
          .dx;
      final listRight = viewportWidth - 28;
      expect(listRight - firstCardRight, greaterThan(cardWidth * 0.35));
    });

    testWidgets('panel respects bottom inset above navigation', (tester) async {
      await setTallSurface(tester);
      const bottomInset = 120.0;
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.events,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.empty,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: bottomInset,
                    selectedVenueId: null,
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final panelRect = tester.getRect(
        find.byKey(DiscoverResultsPanel.panelKey),
      );
      expect(panelRect.bottom, closeTo(800 - bottomInset, 1));
    });

    testWidgets('empty state message renders in panel', (tester) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.deals,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.empty,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: null,
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No active deals were found near you.'), findsOneWidget);
    });

    testWidgets('venues panel heading uses Closest venues', (tester) async {
      final carouselController = ScrollController();
      addTearDown(carouselController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Stack(
                children: [
                  DiscoverResultsPanel(
                    filter: DiscoverFilter.venues,
                    loadState: const DiscoverLoadState(
                      status: DiscoverLoadStatus.locationDenied,
                    ),
                    expanded: true,
                    visible: true,
                    bottomInset: 96,
                    selectedVenueId: null,
                    favouriteVenueIds: {},
                    carouselController: carouselController,
                    onToggleExpanded: () {},
                    onVenueOpen: (_) {},
                    onFavouriteTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Closest venues'), findsOneWidget);
      expect(find.text(DiscoverFilter.locationDeniedMessage), findsOneWidget);
    });
  });
}

DrinkSpotTrailModel _trail({required DateTime start}) {
  final end = start.add(const Duration(hours: 4));
  return DrinkSpotTrailModel(
    id: 'trail-1',
    name: 'Test Trail',
    description: 'Test',
    bannerImageUrl: '',
    area: 'Edinburgh',
    status: TrailStatus.published,
    published: true,
    generatedAt: start,
    availabilityStart: start,
    availabilityEnd: end,
    estimatedDuration: end.difference(start),
    estimatedWalkingDistance: 1200,
    venueCount: 2,
    trailType: TrailType.curated,
    stops: const [],
  );
}

void _noop() {}

class _PanelVisibilityHost extends StatefulWidget {
  const _PanelVisibilityHost({
    super.key,
    required this.carouselController,
    required this.onHidden,
  });

  final ScrollController carouselController;
  final VoidCallback onHidden;

  @override
  State<_PanelVisibilityHost> createState() => _PanelVisibilityHostState();
}

class _PanelVisibilityHostState extends State<_PanelVisibilityHost> {
  bool _visible = true;

  void hide() => setState(() => _visible = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DiscoverResultsPanel(
            filter: DiscoverFilter.deals,
            loadState: const DiscoverLoadState(
              status: DiscoverLoadStatus.empty,
            ),
            expanded: true,
            visible: _visible,
            bottomInset: 96,
            selectedVenueId: null,
            favouriteVenueIds: const {},
            carouselController: widget.carouselController,
            onToggleExpanded: () {},
            onVenueOpen: (_) {},
            onFavouriteTap: (_) {},
            onHidden: widget.onHidden,
          ),
        ],
      ),
    );
  }
}
