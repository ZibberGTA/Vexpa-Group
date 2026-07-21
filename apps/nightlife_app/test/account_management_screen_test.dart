import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/account/screens/account_management_screen.dart';
import 'package:nightlife_app/features/account/services/account_self_service.dart';
import 'package:nightlife_app/features/auth/services/auth_service.dart';

void main() {
  tearDown(() {
    AuthService.isGuestUserOverride = null;
  });

  testWidgets('guest can edit display name and cannot see login security controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountManagementScreen(
          isGuestOverride: true,
          profileLoader: () async => {
            'displayName': 'Jamie',
            'phone': '',
            'city': 'Manchester',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Display name (optional)'), findsOneWidget);
    expect(find.text('Jamie'), findsOneWidget);
    expect(find.text('Login & security'), findsNothing);
    expect(find.text('Change email'), findsNothing);
    expect(find.text('Change password'), findsNothing);
    expect(
      find.textContaining('protect your saved venues'),
      findsOneWidget,
    );
  });

  testWidgets('registered user sees login and security controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountManagementScreen(
          isGuestOverride: false,
          initialEmail: 'member@example.com',
          profileLoader: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login & security'), findsOneWidget);
    expect(find.text('Change email'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
  });

  test('profile loader hook delegates to AccountSelfService by default', () {
    expect(
      const AccountManagementScreen().profileLoader,
      isNull,
    );
    expect(AccountSelfService.loadProfileDocument, isNotNull);
  });
}
