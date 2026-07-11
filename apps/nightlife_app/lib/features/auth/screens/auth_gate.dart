import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/vexcore/mobile_vexcore.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../navigation/main_navigation_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// App entry gate using VexCore authentication and identity services.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    @visibleForTesting this.mainNavigationBuilder,
    @visibleForTesting this.adminDashboardBuilder,
  });

  @visibleForTesting
  final WidgetBuilder? mainNavigationBuilder;

  @visibleForTesting
  final WidgetBuilder? adminDashboardBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthenticatedUser?>(
      stream: MobileVexCore.authentication.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen(message: 'Checking your account...');
        }

        if (!authSnapshot.hasData) {
          return FutureBuilder<void>(
            future: AuthService.signInAnonymouslyIfNeeded(),
            builder: (context, guestSnapshot) {
              if (guestSnapshot.connectionState != ConnectionState.done) {
                return const _AuthLoadingScreen(
                  message: 'Preparing DrinkSpot...',
                );
              }

              if (guestSnapshot.hasError) {
                return _GuestModeErrorScreen(
                  error: guestSnapshot.error.toString(),
                );
              }

              return _buildMainNavigation(context);
            },
          );
        }

        final authUser = authSnapshot.data!;
        return _SignedInGate(
          uid: authUser.uid,
          mainNavigationBuilder: mainNavigationBuilder,
          adminDashboardBuilder: adminDashboardBuilder,
        );
      },
    );
  }

  Widget _buildMainNavigation(BuildContext context) {
    final builder = mainNavigationBuilder;
    if (builder != null) return builder(context);
    return const MainNavigationScreen();
  }
}

class _SignedInGate extends StatefulWidget {
  const _SignedInGate({
    required this.uid,
    this.mainNavigationBuilder,
    this.adminDashboardBuilder,
  });

  final String uid;
  final WidgetBuilder? mainNavigationBuilder;
  final WidgetBuilder? adminDashboardBuilder;

  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  static const _resolutionTimeout = Duration(seconds: 10);

  final _identity = MobileVexCore.identity;
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timedOut = false;
    _timeoutTimer = Timer(_resolutionTimeout, () {
      if (!mounted) return;
      setState(() => _timedOut = true);
    });
  }

  void _clearTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _timedOut = false;
  }

  Future<void> _retryResolution() async {
    setState(() => _retrying = true);
    _startTimeout();

    try {
      await _identity.retryIdentityResolution(widget.uid);
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  bool _canAccessAdmin(VexIdentity identity) {
    return RouteAccess.canAccessAdminPortal(identity);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VexIdentity?>(
      stream: _identity.currentIdentityStream,
      builder: (context, identitySnapshot) {
        final cached = _identity.peekCachedIdentity(widget.uid);
        final identity = identitySnapshot.data ?? cached;
        final waitingForFirstIdentity = identity == null &&
            identitySnapshot.connectionState == ConnectionState.waiting;

        if (identity != null) {
          _clearTimeout();
        }

        if (waitingForFirstIdentity && !_timedOut) {
          return const _AuthLoadingScreen(
            message: 'Loading your dashboard...',
          );
        }

        if (identity == null && (_timedOut || identitySnapshot.hasError)) {
          return _AuthRetryScreen(
            retrying: _retrying,
            onRetry: _retrying ? null : _retryResolution,
          );
        }

        if (identity != null && _canAccessAdmin(identity)) {
          final builder = widget.adminDashboardBuilder;
          if (builder != null) return builder(context);
          return const AdminDashboardScreen();
        }

        final builder = widget.mainNavigationBuilder;
        if (builder != null) return builder(context);
        return const MainNavigationScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthRetryScreen extends StatelessWidget {
  const _AuthRetryScreen({
    required this.retrying,
    required this.onRetry,
  });

  final bool retrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Permissions unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'We could not confirm your dashboard access. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(retrying ? 'Retrying…' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestModeErrorScreen extends StatelessWidget {
  const _GuestModeErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'DrinkSpot could not start guest mode.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
                child: const Text('Sign in instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
