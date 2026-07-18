import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../auth/services/auth_service.dart';

/// Protected route requirements checked through VexCore identity and permissions.
enum AuthGuardRequirement { admin, venueStaff }

/// Wraps staff dashboards with Firebase Auth + VexCore identity resolution.
///
/// Authentication session: [WebVexCore.authentication]
/// Identity resolution: [WebVexCore.identity]
/// Route access: [WebVexCore.permissionEvaluator] via [VexPermission.accessAdminPortal]
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.requirement, required this.child});

  final AuthGuardRequirement requirement;
  final Widget child;

  VexPermission get _requiredPermission {
    return switch (requirement) {
      AuthGuardRequirement.admin => VexPermission.accessAdminPortal,
      AuthGuardRequirement.venueStaff => VexPermission.manageVenue,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthenticatedUser?>(
      stream: WebVexCore.authentication.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const PublicPageShell(
            child: PublicLoadingState(message: 'Checking your session…'),
          );
        }

        final authUser = authSnapshot.data;
        if (authUser == null) {
          return PublicPageShell(
            child: _AuthPrompt(
              title: 'Sign in required',
              message:
                  'Sign in with your Vexda staff account to access this dashboard.',
              actionLabel: AppStrings.login,
              onAction: () => Navigator.pushNamed(context, AppRouter.login),
            ),
          );
        }

        return _PermissionGate(
          uid: authUser.uid,
          requiredPermission: _requiredPermission,
          child: child,
        );
      },
    );
  }
}

class _PermissionGate extends StatefulWidget {
  const _PermissionGate({
    required this.uid,
    required this.requiredPermission,
    required this.child,
  });

  final String uid;
  final VexPermission requiredPermission;
  final Widget child;

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  static const _resolutionTimeout = Duration(seconds: 10);

  final _identityAdapter = WebVexCore.identity;
  final _permissionEvaluator = WebVexCore.permissionEvaluator;

  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _retrying = false;
  String? _retryError;

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

  Future<bool> _isAllowed(VexIdentity identity) async {
    final decision = await _permissionEvaluator.evaluate(
      identity: identity,
      permission: widget.requiredPermission,
    );
    return decision.isAllowed;
  }

  bool _isAllowedSync(VexIdentity identity) {
    return switch (widget.requiredPermission) {
      VexPermission.accessAdminPortal => RouteAccess.canAccessAdminPortal(
        identity,
      ),
      VexPermission.manageVenue => RouteAccess.canAccessVenueDashboard(identity),
      _ => false,
    };
  }

  Future<void> _retryResolution() async {
    setState(() {
      _retrying = true;
      _retryError = null;
    });
    _startTimeout();

    try {
      final identity = await _identityAdapter.retryIdentityResolution(
        widget.uid,
      );
      if (!mounted) return;
      _clearTimeout();
      final allowed = identity != null && await _isAllowed(identity);
      setState(() {
        _retrying = false;
        if (!allowed) {
          _retryError = AppStrings.staffAccessDenied;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _retrying = false;
        _retryError = 'Could not load your permissions. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VexIdentity?>(
      stream: _identityAdapter.currentIdentityStream,
      builder: (context, identitySnapshot) {
        final cached = _identityAdapter.peekCachedIdentity(widget.uid);
        final identity = identitySnapshot.data ?? cached;
        final waitingForFirstIdentity =
            identity == null &&
            identitySnapshot.connectionState == ConnectionState.waiting;

        if (identity != null) {
          _clearTimeout();
        }

        if (waitingForFirstIdentity && !_timedOut) {
          return const PublicPageShell(
            child: PublicLoadingState(message: 'Loading your permissions…'),
          );
        }

        if (identity == null && (_timedOut || identitySnapshot.hasError)) {
          return PublicPageShell(
            child: _AuthPrompt(
              title: 'Permissions unavailable',
              message:
                  _retryError ??
                  'We could not confirm your dashboard access. Please try again.',
              actionLabel: _retrying ? 'Retrying…' : 'Retry',
              onAction: _retrying ? () {} : _retryResolution,
              secondaryLabel: AppStrings.logout,
              onSecondary: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.home,
                  (_) => false,
                );
              },
            ),
          );
        }

        if (identity == null || identity.uid != widget.uid) {
          return const PublicPageShell(
            child: PublicLoadingState(message: 'Loading your permissions…'),
          );
        }

        final allowed = _isAllowedSync(identity);
        if (!allowed) {
          return PublicPageShell(
            child: _AuthPrompt(
              title: 'Access restricted',
              message: AppStrings.staffAccessDenied,
              actionLabel: 'Go to home',
              onAction: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.home,
                (_) => false,
              ),
              secondaryLabel: AppStrings.logout,
              onSecondary: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.home,
                  (_) => false,
                );
              },
            ),
          );
        }

        return widget.child;
      },
    );
  }
}

class _AuthPrompt extends StatelessWidget {
  const _AuthPrompt({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                DrinkSpotButton(label: actionLabel, onPressed: onAction),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  DrinkSpotButton(
                    label: secondaryLabel!,
                    variant: DrinkSpotButtonVariant.ghost,
                    onPressed: onSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
