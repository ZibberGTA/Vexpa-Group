import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/pill_tag.dart';
import '../../../shared/widgets/positioned_venue_image.dart';
import '../models/venue_details_view.dart';

/// Cinematic venue header with banner, floating logo, glass info layer and actions.
class VenueDetailsHero extends StatelessWidget {
  const VenueDetailsHero({
    super.key,
    required this.venue,
    required this.onBackToSearch,
  });

  final VenueDetailsView venue;
  final VoidCallback onBackToSearch;

  static const _bottomRadius = BorderRadius.only(
    bottomLeft: Radius.circular(AppSpacing.radiusXl),
    bottomRight: Radius.circular(AppSpacing.radiusXl),
  );

  @override
  Widget build(BuildContext context) {
    final screen = Breakpoints.of(context);

    final bannerHeight = switch (screen) {
      ScreenSize.desktop => 400.0,
      ScreenSize.tablet => 320.0,
      ScreenSize.mobile => 240.0,
    };
    final logoSize = switch (screen) {
      ScreenSize.desktop => 104.0,
      ScreenSize.tablet => 88.0,
      ScreenSize.mobile => 76.0,
    };
    final logoOverlap = logoSize * 0.52;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CinematicBanner(
              venue: venue,
              height: bannerHeight,
              borderRadius: _bottomRadius,
            ),
            Positioned(
              left: AppSpacing.lg,
              bottom: -logoOverlap,
              child: _FloatingLogo(venue: venue, size: logoSize),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.lg,
              child: _GlowAccent(
                size: screen == ScreenSize.desktop ? 120 : 88,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
        SizedBox(height: logoOverlap + AppSpacing.md),
        _GlassInfoLayer(
          venue: venue,
          logoSize: logoSize,
          onBackToSearch: onBackToSearch,
        ),
      ],
    );
  }
}

class _CinematicBanner extends StatefulWidget {
  const _CinematicBanner({
    required this.venue,
    required this.height,
    required this.borderRadius,
  });

  final VenueDetailsView venue;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<_CinematicBanner> createState() => _CinematicBannerState();
}

class _CinematicBannerState extends State<_CinematicBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lightController;

  @override
  void initState() {
    super.initState();
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.venue.bannerImageUrl != null)
              FramedVenueImage(
                imageUrl: widget.venue.bannerImageUrl,
                metadata: widget.venue.bannerImagePosition,
                fallback: const _HeroGradientFallback(),
              )
            else
              const _HeroGradientFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.52),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _lightController,
              builder: (context, child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        -0.8 + (_lightController.value * 0.4),
                        -1,
                      ),
                      end: Alignment(0.8 - (_lightController.value * 0.4), 1),
                      colors: [
                        AppColors.primaryPink.withValues(
                          alpha: 0.08 + (_lightController.value * 0.1),
                        ),
                        Colors.transparent,
                        AppColors.primaryPurple.withValues(
                          alpha: 0.12 + ((1 - _lightController.value) * 0.12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: -40,
              bottom: -20,
              child: _GlowAccent(size: 160, color: AppColors.primaryPink),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGradientFallback extends StatelessWidget {
  const _HeroGradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1054), Color(0xFF1A0B2E), Color(0xFF9D28FF)],
        ),
      ),
    );
  }
}

class _GlowAccent extends StatelessWidget {
  const _GlowAccent({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: size * 0.55,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.venue, required this.size});

  final VenueDetailsView venue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = venue.logoUrl?.trim() ?? '';
    final hasLogo = logoUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasLogo ? null : AppColors.brandGradient,
        color: hasLogo ? AppColors.background.withValues(alpha: 0.72) : null,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.32),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: hasLogo
            ? FramedVenueImage(
                imageUrl: logoUrl,
                metadata: venue.logoImagePosition,
                circular: true,
                fallback: _LogoInitial(name: venue.name, size: size),
              )
            : _LogoInitial(name: venue.name, size: size),
      ),
    );
  }
}

class _LogoInitial extends StatelessWidget {
  const _LogoInitial({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassInfoLayer extends StatelessWidget {
  const _GlassInfoLayer({
    required this.venue,
    required this.logoSize,
    required this.onBackToSearch,
  });

  final VenueDetailsView venue;
  final double logoSize;
  final VoidCallback onBackToSearch;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final logoInset = logoSize + AppSpacing.sm;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              logoInset,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VenueIdentity(venue: venue, compact: isMobile),
                const SizedBox(height: AppSpacing.md),
                _HeroMetaRow(venue: venue),
                if (venue.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (var i = 0; i < venue.tags.take(3).length; i++)
                        PillTag(label: venue.tags[i], highlighted: i == 0),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _HeroActions(
                  venue: venue,
                  onViewOnMap: () {
                    Navigator.of(context).pushNamed(AppRouter.search);
                  },
                  onPlaceholder: (label) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label coming soon'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueIdentity extends StatelessWidget {
  const _VenueIdentity({required this.venue, required this.compact});

  final VenueDetailsView venue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 26.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          venue.displayCategory,
          style: TextStyle(
            color: AppColors.primaryPink,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          venue.name,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 15,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                venue.locationLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({required this.venue});

  final VenueDetailsView venue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _MetaChip(
          icon: Icons.star_rounded,
          label: venue.rating.toStringAsFixed(1),
          accent: AppColors.trailGold,
        ),
        _MetaChip(
          icon: venue.isOpen ? Icons.circle : Icons.circle_outlined,
          label: venue.isOpen ? 'Open now' : 'Closed',
          accent: venue.isOpen
              ? AppColors.primaryPink
              : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.venue,
    required this.onViewOnMap,
    required this.onPlaceholder,
  });

  final VenueDetailsView venue;
  final VoidCallback onViewOnMap;
  final ValueChanged<String> onPlaceholder;

  Future<void> _openDirections() async {
    if (!venue.hasCoordinates) {
      onPlaceholder('Get directions');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${venue.latitude},${venue.longitude}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      onPlaceholder('Get directions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    final primaryButtons = [
      DrinkSpotButton(
        label: 'Get directions',
        icon: Icons.directions_outlined,
        variant: DrinkSpotButtonVariant.primary,
        compact: isMobile,
        onPressed: _openDirections,
      ),
    ];

    final secondaryButtons = [
      DrinkSpotButton(
        label: 'Save venue',
        icon: Icons.bookmark_border_rounded,
        variant: DrinkSpotButtonVariant.secondary,
        compact: isMobile,
        onPressed: () => onPlaceholder('Save venue'),
      ),
      DrinkSpotButton(
        label: 'Share',
        icon: Icons.ios_share_rounded,
        variant: DrinkSpotButtonVariant.ghost,
        compact: isMobile,
        onPressed: () => onPlaceholder('Share'),
      ),
      DrinkSpotButton(
        label: 'View on map',
        icon: Icons.map_outlined,
        variant: DrinkSpotButtonVariant.ghost,
        compact: isMobile,
        onPressed: onViewOnMap,
      ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [...primaryButtons, ...secondaryButtons],
    );
  }
}
