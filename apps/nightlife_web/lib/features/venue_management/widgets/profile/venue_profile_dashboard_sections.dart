import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/components/pill_tag.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../../shared/widgets/positioned_venue_image.dart';
import '../../../search/data/search_venue_mapper.dart';
import '../../../search/widgets/venue_result_card.dart';
import '../../../venue/data/venue_opening_hours_formatter.dart';
import '../../../venue/models/venue_details_view.dart';
import '../../../venues/models/image_position_metadata.dart';
import '../../../venues/models/venue_model.dart';
import '../../data/venue_profile_field_codec.dart';
import '../image_reposition/image_reposition_dialog.dart';
import '../page/venue_dashboard_page_widgets.dart';
import 'venue_profile_activity_counts.dart';

/// Responsive dashboard layout for the venue profile control centre.
class VenueProfileDashboardLayout extends StatelessWidget {
  const VenueProfileDashboardLayout({
    super.key,
    required this.publicPreview,
    required this.searchPreview,
    required this.profileDetails,
    required this.branding,
    required this.visibilityChecklist,
  });

  final Widget publicPreview;
  final Widget searchPreview;
  final Widget profileDetails;
  final Widget branding;
  final Widget visibilityChecklist;

  static const _breakpoint = 980.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _breakpoint;
        const gap = AppSpacing.lg;

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              publicPreview,
              const SizedBox(height: gap),
              branding,
              const SizedBox(height: gap),
              searchPreview,
              const SizedBox(height: gap),
              profileDetails,
              const SizedBox(height: gap),
              visibilityChecklist,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EqualHeightProfileRow(
              leftFlex: 68,
              rightFlex: 32,
              gap: gap,
              left: publicPreview,
              right: branding,
            ),
            const SizedBox(height: gap),
            _EqualHeightProfileRow(
              leftFlex: 70,
              rightFlex: 30,
              gap: gap,
              left: profileDetails,
              right: searchPreview,
            ),
            const SizedBox(height: gap),
            visibilityChecklist,
          ],
        );
      },
    );
  }
}

class _EqualHeightProfileRow extends StatefulWidget {
  const _EqualHeightProfileRow({
    required this.leftFlex,
    required this.rightFlex,
    required this.gap,
    required this.left,
    required this.right,
  });

  final int leftFlex;
  final int rightFlex;
  final double gap;
  final Widget left;
  final Widget right;

  @override
  State<_EqualHeightProfileRow> createState() => _EqualHeightProfileRowState();
}

class _EqualHeightProfileRowState extends State<_EqualHeightProfileRow> {
  final _leftKey = GlobalKey();
  final _rightKey = GlobalKey();

  double? _height;
  double? _lastWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_lastWidth != constraints.maxWidth) {
          _lastWidth = constraints.maxWidth;
          if (_height != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _height = null);
            });
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _syncHeight());

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: widget.leftFlex,
              child: _heightConstrained(key: _leftKey, child: widget.left),
            ),
            SizedBox(width: widget.gap),
            Expanded(
              flex: widget.rightFlex,
              child: _heightConstrained(key: _rightKey, child: widget.right),
            ),
          ],
        );
      },
    );
  }

  Widget _heightConstrained({required Key key, required Widget child}) {
    final measuredHeight = _height;
    final keyedChild = KeyedSubtree(key: key, child: child);
    if (measuredHeight == null) return keyedChild;
    return SizedBox(height: measuredHeight, child: keyedChild);
  }

  void _syncHeight() {
    if (!mounted) return;

    final leftHeight = _leftKey.currentContext?.size?.height;
    final rightHeight = _rightKey.currentContext?.size?.height;
    if (leftHeight == null || rightHeight == null) return;

    final nextHeight = leftHeight > rightHeight ? leftHeight : rightHeight;
    if (_height != null && (_height! - nextHeight).abs() < 0.5) return;

    setState(() => _height = nextHeight);
  }
}

class VenueProfilePublicPreviewCard extends StatelessWidget {
  const VenueProfilePublicPreviewCard({
    super.key,
    required this.venue,
    required this.details,
    required this.usableBannerUrl,
    required this.usableLogoUrl,
    required this.onEditProfileDetails,
  });

