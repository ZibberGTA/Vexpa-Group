import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Angled phone mockups and floating feature card for the homepage hero.
class HomeHeroPhones extends StatelessWidget {
  const HomeHeroPhones({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = Breakpoints.isDesktop(context) ? 1.08 : 1.0;

    return SizedBox(
      height: 440,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 24,
                top: 48,
                child: Transform.rotate(
                  angle: -0.11,
                  child: const _PhoneMockup(variant: _PhoneVariant.discovery),
                ),
              ),
              Positioned(
                right: 72,
                top: 8,
                child: Transform.rotate(
                  angle: 0.09,
                  child: const _PhoneMockup(variant: _PhoneVariant.map),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 36,
                child: const _HeroFeatureCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PhoneVariant { discovery, map }

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.variant});

  final _PhoneVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 390,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.deepPurple.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: variant == _PhoneVariant.discovery
              ? const _DiscoveryScreenMock()
              : const _MapScreenMock(),
        ),
      ),
    );
  }
}

class _DiscoveryScreenMock extends StatelessWidget {
  const _DiscoveryScreenMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 14,
                color: AppColors.primaryPink.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Search tonight...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MiniCard(
          colors: [AppColors.primaryPink, AppColors.primaryPurple],
          title: 'Neon Room',
          subtitle: 'Cocktails · Live DJ',
        ),
        const SizedBox(height: 8),
        _MiniCard(
          colors: [AppColors.primaryPurple, AppColors.deepPurple],
          title: 'Skyline Bar',
          subtitle: 'Rooftop · Open now',
        ),
        const SizedBox(height: 8),
        _MiniCard(
          colors: [AppColors.deepPurple, AppColors.surface],
          title: 'Jazz Lounge',
          subtitle: 'Live music tonight',
        ),
      ],
    );
  }
}

class _MapScreenMock extends StatelessWidget {
  const _MapScreenMock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1B1530),
                AppColors.background,
              ],
            ),
          ),
        ),
        ...List.generate(5, (index) {
          final angle = index * 1.2;
          return Positioned(
            left: 30 + math.cos(angle) * 40 + index * 18.0,
            top: 60 + math.sin(angle) * 30 + index * 22.0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        }),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venue nearby',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '0.3 mi · Open now',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.colors,
    required this.title,
    required this.subtitle,
  });

  final List<Color> colors;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: colors),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFeatureCard extends StatelessWidget {
  const _HeroFeatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: AppColors.surface.withValues(alpha: 0.78),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.primaryPink.withValues(alpha: 0.95),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.heroFeatureCardTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...AppStrings.heroFeatureCardItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primaryPink.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact single-phone mockup for mobile hero.
class HomeHeroPhoneCompact extends StatelessWidget {
  const HomeHeroPhoneCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: 0.06,
        child: const _PhoneMockup(variant: _PhoneVariant.discovery),
      ),
    );
  }
}
