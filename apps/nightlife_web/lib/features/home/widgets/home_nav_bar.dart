import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/vexda_logo.dart';
import '../../../shared/layouts/content_container.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import 'home_layout.dart';

/// Fixed public navigation — full-width dark glass on homepage.
class HomeNavBar extends StatelessWidget {
  const HomeNavBar({
    super.key,
    this.activeRoute,
    this.fullWidth = false,
  });

  final String? activeRoute;
  final bool fullWidth;

  static const double _desktopHeight = 80;

  String _resolveActiveRoute(BuildContext context) {
    final route =
        activeRoute ?? ModalRoute.of(context)?.settings.name ?? AppRouter.home;
    if (route.startsWith(AppRouter.venuePrefix)) return AppRouter.map;
    return route;
  }

  void _navigate(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final showNavLinks = !isMobile;
    final logoHeight = fullWidth ? (isMobile ? 44.0 : 52.0) : Breakpoints.logoHeight(context);
    final barHeight = fullWidth
        ? (isMobile ? 64.0 : _desktopHeight)
        : logoHeight + AppSpacing.navBarInnerPadding;
    final currentRoute = _resolveActiveRoute(context);

    final barContent = SizedBox(
      height: barHeight,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _navigate(context, AppRouter.home),
              child: VexdaLogo(height: logoHeight),
            ),
          ),
          if (showNavLinks)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AppStrings.publicNavLinks
                        .map(
                          (link) => _NavLink(
                            label: link.label,
                            active: currentRoute == link.route,
                            onTap: () => _navigate(context, link.route),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          _NavActions(compact: isMobile),
        ],
      ),
    );

    if (fullWidth) {
      return Material(
        color: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.82),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryPurple.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
              child: ContentContainer(
                maxWidth: HomeLayout.maxContentWidth(context),
                child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
                    ),
                    child: barContent,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.navBarOuterPadding),
          child: ContentContainer(
            child: _LegacyGlassNav(child: barContent),
          ),
        ),
      ),
    );
  }
}

class _LegacyGlassNav extends StatelessWidget {
  const _LegacyGlassNav({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.navBarInnerPadding,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.active
                    ? AppColors.primaryPink
                    : Colors.transparent,
                width: 2,
              ),
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: highlighted ? AppColors.white : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavActions extends StatelessWidget {
  const _NavActions({required this.compact});

  final bool compact;

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user != null) {
          return StreamBuilder<UserRoleProfile>(
            stream: UserRoleService.currentUserProfileStream(),
            builder: (context, roleSnapshot) {
              final cached = UserRoleService.peekCachedProfile(user.uid);
              final profile = roleSnapshot.data ?? cached;
              final resolving = profile == null &&
                  roleSnapshot.connectionState == ConnectionState.waiting;
              final role = profile?.role ?? VexdaUserRole.regularUser;
              final showDashboard = resolving ||
                  role.canAccessVenueDashboard ||
                  role.canAccessAdminDashboard;
              final displayName = AuthService.getDisplayName(user);

              if (profile != null) {
                UserRoleService.debugLogDashboardButtonVisibility(
                  uid: user.uid,
                  visible: showDashboard,
                  role: role,
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDashboard)
                    _NavStaffLink(
                      compact: compact,
                      label: 'Dashboard',
                      onTap: () async {
                        final resolved = profile ??
                            await UserRoleService.getCurrentUserProfile();
                        if (!context.mounted) return;
                        Navigator.pushNamed(
                          context,
                          UserRoleService.routeForRole(resolved.role),
                        );
                      },
                    ),
                  if (showDashboard)
                    SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                  _GlassAccountButton(
                    compact: compact,
                    label: displayName,
                    onPressed: () => Navigator.pushNamed(context, AppRouter.account),
                  ),
                  SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                  _GlassLoginButton(
                    compact: compact,
                    label: AppStrings.logout,
                    onPressed: () => _logout(context),
                  ),
                  SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                  _GradientDownloadButton(
                    compact: compact,
                    onPressed: () => Navigator.pushNamed(context, AppRouter.download),
                  ),
                ],
              );
            },
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassLoginButton(
              compact: compact,
              label: AppStrings.login,
              onPressed: () => Navigator.pushNamed(context, AppRouter.login),
            ),
            SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
            _GradientDownloadButton(
              compact: compact,
              onPressed: () => Navigator.pushNamed(context, AppRouter.download),
            ),
          ],
        );
      },
    );
  }
}

class _NavStaffLink extends StatefulWidget {
  const _NavStaffLink({
    required this.compact,
    required this.label,
    required this.onTap,
  });

  final bool compact;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavStaffLink> createState() => _NavStaffLinkState();
}

class _NavStaffLinkState extends State<_NavStaffLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hovered ? AppColors.primaryPink : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: widget.compact ? 13 : 14,
          ),
        ),
      ),
    );
  }
}

class _GlassAccountButton extends StatefulWidget {
  const _GlassAccountButton({
    required this.compact,
    required this.label,
    required this.onPressed,
  });

  final bool compact;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GlassAccountButton> createState() => _GlassAccountButtonState();
}

class _GlassAccountButtonState extends State<_GlassAccountButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: AppColors.primaryPurple.withValues(alpha: _hovered ? 0.22 : 0.12),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: _hovered ? 0.55 : 0.28),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassLoginButton extends StatefulWidget {
  const _GlassLoginButton({
    required this.compact,
    required this.onPressed,
    required this.label,
  });

  final bool compact;
  final VoidCallback onPressed;
  final String label;

  @override
  State<_GlassLoginButton> createState() => _GlassLoginButtonState();
}

class _GlassLoginButtonState extends State<_GlassLoginButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 14 : 20,
            vertical: widget.compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _hovered
                  ? AppColors.primaryPurple.withValues(alpha: 0.6)
                  : AppColors.glassBorder,
            ),
            color: AppColors.surface.withValues(alpha: _hovered ? 0.55 : 0.35),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? AppColors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientDownloadButton extends StatefulWidget {
  const _GradientDownloadButton({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  State<_GradientDownloadButton> createState() => _GradientDownloadButtonState();
}

class _GradientDownloadButtonState extends State<_GradientDownloadButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 22,
              vertical: widget.compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(
                    alpha: _hovered ? 0.45 : 0.28,
                  ),
                  blurRadius: _hovered ? 24 : 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              AppStrings.downloadApp,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: widget.compact ? 13 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
