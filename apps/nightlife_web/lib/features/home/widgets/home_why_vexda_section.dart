import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_layout.dart';
import 'home_section.dart';

/// Four-panel “Why Vexda?” section aligned to the homepage grid.
class HomeWhyVexdaSection extends StatelessWidget {
  const HomeWhyVexdaSection({super.key});

  static const _panels = [
    (
      title: 'Discover',
      body: 'Stop searching everywhere. Vexda brings the best of your night to you.',
      icon: Icons.explore_outlined,
    ),
    (
      title: 'Explore',
      body: 'From hidden gems to popular hotspots, explore what\'s around you.',
      icon: Icons.location_on_outlined,
    ),
    (
      title: 'Grow',
      body:
          'We help venues get seen by more people and build stronger local communities.',
      icon: Icons.trending_up_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isDesktop = Breakpoints.isDesktop(context);

    return HomeSection(
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.whyVexdaTitle,
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(
            height: isDesktop
                ? HomeLayout.gapWhyHeadingToCards
                : AppSpacing.xl,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;
              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _panels.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < _panels.length ? HomeLayout.gridGutter : 0,
                            ),
                            child: _WhyPanel(
                              title: _panels[i].title,
                              body: _panels[i].body,
                              icon: _panels[i].icon,
                              minHeight: isDesktop
                                  ? HomeLayout.whyPanelMinHeightDesktop
                                  : null,
                            ),
                          ),
                        ),
                      SizedBox(width: HomeLayout.gridGutter),
                      Expanded(
                        child: _VedaHighlightPanel(
                          minHeight: isDesktop
                              ? HomeLayout.whyPanelMinHeightDesktop
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final panel in _panels)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _WhyPanel(
                        title: panel.title,
                        body: panel.body,
                        icon: panel.icon,
                      ),
                    ),
                  const _VedaHighlightPanel(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WhyPanel extends StatefulWidget {
  const _WhyPanel({
    required this.title,
    required this.body,
    required this.icon,
    this.minHeight,
  });

  final String title;
  final String body;
  final IconData icon;
  final double? minHeight;

  @override
  State<_WhyPanel> createState() => _WhyPanelState();
}

class _WhyPanelState extends State<_WhyPanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: widget.minHeight != null
            ? BoxConstraints(minHeight: widget.minHeight!)
            : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          color: AppColors.surface.withValues(alpha: _hovered ? 0.65 : 0.45),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryPink.withValues(alpha: 0.4)
                : AppColors.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              color: _hovered ? AppColors.primaryPink : AppColors.primaryPurple,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VedaHighlightPanel extends StatelessWidget {
  const _VedaHighlightPanel({this.minHeight});

  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: minHeight != null
              ? BoxConstraints(minHeight: minHeight!)
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 28,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPink.withValues(alpha: 0.28),
                AppColors.primaryPurple.withValues(alpha: 0.38),
                AppColors.deepPurple.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryPink.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For People. For Venues. For Nights Out.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Venue Experience.\nDiscovery.\nAdvertising.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'That\'s the Vexda difference.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
