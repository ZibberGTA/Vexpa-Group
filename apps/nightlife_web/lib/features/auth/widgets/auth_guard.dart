import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';

/// Protected route requirements checked against Firestore roles.
enum AuthGuardRequirement { admin, venueStaff }

/// Wraps staff dashboards with Firebase Auth + Firestore role checks.
///
/// Firebase Auth session: [AuthService.authStateChanges]
/// Firestore role resolution: [UserRoleService.currentUserProfileStream]
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.requirement, required this.child});

  final AuthGuardRequirement requirement;
  final Widget child;

  bool _isAllowed(VexdaUserRole role) {
    return switch (requirement) {
      AuthGuardRequirement.admin => role.canAccessAdminDashboard,
      AuthGuardRequirement.venueStaff => role.canAccessVenueDashboard,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const PublicPageShell(
            child: PublicLoadingState(message: 'Checking your session…'),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
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

        return _PermissionGate(user: user, isAllowed: _isAllowed, child: child);
      },
    );
  }
}

class _PermissionGate extends StatefulWidget {
  const _PermissionGate({
    required this.user,
    required this.isAllowed,
    required this.child,
  });

  final User user;
  final bool Function(VexdaUserRole role) isAllowed;
  final Widget child;

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  static const _resolutionTimeout = Duration(seconds: 10);

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

  Future<void> _retryResolution() async {
    setState(() {
      _retrying = true;
      _retryError = null;
    });
    _startTimeout();

    try {
      final profile = await UserRoleService.retryRoleResolution(widget.user);
      if (!mounted) return;
      _clearTimeout();
      setState(() {
        _retrying = false;
        if (!widget.isAllowed(profile.role)) {
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
    return StreamBuilder<UserRoleProfile>(
      stream: UserRoleService.currentUserProfileStream(),
      builder: (context, roleSnapshot) {
        final cached = UserRoleService.peekCachedProfile(widget.user.uid);
        final profile = roleSnapshot.data ?? cached;
        final waitingForFirstProfile =
            profile == null &&
            roleSnapshot.connectionState == ConnectionState.waiting;

        if (profile != null) {
          _clearTimeout();
        }

        if (waitingForFirstProfile && !_timedOut) {
          return const PublicPageShell(
            child: PublicLoadingState(message: 'Loading your permissions…'),
          );
        }

        if (profile == null && (_timedOut || roleSnapshot.hasError)) {
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

        final role = profile?.role ?? VexdaUserRole.regularUser;
        if (!widget.isAllowed(role)) {
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
                const SizedBox(height: AppSpacing.xl),
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
