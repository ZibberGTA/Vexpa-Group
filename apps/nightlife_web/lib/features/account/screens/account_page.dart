import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Account page — public when signed out, profile summary when signed in.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const _benefits = [
    (icon: Icons.bookmark_outline_rounded, title: 'Saved venues', detail: 'Bookmark your favourite spots across web and mobile.'),
    (icon: Icons.notifications_active_outlined, title: 'Notifications', detail: 'Get alerts for deals, events and trail updates.'),
    (icon: Icons.route_outlined, title: 'Trails', detail: 'Join Tonight\'s Trails and track your route progress.'),
    (icon: Icons.tune_rounded, title: 'Personalisation', detail: 'Tailored discovery based on your nights out.'),
  ];

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicPageHero(
            eyebrow: 'Your account',
            title: AppStrings.accountTitle,
            subtitle: AppStrings.accountSubtitle,
            trailing: StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user != null) {
                  return DrinkSpotButton(
                    label: AppStrings.logout,
                    variant: DrinkSpotButtonVariant.secondary,
                    onPressed: () => _logout(context),
                  );
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DrinkSpotButton(
                      label: AppStrings.login,
                      onPressed: () => Navigator.pushNamed(context, AppRouter.login),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    DrinkSpotButton(
                      label: AppStrings.downloadApp,
                      variant: DrinkSpotButtonVariant.secondary,
                      onPressed: () => Navigator.pushNamed(context, AppRouter.download),
                    ),
                  ],
                );
              },
            ),
          ),
          ContentContainer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 3 : 0,
                        child: StreamBuilder<User?>(
                          stream: AuthService.authStateChanges,
                          builder: (context, authSnapshot) {
                            final user = authSnapshot.data;
                            if (user == null) {
                              return GlassContainer(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sign in to sync with mobile',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    const Text(
                                      'Use your existing Vexda email and password. Public browsing stays open — '
                                      'sign in when you want saved venues, staff dashboards, or account features.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14.5,
                                        height: 1.55,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    DrinkSpotButton(
                                      label: AppStrings.login,
                                      onPressed: () => Navigator.pushNamed(context, AppRouter.login),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return StreamBuilder<UserRoleProfile>(
                              stream: UserRoleService.currentUserProfileStream(),
                              builder: (context, roleSnapshot) {
                                final profile = roleSnapshot.data;
                                final role = profile?.role ?? VexdaUserRole.regularUser;
                                final email = user.email ?? 'No email on file';

                                return GlassContainer(
                                  padding: const EdgeInsets.all(AppSpacing.xxl),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AuthService.getDisplayName(user),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      _AccountDetailRow(label: 'Role', value: role.label),
                                      const SizedBox(height: AppSpacing.xl),
                                      if (role.canAccessAdminDashboard)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                          child: DrinkSpotButton(
                                            label: 'Open admin dashboard',
                                            onPressed: () => Navigator.pushNamed(context, AppRouter.admin),
                                          ),
                                        ),
                                      if (role.canAccessVenueDashboard)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                          child: DrinkSpotButton(
                                            label: 'Open venue management',
                                            variant: DrinkSpotButtonVariant.secondary,
                                            onPressed: () => Navigator.pushNamed(context, AppRouter.venueDashboard),
                                          ),
                                        ),
                                      DrinkSpotButton(
                                        label: AppStrings.logout,
                                        variant: DrinkSpotButtonVariant.ghost,
                                        onPressed: () => _logout(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(width: isWide ? AppSpacing.xl : 0, height: isWide ? 0 : AppSpacing.xl),
                      Expanded(
                        flex: isWide ? 4 : 0,
                        child: Column(
                          children: _benefits
                              .map(
                                (benefit) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          benefit.icon,
                                          color: AppColors.primaryPink,
                                          size: 24,
                                        ),
                                        const SizedBox(width: AppSpacing.lg),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                benefit.title,
                                                style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text(
                                                benefit.detail,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 13.5,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
