import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/auth/development_preview_sign_in_service.dart';
import 'package:nightlife_web/core/widgets/development_preview_sign_in_dialog.dart';
import 'package:nightlife_web/shared/components/drinkspot_button.dart';

class _FakeUser implements User {
  _FakeUser(this.email, {this.uid = 'uid-1'});

  @override
  final String? email;

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  _FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DevelopmentPreviewSignInService _testService({
  required PreviewSignInWithEmailPassword signInWithEmailAndPassword,
  PreviewGetCurrentUser? getCurrentUser,
  PreviewWaitForAuthUser? waitForAuthUser,
  PreviewIsApprovedEmail? isApprovedEmail,
  PreviewSignOut? signOut,
  PreviewRecordSuccessfulLogin? recordSuccessfulLogin,
}) {
  return DevelopmentPreviewSignInService(
    signInWithEmailAndPassword: signInWithEmailAndPassword,
    getCurrentUser: getCurrentUser ?? () => null,
    waitForAuthUser: waitForAuthUser ?? () async => null,
    isApprovedEmail: isApprovedEmail ?? (_) => true,
    signOut: signOut ?? () async {},
    recordSuccessfulLogin: recordSuccessfulLogin ?? (_) async {},
  );
}

void main() {
  group('normalizePreviewEmail', () {
    test('trims and lowercases email', () {
      expect(normalizePreviewEmail('  Jason.Cook@Gmail.COM  '), 'jason.cook@gmail.com');
    });
  });

  group('classifyPreviewSignInFailure', () {
    test('maps invalid-credential to invalidCredential', () {
      expect(
        classifyPreviewSignInFailure(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        PreviewSignInFailureKind.invalidCredential,
      );
    });

    test('maps network-request-failed to networkUnavailable', () {
      expect(
        classifyPreviewSignInFailure(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        PreviewSignInFailureKind.networkUnavailable,
      );
    });

    test('maps web-storage-unsupported to browserSession', () {
      expect(
        classifyPreviewSignInFailure(
          FirebaseAuthException(code: 'web-storage-unsupported'),
        ),
        PreviewSignInFailureKind.browserSession,
      );
    });
  });

  group('userMessageForPreviewSignInFailure', () {
    test('returns distinct messages per failure kind', () {
      expect(
        userMessageForPreviewSignInFailure(
          PreviewSignInFailureKind.invalidCredential,
        ),
        'Incorrect email or password.',
      );
      expect(
        userMessageForPreviewSignInFailure(
          PreviewSignInFailureKind.accessNotApproved,
        ),
        'This account does not have preview access.',
      );
      expect(
        userMessageForPreviewSignInFailure(
          PreviewSignInFailureKind.networkUnavailable,
        ),
        contains('Network unavailable'),
      );
      expect(
        userMessageForPreviewSignInFailure(
          PreviewSignInFailureKind.browserSession,
        ),
        contains('browser could not save'),
      );
      expect(
        userMessageForPreviewSignInFailure(PreviewSignInFailureKind.unknown),
        contains('try again'),
      );
    });
  });

  group('DevelopmentPreviewSignInService', () {
    test('successful preview login returns success', () async {
      final user = _FakeUser('jason.cook@gmail.com');
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          expect(email, 'jason.cook@gmail.com');
          expect(password, 'secret-password');
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => user,
        waitForAuthUser: () async => user,
        isApprovedEmail: (email) => email == 'jason.cook@gmail.com',
      );

      final result = await service.signIn(
        rawEmail: '  Jason.Cook@Gmail.COM ',
        rawPassword: 'secret-password',
      );

      expect(result.success, isTrue);
    });

    test('invalid credential surfaces invalidCredential failure', () async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          throw FirebaseAuthException(code: 'invalid-credential');
        },
      );

      final result = await service.signIn(
        rawEmail: 'jason.cook@gmail.com',
        rawPassword: 'wrong',
      );

      expect(result.success, isFalse);
      expect(result.failureKind, PreviewSignInFailureKind.invalidCredential);
      expect(result.userMessage, contains('Incorrect email or password'));
    });

    test('approved-email rejection signs out and returns accessNotApproved', () async {
      var signedOut = false;
      final user = _FakeUser('other@example.com');
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => user,
        waitForAuthUser: () async => user,
        isApprovedEmail: (_) => false,
        signOut: () async {
          signedOut = true;
        },
      );

      final result = await service.signIn(
        rawEmail: 'other@example.com',
        rawPassword: 'password',
      );

      expect(signedOut, isTrue);
      expect(result.failureKind, PreviewSignInFailureKind.accessNotApproved);
    });

