import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../models/media_library_tab.dart';

/// Tab bar for switching between media libraries.
class MediaLibraryTabBar extends StatelessWidget {
  const MediaLibraryTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MediaLibraryTab selectedTab;
  final ValueChanged<MediaLibraryTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      child: Row(
        children: [
          for (final tab in MediaLibraryTab.values) ...[
            Expanded(
              child: _MediaTabChip(
                label: tab.label,
                selected: selectedTab == tab,
                onTap: () => onTabSelected(tab),
              ),
            ),
            if (tab != MediaLibraryTab.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MediaTabChip extends StatefulWidget {
  const _MediaTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MediaTabChip> createState() => _MediaTabChipState();
}

class _MediaTabChipState extends State<_MediaTabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            gradient: widget.selected ? AppColors.brandGradient : null,
            color: widget.selected
                ? null
                : _hovered
                    ? AppColors.primaryPurple.withValues(alpha: 0.18)
                    : Colors.transparent,
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : AppColors.primaryPurple.withValues(alpha: active ? 0.35 : 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
