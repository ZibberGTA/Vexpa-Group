import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/navigation/main_bottom_navigation_bar.dart';
import 'package:nightlife_app/features/trails/services/trail_nav_glow_service.dart';

void main() {
  const bottomInset = 48.0;
  const screenSize = Size(400, 800);
  const designBottomGap = 8.0;

  Future<void> pumpNavigationBar(
    WidgetTester tester, {
    double bottomPadding = bottomInset,
    double keyboardInset = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(430, 800),
            padding: EdgeInsets.only(bottom: bottomPadding + keyboardInset),
            viewPadding: const EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            body: const Placeholder(),
            bottomNavigationBar: MainBottomNavigationBar(
              selectedIndex: MainNavTab.discoverIndex,
              trailGlowState: TrailNavGlowState.idle,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'navigation labels remain visible on narrow mobile width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: Scaffold(
              bottomNavigationBar: MainBottomNavigationBar(
                selectedIndex: MainNavTab.discoverIndex,
                trailGlowState: TrailNavGlowState.idle,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in [
        'Discover',
        'Search',
        'Trails',
        'Saved',
        'Account',
      ]) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.height, greaterThan(0));
        expect(labelRect.width, greaterThan(0));
      }
    },
  );

  testWidgets(
    'navigation bar stays inside bottom safe area when inset is present',
    (tester) async {
      await pumpNavigationBar(tester);

      final safeBottomLimit = screenSize.height - bottomInset - designBottomGap;

      for (final label in [
        'Discover',
        'Search',
        'Trails',
        'Saved',
        'Account',
      ]) {
        final labelRect = tester.getRect(find.text(label));
        expect(
          labelRect.bottom,
          lessThanOrEqualTo(safeBottomLimit),
          reason: '$label should sit above the system navigation inset',
        );
        expect(labelRect.height, greaterThan(0));
      }

      final barRect = tester.getRect(
        find.byKey(MainBottomNavigationBar.barKey),
      );
      expect(barRect.bottom, lessThanOrEqualTo(safeBottomLimit));
    },
  );

  testWidgets(
    'navigation bar moves above keyboard inset without clipping labels',
    (tester) async {
      const keyboardInset = 320.0;
      await pumpNavigationBar(tester, keyboardInset: keyboardInset);

      final safeBottomLimit =
          screenSize.height - bottomInset - keyboardInset - designBottomGap;

      final discoverLabelRect = tester.getRect(find.text('Discover'));
      expect(discoverLabelRect.bottom, lessThanOrEqualTo(safeBottomLimit));
      expect(discoverLabelRect.height, greaterThan(0));
    },
  );
}
