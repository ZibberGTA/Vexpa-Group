import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// In-page section navigation for the venue details main column.
class VenueSectionNav extends StatelessWidget {
  const VenueSectionNav({
    super.key,
    required this.sections,
    required this.onSectionSelected,
    required this.activeSection,
  });

  final List<VenueSectionNavItem> sections;
  final ValueChanged<String> onSectionSelected;
  final String activeSection;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final section = sections[index];
          final selected = section.id == activeSection;

          return InkWell(
            onTap: () => onSectionSelected(section.id),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.brandGradient : null,
                color: selected ? null : AppColors.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.primaryPurple.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                section.label,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textSecondary,
                  fontSize: Breakpoints.isMobile(context) ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VenueSectionNavItem {
  const VenueSectionNavItem({required this.id, required this.label});

  final String id;
  final String label;
}
