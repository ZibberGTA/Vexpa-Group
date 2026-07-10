import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class HoverFeatureCard extends StatefulWidget {
  const HoverFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<HoverFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6.0 : 0, 0),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.surfaceElevated
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryPurple.withValues(alpha: 0.75)
                : AppColors.primaryPurple.withValues(alpha: 0.30),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _hovered
                          ? AppColors.brandGradient
                          : null,
                      color: _hovered
                          ? null
                          : AppColors.primaryPurple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
