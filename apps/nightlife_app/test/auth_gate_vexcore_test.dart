import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/mobile_vexcore.dart';
import 'package:nightlife_app/features/auth/screens/auth_gate.dart';
import 'package:vex_core/vex_core.dart';

const _mainNavKey = Key('auth-gate-main-nav');
const _adminDashKey = Key('auth-gate-admin-dash');

Widget _testMainNav(BuildContext context) =>
    const SizedBox(key: _mainNavKey, child: Text('Main'));

Widget _testAdminDash(BuildContext context) =>
    const SizedBox(key: _adminDashKey, child: Text('Admin'));

void main() {
  tearDown(MobileVexCore.resetTestOverrides);

  testWidgets('customer identity routes to main navigation', (tester) async {
    const uid = 'customer-1';
    MobileVexCore.overrideAuthentication(
      _FakeAuthenticationService(
        stream: Stream.value(
          const AuthenticatedUser(uid: uid, email: 'user@example.com'),
        ),
        current: const AuthenticatedUser(uid: uid, email: 'user@example.com'),
      ),
    );
    MobileVexCore.overrideIdentity(
      _FakeIdentityService(
        stream: Stream.value(
          VexIdentity.fromProfile(
            uid: uid,
            dashboardRole: DashboardRole.regularUser,
          ),
        ),
        cached: VexIdentity.fromProfile(
          uid: uid,
          dashboardRole: DashboardRole.regularUser,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          mainNavigationBuilder: _testMainNav,
          adminDashboardBuilder: _testAdminDash,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(_mainNavKey), findsOneWidget);
    expect(find.byKey(_adminDashKey), findsNothing);
  });

  testWidgets('venue owner routes to main navigation', (tester) async {
    const uid = 'owner-1';
    MobileVexCore.overrideAuthentication(
      _FakeAuthenticationService(
        stream: Stream.value(
          const AuthenticatedUser(uid: uid, email: 'owner@example.com'),
        ),
        current: const AuthenticatedUser(uid: uid, email: 'owner@example.com'),
      ),
    );
    MobileVexCore.overrideIdentity(
      _FakeIdentityService(
        stream: Stream.value(
          VexIdentity.fromProfile(
            uid: uid,
            dashboardRole: DashboardRole.venueOwner,
            venueIds: ['venue-1'],
          ),
        ),
        cached: VexIdentity.fromProfile(
          uid: uid,
          dashboardRole: DashboardRole.venueOwner,
          venueIds: ['venue-1'],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          mainNavigationBuilder: _testMainNav,
          adminDashboardBuilder: _testAdminDash,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(_mainNavKey), findsOneWidget);
  });

  testWidgets('staff admin identity routes to admin dashboard', (tester) async {
    const uid = 'admin-1';
    MobileVexCore.overrideAuthentication(
      _FakeAuthenticationService(
        stream: Stream.value(
          const AuthenticatedUser(uid: uid, email: 'admin@example.com'),
        ),
        current: const AuthenticatedUser(uid: uid, email: 'admin@example.com'),
      ),
    );
    MobileVexCore.overrideIdentity(
      _FakeIdentityService(
        stream: Stream.value(
          VexIdentity.fromProfile(
            uid: uid,
            dashboardRole: DashboardRole.admin,
            roleLevel: 30,
            staffFlag: true,
          ),
        ),
        cached: VexIdentity.fromProfile(
          uid: uid,
          dashboardRole: DashboardRole.admin,
          roleLevel: 30,
          staffFlag: true,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          mainNavigationBuilder: _testMainNav,
          adminDashboardBuilder: _testAdminDash,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(_adminDashKey), findsOneWidget);
  });

  testWidgets('identity retry uses shared identity service', (tester) async {
    const uid = 'admin-1';
    final identity = _FakeIdentityService(
      stream: Stream<VexIdentity?>.empty(),
    );
    MobileVexCore.overrideAuthentication(
      _FakeAuthenticationService(
        stream: Stream.value(
          const AuthenticatedUser(uid: uid, email: 'admin@example.com'),
        ),
        current: const AuthenticatedUser(uid: uid, email: 'admin@example.com'),
      ),
    );
    MobileVexCore.overrideIdentity(identity);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          mainNavigationBuilder: _testMainNav,
          adminDashboardBuilder: _testAdminDash,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));

    expect(find.text('Permissions unavailable'), findsOneWidget);

    identity.nextIdentity = VexIdentity.fromProfile(
      uid: uid,
      dashboardRole: DashboardRole.admin,
      roleLevel: 30,
      staffFlag: true,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(identity.retryCalls, 1);
    expect(find.byKey(_adminDashKey), findsOneWidget);
  });
}

final class _FakeAuthenticationService implements AuthenticationService {
  _FakeAuthenticationService({
    required this.stream,
    this.current,
  });

  @override
  final Stream<AuthenticatedUser?> stream;

  final AuthenticatedUser? current;

  @override
  Stream<AuthenticatedUser?> get authStateChanges => stream;

  @override
  AuthenticatedUser? get currentUser => current;

  @override
  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

final class _FakeIdentityService implements IdentityService {
  _FakeIdentityService({
    required Stream<VexIdentity?> stream,
    VexIdentity? cached,
  })  : _controller = StreamController<VexIdentity?>.broadcast(),
        _cached = cached {
    if (cached != null) {
      _controller.add(cached);
    }
    stream.listen(_controller.add);
  }

  final StreamController<VexIdentity?> _controller;
  VexIdentity? _cached;
  VexIdentity? nextIdentity;
  int retryCalls = 0;

  @override
  Stream<VexIdentity?> get currentIdentityStream => _controller.stream;

  @override
  Future<VexIdentity?> resolveCurrentIdentity() async => _cached;

  @override
  Future<VexIdentity?> resolveIdentity(String uid) async => _cached;

  @override
  Future<VexIdentity?> retryIdentityResolution(String uid) async {
    retryCalls++;
    _cached = nextIdentity;
    if (_cached != null) {
      _controller.add(_cached);
    }
    return _cached;
  }

  @override
  VexIdentity? peekCachedIdentity(String uid) => _cached;
}
