import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Download app landing page with store CTAs.
class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  static const _benefits = [
    'Save venues and sync across devices',
    'Join Tonight\'s Trails with live route guidance',
    'Get deal and event notifications',
    'Plan your perfect night out on the go',
  ];

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicPageHero(
            eyebrow: 'Mobile app',
            title: AppStrings.downloadTitle,
            subtitle: AppStrings.downloadSubtitle,
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
                        child: GlassContainer(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final benefit in _benefits) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.primaryPink,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: [
                                  DrinkSpotButton(
                                    label: 'App Store (coming soon)',
                                    onPressed: () {},
                                  ),
                                  DrinkSpotButton(
                                    label: 'Google Play (coming soon)',
                                    variant: DrinkSpotButtonVariant.secondary,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isWide ? AppSpacing.xl : 0, height: isWide ? 0 : AppSpacing.xl),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  border: Border.all(color: AppColors.glassBorder),
                                  gradient: AppColors.brandGradient,
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 96,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Text(
                                'Scan to download',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              DrinkSpotButton(
                                label: 'Explore on web',
                                variant: DrinkSpotButtonVariant.ghost,
                                onPressed: () => Navigator.pushNamed(context, AppRouter.map),
                              ),
                            ],
                          ),
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
