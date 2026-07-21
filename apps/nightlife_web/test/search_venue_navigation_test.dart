import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/routing/app_router.dart';
import 'package:nightlife_web/core/theme/app_colors.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';
import 'package:nightlife_web/features/search/search_venue_navigation.dart';

void main() {
  group('SearchVenueNavigation', () {
    test('canonicalVenueId uses Firestore document id on search result', () {
      expect(
        SearchVenueNavigation.canonicalVenueId(_venue(id: 'legacy-doc-42')),
        'legacy-doc-42',
      );
    });

    test('canonicalVenueId rejects blank ids', () {
      expect(SearchVenueNavigation.canonicalVenueId(_venue(id: '  ')), isNull);
    });

    testWidgets('openVenueDetails pushes /venue/{documentId}', (
      WidgetTester tester,
    ) async {
      final observer = _RouteObserver();

      await tester.pumpWidget(
        _navigationApp(
          observer: observer,
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => SearchVenueNavigation.openVenueDetails(
                  context,
                  _venue(id: 'venue-alpha'),
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(observer.venueRoutes, [AppRouter.venueDetails('venue-alpha')]);
      expect(find.text('Venue Details Stub'), findsOneWidget);
    });

    testWidgets(
      'legacy venue without embedded venueId field still navigates by document id',
      (WidgetTester tester) async {
        final observer = _RouteObserver();

        await tester.pumpWidget(
          _navigationApp(
            observer: observer,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => SearchVenueNavigation.selectAndOpen(
                    context: context,
                    venues: [_venue(id: 'legacy-doc-without-field')],
                    index: 0,
                    onSelected: (_) {},
                  ),
                  child: const Text('open legacy'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('open legacy'));
        await tester.pumpAndSettle();

        expect(
          observer.venueRoutes,
          [AppRouter.venueDetails('legacy-doc-without-field')],
        );
      },
    );

    testWidgets('invalid catalog index does not navigate', (
      WidgetTester tester,
    ) async {
      final observer = _RouteObserver();

      await tester.pumpWidget(
        _navigationApp(
          observer: observer,
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => SearchVenueNavigation.selectAndOpen(
                  context: context,
                  venues: [_venue(id: 'venue-alpha')],
                  index: 4,
                  onSelected: (_) {},
                ),
                child: const Text('open invalid'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open invalid'));
      await tester.pumpAndSettle();

      expect(observer.venueRoutes, isEmpty);
      expect(find.text('open invalid'), findsOneWidget);
    });

    testWidgets('browser back returns to the map after opening a venue', (
      WidgetTester tester,
    ) async {
      final observer = _RouteObserver();

      await tester.pumpWidget(
        _navigationApp(
          observer: observer,
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => SearchVenueNavigation.openVenueDetails(
                  context,
                  _venue(id: 'venue-beta'),
                ),
                child: const Text('open and back'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open and back'));
      await tester.pumpAndSettle();
      expect(find.text('Venue Details Stub'), findsOneWidget);

      Navigator.of(tester.element(find.text('Venue Details Stub'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('open and back'), findsOneWidget);
      expect(observer.venueRoutes, [AppRouter.venueDetails('venue-beta')]);
      expect(observer.poppedVenueRoutes, [AppRouter.venueDetails('venue-beta')]);
    });
  });
}

Widget _navigationApp({
  required _RouteObserver observer,
  required Widget child,
}) {
  return MaterialApp(
    navigatorObservers: [observer],
    home: Scaffold(body: child),
    onGenerateRoute: (settings) {
      if (settings.name?.startsWith(AppRouter.venuePrefix) ?? false) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('Venue Details Stub')),
        );
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: Text('Map Screen')),
      );
    },
  );
}

VenueSearchResult _venue({required String id}) {
  return VenueSearchResult(
    id: id,
    name: 'Test Venue',
    area: 'Shoreditch',
    city: 'London',
    venueType: 'Bar',
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [AppColors.primaryPurple, AppColors.primaryPink],
    logoGradient: const [AppColors.primaryPurple, AppColors.primaryPink],
    resultReason: 'Open until late',
    isOpen: true,
    latitude: 51.52,
    longitude: -0.08,
  );
}

class _RouteObserver extends NavigatorObserver {
  final pushedRoutes = <String?>[];
  final poppedRoutes = <String?>[];

  List<String?> get venueRoutes => pushedRoutes
      .where((route) => route?.startsWith(AppRouter.venuePrefix) ?? false)
      .toList();

  List<String?> get poppedVenueRoutes => poppedRoutes
      .where((route) => route?.startsWith(AppRouter.venuePrefix) ?? false)
      .toList();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route.settings.name);
    super.didPop(route, previousRoute);
  }
}
