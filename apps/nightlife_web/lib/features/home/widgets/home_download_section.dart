import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_section.dart';

/// Premium download CTA with store buttons, QR and lifestyle panel.
class HomeDownloadSection extends StatelessWidget {
  const HomeDownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isDesktop = Breakpoints.isDesktop(context);

    return HomeSection(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isMobile ? AppSpacing.xl : (isDesktop ? AppSpacing.xxl : AppSpacing.xxxl),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              color: AppColors.surface.withValues(alpha: 0.5),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.18),
                  blurRadius: 32,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;

                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: isWide ? 3 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.homeDownloadTitle,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isMobile ? 30 : 38,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            AppStrings.homeDownloadSubtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: isWide ? AppSpacing.xxl : 0,
                      height: isWide ? 0 : AppSpacing.xl,
                    ),
                    Expanded(
                      flex: isWide ? 2 : 0,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          _StoreButton(
                            label: 'App Store',
                            icon: Icons.apple,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRouter.download),
                          ),
                          _StoreButton(
                            label: 'Google Play',
                            icon: Icons.android,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRouter.download),
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                              gradient: AppColors.brandGradient,
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: AppColors.white,
                              size: 52,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: isWide ? AppSpacing.xxl : 0,
                      height: isWide ? 0 : AppSpacing.xl,
                    ),
                    Expanded(
                      flex: isWide ? 3 : 0,
                      child: Container(
                        height: isWide ? 180 : 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryPink.withValues(alpha: 0.35),
                              AppColors.primaryPurple.withValues(alpha: 0.45),
                              AppColors.deepPurple.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.nightlife,
                                size: 40,
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Your night out awaits',
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreButton extends StatefulWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_StoreButton> createState() => _StoreButtonState();
}

class _StoreButtonState extends State<_StoreButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface.withValues(alpha: _hovered ? 0.75 : 0.5),
            border: Border.all(
              color: _hovered
                  ? AppColors.primaryPink.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
