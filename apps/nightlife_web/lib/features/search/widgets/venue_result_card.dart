import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/pill_tag.dart';
import '../../../shared/widgets/positioned_venue_image.dart';
import '../models/venue_search_result.dart';

/// Premium venue card for the search results panel.
class VenueResultCard extends StatefulWidget {
  const VenueResultCard({
    super.key,
    required this.venue,
    required this.selected,
    this.matchLine,
    this.onTap,
  });

  final VenueSearchResult venue;
  final bool selected;
  final String? matchLine;
  final VoidCallback? onTap;

  static const _animationDuration = Duration(milliseconds: 180);

  @override
  State<VenueResultCard> createState() => _VenueResultCardState();
}

class _VenueResultCardState extends State<VenueResultCard> {
  bool _hovered = false;

  bool get _elevated => widget.selected || _hovered;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final bannerHeight = isMobile ? 72.0 : 78.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: VenueResultCard._animationDuration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _hovered && !widget.selected ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: _elevated
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(
                      alpha: widget.selected ? 0.38 : 0.12,
                    ),
                    blurRadius: widget.selected ? 32 : 16,
                    spreadRadius: widget.selected ? 1 : 0,
                    offset: Offset(0, widget.selected ? 12 : 8),
                  ),
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(
                      alpha: widget.selected ? 0.24 : 0.06,
                    ),
                    blurRadius: widget.selected ? 28 : 18,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: widget.selected ? AppColors.brandGradient : null,
            border: widget.selected
                ? null
                : Border.all(
                    color: _hovered
                        ? AppColors.primaryPurple.withValues(alpha: 0.58)
                        : AppColors.primaryPurple.withValues(alpha: 0.22),
                    width: _hovered ? 1.3 : 1,
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.selected ? 1.8 : 0),
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(
                widget.selected
                    ? AppSpacing.radiusLg - 1.8
                    : AppSpacing.radiusLg,
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  widget.selected
                      ? AppSpacing.radiusLg - 1.8
                      : AppSpacing.radiusLg,
                ),
                hoverColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.selected
                        ? AppSpacing.radiusLg - 1.8
                        : AppSpacing.radiusLg,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BannerSection(
                            venue: widget.venue,
                            height: bannerHeight,
                            selected: widget.selected,
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg + 2,
                              AppSpacing.md,
                              AppSpacing.sm + 2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.venue.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: isMobile ? 14.5 : 15.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.venue.locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: 6,
                                  children: [
                                    _OpenBadge(isOpen: widget.venue.isOpen),
                                    for (
                                      var i = 0;
                                      i < widget.venue.tags.take(3).length;
                                      i++
                                    )
                                      PillTag(
                                        label: widget.venue.tags[i],
                                        highlighted: i == 0,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: widget.selected
                                          ? AppColors.primaryPink
                                          : AppColors.primaryPurple.withValues(
                                              alpha: 0.85,
                                            ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        widget.matchLine ??
                                            widget.venue.resultReason,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.selected
                                              ? AppColors.white
                                              : AppColors.textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        top: bannerHeight - 20,
                        child: _FloatingLogo(
                          venue: widget.venue,
                          selected: widget.selected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.venue,
    required this.height,
    required this.selected,
  });

  final VenueSearchResult venue;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final hasBanner =
        venue.bannerImageUrl != null && venue.bannerImageUrl!.trim().isNotEmpty;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBanner)
            FramedVenueImage(
              imageUrl: venue.bannerImageUrl,
              metadata: venue.bannerImagePosition,
            )
          else
            const SizedBox.shrink(),
          if (!hasBanner)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: venue.bannerGradient,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.55, -0.65),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.38),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.18),
                    AppColors.primaryPurple.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.venue, required this.selected});

  final VenueSearchResult venue;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final logoUrl = venue.logoUrl?.trim() ?? '';
    final hasLogo = logoUrl.isNotEmpty;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasLogo
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: venue.logoGradient,
              ),
        color: hasLogo ? AppColors.background.withValues(alpha: 0.72) : null,
        border: Border.all(
          color: selected
              ? AppColors.primaryPink.withValues(alpha: 0.95)
              : AppColors.white.withValues(alpha: 0.32),
          width: selected ? 2.2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (selected)
            BoxShadow(
              color: AppColors.primaryPink.withValues(alpha: 0.42),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipOval(
        child: hasLogo
            ? FramedVenueImage(
                imageUrl: logoUrl,
                metadata: venue.logoImagePosition,
                width: 40,
                height: 40,
                circular: true,
                fallback: _LogoInitial(venue: venue),
              )
            : _LogoInitial(venue: venue),
      ),
    );
  }
}

class _LogoInitial extends StatelessWidget {
  const _LogoInitial({required this.venue});

  final VenueSearchResult venue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        venue.name.isNotEmpty ? venue.name[0].toUpperCase() : 'V',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.primaryPink : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isOpen ? 0.55 : 0.35),
        ),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? AppColors.white : AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
