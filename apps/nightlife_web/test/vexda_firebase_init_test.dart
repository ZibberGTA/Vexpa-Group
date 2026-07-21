import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/firebase/vexda_firebase.dart';
import 'package:nightlife_web/core/widgets/development_holding_page.dart';

void main() {
  tearDown(VexdaFirebase.resetForTesting);

  testWidgets('login stays disabled when Firebase startup failed', (tester) async {
    VexdaFirebase.initializeFailedOverride = true;
    VexdaFirebase.isReadyOverride = false;

    await tester.pumpWidget(
      const MaterialApp(home: DevelopmentHoldingPage()),
    );

    final loginButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Login'));
    expect(loginButton.onPressed, isNull);
  });

  testWidgets('startup failure settles without infinite spinner', (tester) async {
    VexdaFirebase.initializeFailedOverride = true;
    VexdaFirebase.isReadyOverride = false;

    await tester.pumpWidget(
      const MaterialApp(home: DevelopmentHoldingPage.loading()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