  final VenueModel venue;
  final VenueDetailsView details;
  final String? usableBannerUrl;
  final String? usableLogoUrl;
  final VoidCallback onEditProfileDetails;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Public Profile Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FramedVenueImage(
                  imageUrl: usableBannerUrl,
                  metadata: venue.bannerImagePosition,
                  height: Breakpoints.isMobile(context) ? 160 : 200,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  fallback: const _PreviewBannerFallback(height: 200),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  bottom: -36,
                  child: _ProfilePreviewLogoFrame(
                    child: FramedVenueImage(
                      imageUrl: usableLogoUrl,
                      metadata: venue.logoImagePosition,
                      width: 72,
                      height: 72,
                      circular: true,
                      fallback: _LogoInitialFallback(name: venue.name),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _PreviewEditChip(
                    onTap: onEditProfileDetails,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            details.name,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            details.displayCategory,
            style: TextStyle(
              color: AppColors.primaryPink.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: 0.4,
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
                  details.locationLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(
                icon: details.isOpen ? Icons.circle : Icons.circle_outlined,
                label: details.isOpen ? 'Open now' : 'Closed',
                accent: details.isOpen
                    ? AppColors.primaryPink
                    : AppColors.textSecondary,
              ),
              _StatusChip(
                icon: Icons.star_rounded,
                label: details.rating.toStringAsFixed(1),
                accent: AppColors.trailGold,
              ),
              if (details.hasOpeningHours)
                _StatusChip(
                  icon: Icons.schedule_outlined,
                  label: details.todayHoursLabel,
                  accent: AppColors.primaryPurple,
                ),
            ],
          ),
          if (details.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < details.tags.take(3).length; i++)
                  PillTag(
                    label: details.tags[i],
                    highlighted: i == 0,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            details.overviewDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              DrinkSpotButton(
                label: 'View Live Public Profile',
                icon: Icons.open_in_new_rounded,
                compact: true,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.venueDetails(venue.id),
                  );
                },
              ),
              DrinkSpotButton(
                label: 'Edit Profile Details',
                icon: Icons.edit_outlined,
                compact: true,
                variant: DrinkSpotButtonVariant.secondary,
                onPressed: onEditProfileDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VenueProfileSearchPreviewCard extends StatelessWidget {
  const VenueProfileSearchPreviewCard({
    super.key,
    required this.venue,
  });

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    final searchResult = SearchVenueMapper.previewFromVenueModel(venue);

    return VenuePageSection(
      title: 'Search & Map Card Preview',
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1,
              child: Transform.scale(
                scale: 0.92,
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: VenueResultCard(
                    venue: searchResult,
                    selected: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This is how customers discover your venue in search and on the map.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DrinkSpotButton(
            label: 'View on Map',
            icon: Icons.map_outlined,
            compact: true,
            variant: DrinkSpotButtonVariant.ghost,
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.search);
            },
          ),
        ],
      ),
    );
  }
}

class VenueProfileDetailsGrid extends StatelessWidget {
  const VenueProfileDetailsGrid({
    super.key,
    required this.venue,
    required this.onEditField,
    this.rawVenueDocument,
    this.stretchVertically = false,
  });

  final VenueModel venue;
  final ValueChanged<String> onEditField;
  final Map<String, dynamic>? rawVenueDocument;
  final bool stretchVertically;

