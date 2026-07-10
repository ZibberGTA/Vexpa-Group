import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../components/drinkspot_nav_link.dart';
import '../components/vexda_logo.dart';
import '../layouts/content_container.dart';

/// Premium minimal footer for the public platform.
class PublicFooter extends StatelessWidget {
  const PublicFooter({super.key});

  static const _socialIcons = [
    Icons.language_rounded,
    Icons.camera_alt_outlined,
    Icons.play_circle_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxl),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: ContentContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VexdaLogo(height: 40),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              AppStrings.footerTagline,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isWide) const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        flex: isWide ? 3 : 0,
                        child: Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.sm,
                          children: AppStrings.footerPrimaryLinks
                              .map(
                                (link) => DrinkSpotNavLink(
                                  label: link.label,
                                  onTap: () {
                                    if (link.route == AppRouter.home) return;
                                    Navigator.pushNamed(context, link.route);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      ..._socialIcons.map(
                        (icon) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Icon(
                            icon,
                            size: 20,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.footerCopyright,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