    test('network failure surfaces networkUnavailable', () async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          throw FirebaseAuthException(code: 'network-request-failed');
        },
      );

      final result = await service.signIn(
        rawEmail: 'jason.cook@gmail.com',
        rawPassword: 'password',
      );

      expect(result.failureKind, PreviewSignInFailureKind.networkUnavailable);
    });

    test('missing session after sign-in surfaces browserSession', () async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          return _FakeUserCredential(null);
        },
        getCurrentUser: () => null,
        waitForAuthUser: () async => null,
      );

      final result = await service.signIn(
        rawEmail: 'jason.cook@gmail.com',
        rawPassword: 'password',
      );

      expect(result.failureKind, PreviewSignInFailureKind.browserSession);
    });

    test('session lost after approval surfaces browserSession', () async {
      final user = _FakeUser('jason.cook@gmail.com');
      User? currentUser = user;
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => currentUser,
        waitForAuthUser: () async => user,
        isApprovedEmail: (_) => true,
        recordSuccessfulLogin: (_) async {
          currentUser = null;
        },
      );

      final result = await service.signIn(
        rawEmail: 'jason.cook@gmail.com',
        rawPassword: 'password',
      );

      expect(result.failureKind, PreviewSignInFailureKind.browserSession);
    });
  });

  group('DevelopmentPreviewSignInDialog widget', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required DevelopmentPreviewSignInService signInService,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => DevelopmentPreviewSignInDialog(
                        signInService: signInService,
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('successful mobile-sized flow dismisses dialog', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final user = _FakeUser('jason.cook@gmail.com');
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => user,
        waitForAuthUser: () async => user,
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'jason.cook@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(DevelopmentPreviewSignInDialog), findsNothing);
    });

    testWidgets('invalid credential shows specific message', (tester) async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          throw FirebaseAuthException(code: 'wrong-password');
        },
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'jason.cook@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('duplicate submit prevention calls sign-in once', (tester) async {
      var signInCalls = 0;
      final completer = Completer<void>();
      final user = _FakeUser('jason.cook@gmail.com');

      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          signInCalls++;
          await completer.future;
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => user,
        waitForAuthUser: () async => user,
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'jason.cook@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');

      final signInButton = find.byType(DrinkSpotButton);
      await tester.tap(signInButton);
      await tester.pump();
      await tester.tap(signInButton);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(signInCalls, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('loading state always clears after failure', (tester) async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          throw FirebaseAuthException(code: 'network-request-failed');
        },
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'jason.cook@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Signing in…'), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('desktop behaviour shows access-not-approved message', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final user = _FakeUser('other@example.com');
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          return _FakeUserCredential(user);
        },
        getCurrentUser: () => user,
        waitForAuthUser: () async => user,
        isApprovedEmail: (_) => false,
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'other@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('This account does not have preview access.'),
        findsOneWidget,
      );
      expect(find.byType(DevelopmentPreviewSignInDialog), findsOneWidget);
    });

    testWidgets('unknown errors show generic user message only', (tester) async {
      final service = _testService(
        signInWithEmailAndPassword: ({required email, required password}) async {
          throw StateError('unexpected');
        },
      );

      await pumpDialog(tester, signInService: service);
      await tester.enterText(find.byType(TextFormField).at(0), 'jason.cook@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sign-in failed. Please try again in a moment.'),
        findsOneWidget,
      );
      expect(find.textContaining('Diagnostic:'), findsNothing);
    });
  });
}
