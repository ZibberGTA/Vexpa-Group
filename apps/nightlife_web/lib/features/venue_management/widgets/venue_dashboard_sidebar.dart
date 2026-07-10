import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../../../shared/widgets/safe_venue_branding_image.dart';
import '../../venues/data/venue_image_field_parser.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_nav_sections.dart';
import '../models/venue_dashboard_tab.dart';
import 'venue_dashboard_layout.dart';

/// Collapsible left navigation for the venue management dashboard.
class VenueDashboardSidebar extends StatefulWidget {
  const VenueDashboardSidebar({
    super.key,
    required this.contextData,
    required this.expanded,
    required this.selectedTab,
    required this.onTabSelected,
    this.venueDocument,
    this.onToggleSidebar,
  });

  final VenueDashboardContext contextData;
  final bool expanded;
  final VenueDashboardTab selectedTab;
  final ValueChanged<VenueDashboardTab> onTabSelected;
  final Map<String, dynamic>? venueDocument;
  final VoidCallback? onToggleSidebar;

  @override
  State<VenueDashboardSidebar> createState() => _VenueDashboardSidebarState();
}

class _VenueDashboardSidebarState extends State<VenueDashboardSidebar> {
  final _stackKey = GlobalKey();
  final _dashboardNavKey = GlobalKey();
  double? _toggleTop;

  @override
  void initState() {
    super.initState();
    _scheduleTogglePositionUpdate();
  }

