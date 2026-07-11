import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/core/widgets/development_holding_page.dart';
import 'package:nightlife_web/core/widgets/development_preview_sign_in_dialog.dart';

void main() {
  testWidgets('holding page shows Login and opens preview sign-in dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DevelopmentHoldingPage(),
      ),
    );

    expect(find.text(AppStrings.login), findsOneWidget);
    expect(find.text(DevelopmentHoldingPage.statusText), findsOneWidget);
    expect(find.byType(DevelopmentPreviewSignInDialog), findsNothing);

    await tester.tap(find.text(AppStrings.login));
    await tester.pumpAndSettle();

    expect(find.byType(DevelopmentPreviewSignInDialog), findsOneWidget);
  });
}