  @override
  Widget build(BuildContext context) {
    final openingHours = VenueOpeningHoursFormatter.fromMap(venue.openingHours);
    final openingSummary = openingHours.isEmpty
        ? 'Not set'
        : openingHours
              .where((entry) => !entry.isClosed)
              .take(3)
              .map((entry) => '${entry.dayLabel}: ${entry.hoursLabel}')
              .join('\n');
    final tags = VenueProfileFieldCodec.displayFeatureTags(venue);
    final ageLabel = _ageRestrictionLabel(
      venue,
      rawVenueDocument,
    );

    final tiles = [
      _DetailSpec(
        label: 'Venue Name',
        value: venue.name.trim().isEmpty ? 'Not set' : venue.name,
        icon: Icons.storefront_outlined,
      ),
      _DetailSpec(
        label: 'Category',
        value: venue.venueType.trim().isNotEmpty
            ? venue.venueType
            : (venue.category.trim().isEmpty ? 'Not set' : venue.category),
        icon: Icons.category_outlined,
      ),
      _DetailSpec(
        label: 'Address',
        value: venue.address.trim().isEmpty ? 'Not set' : venue.address,
        icon: Icons.location_on_outlined,
      ),
      _DetailSpec(
        label: 'Description',
        value: venue.description.trim().isEmpty ? 'Not set' : venue.description,
        icon: Icons.notes_outlined,
      ),
      _DetailSpec(
        label: 'Website',
        value: venue.website.trim().isEmpty ? 'Not set' : venue.website,
        icon: Icons.language_outlined,
      ),
      _DetailSpec(
        label: 'Opening Hours',
        value: openingSummary,
        icon: Icons.schedule_outlined,
      ),
      _DetailSpec(
        label: 'Feature Tags',
        value: tags.isEmpty ? 'Not set' : tags.join(', '),
        icon: Icons.label_outline_rounded,
      ),
      _DetailSpec(
        label: 'Crowd Level',
        value: _formatCrowdLevel(venue.crowdLevel),
        icon: Icons.groups_outlined,
      ),
      _DetailSpec(
        label: '18+ Venue',
        value: ageLabel,
        icon: Icons.verified_user_outlined,
      ),
    ];

    return VenuePageSection(
      title: 'Profile Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              final tileWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                        columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: tiles
                    .map(
                      (tile) => SizedBox(
                        width: tileWidth,
                        child: _ProfileDetailTile(
                          spec: tile,
                          onEdit: () => onEditField(tile.label),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatCrowdLevel(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return 'Not set';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static String _ageRestrictionLabel(
    VenueModel venue,
    Map<String, dynamic>? rawVenueDocument,
  ) {
    if (VenueProfileFieldCodec.isAgeRestrictedVenue(venue, rawVenueDocument)) {
      for (final tag in venue.featureTags) {
        if (tag.toLowerCase().contains('21')) return '21+';
      }
      return '18+';
    }
    return 'Not set';
  }
}

class VenueProfileBrandingCard extends StatelessWidget {
  const VenueProfileBrandingCard({
    super.key,
    required this.venue,
    required this.usableBannerUrl,
    required this.usableLogoUrl,
    required this.onUploadLogo,
    required this.onUploadBanner,
    required this.onAdjustLogo,
    required this.onAdjustBanner,
  });

  final VenueModel venue;
  final String? usableBannerUrl;
  final String? usableLogoUrl;
  final VoidCallback onUploadLogo;
  final VoidCallback onUploadBanner;
  final VoidCallback onAdjustLogo;
  final VoidCallback onAdjustBanner;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Branding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandingPreviewTile(
            label: 'Logo',
            child: Center(
              child: ImageRepositionPreview(
                frameKind: ImageFrameKind.logo,
                imageUrl: usableLogoUrl,
                metadata: venue.logoImagePosition,
                height: 120,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BrandingPreviewTile(
            label: 'Banner',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bannerHeight =
                    (constraints.maxWidth / ImageFrameKind.banner.aspectRatio)
                        .clamp(108.0, 148.0);
                return ImageRepositionPreview(
                  frameKind: ImageFrameKind.banner,
                  imageUrl: usableBannerUrl,
                  metadata: venue.bannerImagePosition,
                  height: bannerHeight,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              DrinkSpotButton(
                label: 'Upload Logo',
                icon: Icons.upload_outlined,
                compact: true,
                onPressed: onUploadLogo,
              ),
              DrinkSpotButton(
                label: 'Upload Banner',
                icon: Icons.upload_outlined,
                compact: true,
                onPressed: onUploadBanner,
              ),
              DrinkSpotButton(
                label: 'Adjust Logo Position',
                icon: Icons.crop_outlined,
                compact: true,
                variant: DrinkSpotButtonVariant.secondary,
                onPressed: venue.logoUrl.trim().isEmpty ? null : onAdjustLogo,
              ),
              DrinkSpotButton(
                label: 'Adjust Banner Position',
                icon: Icons.crop_outlined,
                compact: true,
                variant: DrinkSpotButtonVariant.secondary,
                onPressed: venue.bannerImageUrl.trim().isEmpty
                    ? null
                    : onAdjustBanner,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VenueProfileVisibilityChecklist extends StatelessWidget {
  const VenueProfileVisibilityChecklist({
    super.key,
    required this.venue,
    required this.activityCounts,
  });

  final VenueModel venue;
  final VenueProfileActivityCounts activityCounts;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(venue, activityCounts);

    return VenuePageSection(
      title: 'Customer Visibility Checklist',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                        columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _ChecklistRow(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Complete more profile items to improve customer confidence and '
            'discoverability across search, map and your public venue profile.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static List<_ChecklistItem> _buildItems(
    VenueModel venue,
    VenueProfileActivityCounts counts,
  ) {
    bool hasOpeningHours() {
      if (venue.openingHours.isEmpty) return false;
      return venue.openingHours.values.any((value) {
        if (value is Map) {
          return value.values.any(
            (entry) => entry?.toString().trim().isNotEmpty ?? false,
          );
        }
        return value?.toString().trim().isNotEmpty ?? false;
      });
    }

    return [
      _ChecklistItem(
        'Logo uploaded',
        venue.logoUrl.trim().isNotEmpty,
      ),
      _ChecklistItem(
        'Banner uploaded',
        venue.bannerImageUrl.trim().isNotEmpty,
      ),
      _ChecklistItem(
        'Description added',
        venue.description.trim().isNotEmpty,
      ),
      _ChecklistItem(
        'Website added',
        venue.website.trim().isNotEmpty,
      ),
      _ChecklistItem('Opening hours complete', hasOpeningHours()),
      _ChecklistItem(
        'Tags selected',
        venue.featureTags.isNotEmpty || venue.features.isNotEmpty,
      ),
      _ChecklistItem(
        'Gallery uploaded',
        venue.galleryImageUrls.isNotEmpty,
      ),
      _ChecklistItem('Deals created', counts.dealCount > 0),
      _ChecklistItem('Events created', counts.eventCount > 0),
      _ChecklistItem(
        'Contact information complete',
        venue.phone.trim().isNotEmpty,
      ),
    ];
  }
}

class _ProfilePreviewLogoFrame extends StatelessWidget {
  const _ProfilePreviewLogoFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background.withValues(alpha: 0.58),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}

class _PreviewEditChip extends StatelessWidget {
  const _PreviewEditChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 14, color: AppColors.white),
              SizedBox(width: 4),
              Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBannerFallback extends StatelessWidget {
  const _PreviewBannerFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D1054), Color(0xFF1A0B2E), Color(0xFF9D28FF)],
          ),
        ),
      ),
    );
  }
}

class _LogoInitialFallback extends StatelessWidget {
  const _LogoInitialFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'V',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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

class _DetailSpec {
  const _DetailSpec({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ProfileDetailTile extends StatefulWidget {
  const _ProfileDetailTile({
    required this.spec,
    required this.onEdit,
  });

  final _DetailSpec spec;
  final VoidCallback onEdit;

  @override
  State<_ProfileDetailTile> createState() => _ProfileDetailTileState();
}

class _ProfileDetailTileState extends State<_ProfileDetailTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: PremiumEffects.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: AppColors.surfaceElevated.withValues(
            alpha: _hovered ? 0.72 : 0.55,
          ),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(
              alpha: _hovered ? 0.28 : 0.16,
            ),
          ),
          boxShadow: _hovered ? PremiumEffects.hoverGlow(intensity: 0.25) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PremiumIconBadge(icon: widget.spec.icon, highlighted: _hovered),
                const Spacer(),
                TextButton(
                  onPressed: widget.onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.spec.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.spec.value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandingPreviewTile extends StatelessWidget {
  const _BrandingPreviewTile({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: child,
        ),
      ],
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem(this.label, this.completed);

  final String label;
  final bool completed;
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final _ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.completed
        ? AppColors.primaryPink
        : AppColors.textSecondary.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            item.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: item.completed
                    ? AppColors.white
                    : AppColors.textSecondary.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