  @override
  void didUpdateWidget(covariant VenueDashboardSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded ||
        oldWidget.contextData.venueName != widget.contextData.venueName) {
      _scheduleTogglePositionUpdate();
    }
  }

  void _scheduleTogglePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTogglePosition());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        VenueDashboardLayout.sidebarTransitionDuration,
        () {
          if (mounted) _updateTogglePosition();
        },
      );
    });
  }

  void _updateTogglePosition() {
    final dashboardContext = _dashboardNavKey.currentContext;
    final stackContext = _stackKey.currentContext;
    if (dashboardContext == null || stackContext == null) return;

    final dashboardBox = dashboardContext.findRenderObject() as RenderBox?;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (dashboardBox == null ||
        stackBox == null ||
        !dashboardBox.hasSize ||
        !stackBox.hasSize) {
      return;
    }

    final dashboardOrigin = dashboardBox.localToGlobal(Offset.zero);
    final stackOrigin = stackBox.localToGlobal(Offset.zero);
    final pillCenterY =
        dashboardOrigin.dy + (VenueDashboardLayout.navItemHeight / 2);
    final measuredTop =
        (pillCenterY - stackOrigin.dy) -
        (VenueDashboardLayout.sidebarToggleSize / 2);

    if (_toggleTop == null || (_toggleTop! - measuredTop).abs() > 0.5) {
      setState(() => _toggleTop = measuredTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggleSize = VenueDashboardLayout.sidebarToggleSize;
    final fallbackTop = VenueDashboardLayout.sidebarToggleTopOffset(
      expanded: widget.expanded,
    );

    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: VenueDashboardLayout.sidebarTransitionDuration,
          curve: PremiumEffects.easeOut,
          width: widget.expanded
              ? VenueDashboardLayout.sidebarExpandedWidth
              : VenueDashboardLayout.sidebarCollapsedWidth,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            border: Border(
              right: BorderSide(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: -8,
                offset: const Offset(6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header outside BackdropFilter — blur layer can hide network images on web.
              AnimatedOpacity(
                opacity: widget.expanded ? 1 : 0.88,
                duration: VenueDashboardLayout.sidebarTransitionDuration,
                curve: PremiumEffects.easeOut,
                child: _VenueSidebarHeader(
                  contextData: widget.contextData,
                  expanded: widget.expanded,
                  venueDocument: widget.venueDocument,
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: ColoredBox(
                      color: Colors.transparent,
                      child: AnimatedOpacity(
                        opacity: widget.expanded ? 1 : 0.78,
                        duration: VenueDashboardLayout.sidebarTransitionDuration,
                        curve: PremiumEffects.easeOut,
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.expanded
                                ? AppSpacing.lg
                                : AppSpacing.sm,
                            vertical: AppSpacing.md,
                          ),
                          children: widget.expanded
                              ? _buildGroupedNavItems()
                              : _buildFlatNavItems(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.onToggleSidebar != null)
          AnimatedPositioned(
            duration: VenueDashboardLayout.sidebarTransitionDuration,
            curve: PremiumEffects.easeOut,
            top: _toggleTop ?? fallbackTop,
            right: -(toggleSize / 2),
            child: _SidebarEdgeToggle(
              expanded: widget.expanded,
              onPressed: widget.onToggleSidebar!,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildFlatNavItems() {
    return VenueDashboardTab.values
        .map(
          (tab) => _SidebarNavItem(
            key: tab == VenueDashboardTab.dashboard ? _dashboardNavKey : null,
            tab: tab,
            expanded: widget.expanded,
            selected: widget.selectedTab == tab,
            onTap: () => widget.onTabSelected(tab),
          ),
        )
        .toList();
  }

  List<Widget> _buildGroupedNavItems() {
    final items = <Widget>[];

    for (var sectionIndex = 0;
        sectionIndex < venueDashboardNavSections.length;
        sectionIndex++) {
      final section = venueDashboardNavSections[sectionIndex];
      if (sectionIndex > 0) {
        items.add(const SizedBox(height: AppSpacing.sm));
      }
      items.add(_SidebarSectionLabel(label: section.label));
      items.add(const SizedBox(height: AppSpacing.xs));
      for (final tab in section.tabs) {
        items.add(
          _SidebarNavItem(
            key: tab == VenueDashboardTab.dashboard ? _dashboardNavKey : null,
            tab: tab,
            expanded: widget.expanded,
            selected: widget.selectedTab == tab,
            onTap: () => widget.onTabSelected(tab),
          ),
        );
      }
    }

    return items;
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _VenueSidebarHeader extends StatelessWidget {
  const _VenueSidebarHeader({
    required this.contextData,
    required this.expanded,
    this.venueDocument,
  });

  final VenueDashboardContext contextData;
  final bool expanded;
  final Map<String, dynamic>? venueDocument;

  @override
  Widget build(BuildContext context) {
    final branding = _SidebarBranding.resolve(
      contextData: contextData,
      venueDocument: venueDocument,
    );
    final logoUrl = branding.logoUrl;
    final bannerUrl = branding.bannerUrl;
    final hasBanner = bannerUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
          ),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (hasBanner)
            Positioned.fill(
              child: SafeVenueBrandingImage(
                url: bannerUrl,
                fit: BoxFit.cover,
                fallback: const _SidebarHeaderFallbackBg(),
              ),
            )
          else
            const Positioned.fill(child: _SidebarHeaderFallbackBg()),
          if (hasBanner)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x990D0814), Color(0xBF0D0814)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              expanded ? AppSpacing.lg : AppSpacing.sm,
              AppSpacing.lg,
              expanded ? AppSpacing.lg : AppSpacing.sm,
              AppSpacing.md,
            ),
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _VenueAvatar(
                            initials: contextData.initials,
                            logoUrl: logoUrl,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              contextData.venueName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.25,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ViewPublicProfileLink(venueId: contextData.venueId),
                    ],
                  )
                : Center(
                    child: _VenueAvatar(
                      initials: contextData.initials,
                      logoUrl: logoUrl,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBranding {
  const _SidebarBranding({required this.logoUrl, required this.bannerUrl});

  final String logoUrl;
  final String bannerUrl;

  static _SidebarBranding resolve({
    required VenueDashboardContext contextData,
    required Map<String, dynamic>? venueDocument,
  }) {
    final data = venueDocument;

    if (data != null) {
      return _SidebarBranding(
        logoUrl: VenueImageFieldParser.resolveVenueLogoUrl(data),
        bannerUrl: VenueImageFieldParser.resolveVenueBannerUrl(data),
      );
    }

    return _SidebarBranding(
      logoUrl: contextData.logoUrl?.trim() ?? '',
      bannerUrl: contextData.bannerImageUrl?.trim() ?? '',
    );
  }
}

class _SidebarHeaderFallbackBg extends StatelessWidget {
  const _SidebarHeaderFallbackBg();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.18),
            AppColors.surface.withValues(alpha: 0.88),
          ],
        ),
      ),
    );
  }
}

class _VenueAvatar extends StatelessWidget {
  const _VenueAvatar({required this.initials, this.logoUrl = ''});

  final String initials;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl.trim();
    final hasLogo = url.isNotEmpty;

    return Container(
      width: VenueDashboardLayout.venueAvatarSize,
      height: VenueDashboardLayout.venueAvatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: hasLogo ? null : AppColors.brandGradient,
        color: hasLogo ? AppColors.surface.withValues(alpha: 0.5) : null,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        boxShadow: PremiumEffects.hoverGlow(intensity: 0.45),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? SafeVenueBrandingImage(
              url: url,
              fit: BoxFit.cover,
              width: VenueDashboardLayout.venueAvatarSize,
              height: VenueDashboardLayout.venueAvatarSize,
              fallback: _InitialsFallback(initials: initials),
            )
          : _InitialsFallback(initials: initials),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ViewPublicProfileLink extends StatefulWidget {
  const _ViewPublicProfileLink({required this.venueId});

  final String venueId;

  @override
  State<_ViewPublicProfileLink> createState() => _ViewPublicProfileLinkState();
}

class _ViewPublicProfileLinkState extends State<_ViewPublicProfileLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRouter.venueDetails(widget.venueId));
        },
        child: Text(
          AppStrings.viewPublicProfile,
          style: TextStyle(
            color: _hovered ? AppColors.primaryPink : AppColors.primaryPurple,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            decoration: TextDecoration.underline,
            decorationColor: _hovered
                ? AppColors.primaryPink.withValues(alpha: 0.8)
                : AppColors.primaryPurple.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    super.key,
    required this.tab,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final VenueDashboardTab tab;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;
    final icon = widget.selected ? widget.tab.selectedIcon : widget.tab.icon;

    final item = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          height: VenueDashboardLayout.navItemHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? AppSpacing.md : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: widget.selected ? AppColors.brandGradient : null,
            color: widget.selected
                ? null
                : _hovered
                ? AppColors.primaryPurple.withValues(alpha: 0.14)
                : Colors.transparent,
            border: widget.selected
                ? null
                : Border.all(
                    color: _hovered
                        ? AppColors.primaryPurple.withValues(alpha: 0.24)
                        : Colors.transparent,
                  ),
            boxShadow: widget.selected ? PremiumEffects.activeNavGlow() : null,
          ),
          child: widget.expanded
              ? Row(
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: highlighted
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlighted
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight: widget.selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: highlighted
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );

    if (widget.expanded) return item;

    return Tooltip(message: widget.tab.label, preferBelow: false, child: item);
  }
}

class _SidebarEdgeToggle extends StatefulWidget {
  const _SidebarEdgeToggle({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  State<_SidebarEdgeToggle> createState() => _SidebarEdgeToggleState();
}

class _SidebarEdgeToggleState extends State<_SidebarEdgeToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = VenueDashboardLayout.sidebarToggleSize;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: PremiumEffects.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(-3, 2),
              ),
              if (_hovered)
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.42),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: PremiumEffects.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hovered
                      ? AppColors.primaryPurple.withValues(alpha: 0.22)
                      : AppColors.surface.withValues(alpha: 0.72),
                  border: Border.all(
                    color: _hovered
                        ? AppColors.primaryPurple.withValues(alpha: 0.55)
                        : AppColors.glassBorder,
                  ),
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: widget.expanded ? 0 : 0.5,
                    duration: VenueDashboardLayout.sidebarTransitionDuration,
                    curve: PremiumEffects.easeOut,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: _hovered
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
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
