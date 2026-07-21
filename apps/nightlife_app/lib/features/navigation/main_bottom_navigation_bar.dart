import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../discover/widgets/trails_navigation_button.dart';
import '../trails/services/trail_nav_glow_service.dart';

enum MainNavTab {
  discover,
  search,
  trails,
  saved,
  account;

  static const int discoverIndex = 0;
  static const int searchIndex = 1;
  static const int trailsIndex = 2;
  static const int savedIndex = 3;
  static const int accountIndex = 4;
}

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.trailGlowState,
    this.accountBadgeCount = 0,
  });

  static const Key barKey = Key('main-bottom-navigation-bar');
  static const double barHeight = 74;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final TrailNavGlowState trailGlowState;
  final int accountBadgeCount;

  bool _isCompactLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  @override
  Widget build(BuildContext context) {
    final compact = _isCompactLayout(context);
    final labelFontSize = compact ? 11.0 : 12.0;
    final trailsWidth = compact ? 56.0 : 62.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Container(
          key: barKey,
          clipBehavior: Clip.none,
          constraints: const BoxConstraints(minHeight: barHeight),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                label: 'Discover',
                labelFontSize: labelFontSize,
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                selected: selectedIndex == MainNavTab.discoverIndex,
                onTap: () => onDestinationSelected(MainNavTab.discoverIndex),
              ),
              _NavItem(
                label: 'Search',
                labelFontSize: labelFontSize,
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                selected: selectedIndex == MainNavTab.searchIndex,
                onTap: () => onDestinationSelected(MainNavTab.searchIndex),
              ),
              TrailsNavigationButton(
                selected: selectedIndex == MainNavTab.trailsIndex,
                shouldGlow: trailGlowState.shouldGlow,
                width: trailsWidth,
                labelFontSize: labelFontSize,
                onTap: () => onDestinationSelected(MainNavTab.trailsIndex),
              ),
              _NavItem(
                label: 'Saved',
                labelFontSize: labelFontSize,
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                selected: selectedIndex == MainNavTab.savedIndex,
                onTap: () => onDestinationSelected(MainNavTab.savedIndex),
              ),
              _NavItem(
                label: 'Account',
                labelFontSize: labelFontSize,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                selected: selectedIndex == MainNavTab.accountIndex,
                badgeCount: accountBadgeCount,
                onTap: () => onDestinationSelected(MainNavTab.accountIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.labelFontSize,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final double labelFontSize;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    size: 24,
                    color: selected
                        ? AppColors.purpleSoft
                        : AppColors.textSecondary,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelFontSize,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.purpleSoft
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
