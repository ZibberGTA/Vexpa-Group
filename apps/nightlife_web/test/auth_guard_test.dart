import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/core/vexcore/web_vexcore.dart';
import 'package:nightlife_web/features/auth/widgets/auth_guard.dart';
import 'package:vex_core/vex_core.dart';

import 'support/auth_guard_test_fakes.dart';

void main() {
  const adminChildKey = Key('admin-dashboard-content');

  late FakeAuthenticationService fakeAuth;
  late FakeIdentityService fakeIdentity;

  Future<void> pumpAdminGuard(
    WidgetTester tester, {
    AuthGuardRequirement requirement = AuthGuardRequirement.admin,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGuard(
          requirement: requirement,
          child: const SizedBox(key: adminChildKey, child: Text('Admin Dashboard')),
        ),
      ),
    );
  }

  setUp(() {
    fakeAuth = FakeAuthenticationService();
    fakeIdentity = FakeIdentityService();
    WebVexCore.authenticationOverride = fakeAuth;
    WebVexCore.identityOverride = fakeIdentity;
  });

  tearDown(() async {
    WebVexCore.authenticationOverride = null;
    WebVexCore.identityOverride = null;
    await fakeAuth.dispose();
    await fakeIdentity.dispose();
  });

  group('AuthGuard admin route (/admin)', () {
    testWidgets('1. signed-out user cannot access /admin', (tester) async {
      fakeAuth.emitAuthState(null);
      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Sign in required'), findsOneWidget);
    });

    testWidgets('2. active admin can access /admin', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          roleLevel: 30,
          staffFlag: true,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsOneWidget);
      expect(find.text('Access restricted'), findsNothing);
    });

    testWidgets('3. customer cannot access /admin', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.regularUser,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);
      expect(find.text(AppStrings.staffAccessDenied), findsOneWidget);
    });

    testWidgets('4. venue owner cannot access /admin', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.venueOwner,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);
    });

    testWidgets('5. suspended admin is denied', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          status: AccountStatus.suspended,
          roleLevel: 30,
          staffFlag: true,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);
    });

    testWidgets('6. disabled admin is denied', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          status: AccountStatus.disabled,
          roleLevel: 30,
          staffFlag: true,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);
    });

    testWidgets('7. deleted admin is denied', (tester) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          status: AccountStatus.deleted,
          roleLevel: 30,
          staffFlag: true,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);
    });

    testWidgets('8. admin page never flashes while identity is resolving', (
      tester,
    ) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity = FakeIdentityService();
      WebVexCore.identityOverride = fakeIdentity;

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.text('Loading your permissions…'), findsOneWidget);
      expect(find.byKey(adminChildKey), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(adminChildKey), findsNothing);

      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.regularUser,
        ),
      );
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Access restricted'), findsOneWidget);

      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          roleLevel: 30,
          staffFlag: true,
        ),
      );
      await tester.pump();

      expect(find.byKey(adminChildKey), findsOneWidget);
    });

    testWidgets('9. signing out while on /admin immediately removes access', (
      tester,
    ) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity.emitIdentity(
        testIdentity(
          uid: testAuthenticatedUser.uid,
          dashboardRole: DashboardRole.admin,
          roleLevel: 30,
          staffFlag: true,
        ),
      );

      await pumpAdminGuard(tester);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsOneWidget);

      fakeAuth.emitAuthState(null);
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Sign in required'), findsOneWidget);
    });

    testWidgets('10. identity resolution failure safely denies access', (
      tester,
    ) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity = FakeIdentityService();
      WebVexCore.identityOverride = fakeIdentity;

      await pumpAdminGuard(tester);
      await tester.pump();

      fakeIdentity.emitStreamError(StateError('identity stream failed'));
      await tester.pump();

      expect(find.byKey(adminChildKey), findsNothing);
      expect(find.text('Permissions unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('11. retry identity resolution behaves correctly', (
      tester,
    ) async {
      fakeAuth.emitAuthState(testAuthenticatedUser);
      fakeIdentity = FakeIdentityService(retryThrows: true);
      WebVexCore.identityOverride = fakeIdentity;

      await pumpAdminGuard(tester);
      await tester.pump();

      fakeIdentity.emitStreamError(StateError('identity stream failed'));
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(fakeIdentity.retryCallCount, 1);
      await tester.pump();

      expect(
        find.text('Could not load your permissions. Please try again.'),
        findsOneWidget,
      );

      fakeIdentity.retryThrows = false;
      fakeIdentity.retryResult = testIdentity(
        uid: testAuthenticatedUser.uid,
        dashboardRole: DashboardRole.admin,
        roleLevel: 30,
        staffFlag: true,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(fakeIdentity.retryCallCount, 2);
      expect(find.byKey(adminChildKey), findsOneWidget);
    });

    testWidgets(
      '12. AuthGuard does not create duplicate auth/identity subscriptions on rebuild',
      (tester) async {
        fakeAuth.emitAuthState(testAuthenticatedUser);
        fakeIdentity.emitIdentity(
          testIdentity(
            uid: testAuthenticatedUser.uid,
            dashboardRole: DashboardRole.admin,
            roleLevel: 30,
            staffFlag: true,
          ),
        );

        await tester.pumpWidget(const _AuthGuardRebuildHarness());
        await tester.pump();

        expect(fakeAuth.maxConcurrentAuthListeners, 1);
        expect(fakeIdentity.maxConcurrentIdentityListeners, 1);

        await tester.tap(find.byKey(_AuthGuardRebuildHarness.triggerKey));
        await tester.pump();

        expect(fakeAuth.maxConcurrentAuthListeners, 1);
        expect(fakeIdentity.maxConcurrentIdentityListeners, 1);
        expect(find.byKey(_AuthGuardRebuildHarness.adminChildKey), findsOneWidget);
      },
    );
  });
}

class _AuthGuardRebuildHarness extends StatefulWidget {
  const _AuthGuardRebuildHarness();

  static const triggerKey = Key('auth-guard-rebuild-trigger');
  static const adminChildKey = Key('admin-dashboard-content');

  @override
  State<_AuthGuardRebuildHarness> createState() =>
      _AuthGuardRebuildHarnessState();
}

class _AuthGuardRebuildHarnessState extends State<_AuthGuardRebuildHarness> {
  var _label = 'Admin Dashboard';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Column(
        children: [
          TextButton(
            key: _AuthGuardRebuildHarness.triggerKey,
            onPressed: () => setState(() => _label = 'Admin Dashboard Updated'),
            child: const Text('Rebuild'),
          ),
          Expanded(
            child: AuthGuard(
              requirement: AuthGuardRequirement.admin,
              child: SizedBox(
                key: _AuthGuardRebuildHarness.adminChildKey,
                child: Text(_label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
