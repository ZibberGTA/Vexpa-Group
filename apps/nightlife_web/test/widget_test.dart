import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/main.dart';

void main() {
  testWidgets('Premium homepage renders hero, why Vexda, stats and download', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const VexdaWebApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your night out.'), findsOneWidget);
    expect(find.text('Perfected.'), findsOneWidget);
    expect(find.text(AppStrings.searchPlaceholder), findsOneWidget);
    expect(find.text(AppStrings.heroDownloadLink), findsOneWidget);
    expect(find.text('Download App'), findsWidgets);
    expect(find.text('View Venues'), findsNothing);
    expect(find.text('Why Vexda?'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Grow'), findsOneWidget);
    expect(find.text('10,000+'), findsOneWidget);
    expect(find.text('Your night. In your pocket.'), findsOneWidget);
    expect(find.text('Discover more. Experience more. Live more.'), findsOneWidget);
    expect(find.text("Tonight's Trails"), findsNothing);
    expect(find.text('Trending tonight'), findsNothing);
    expect(find.text('Shoreditch After Dark'), findsNothing);
  });
}
