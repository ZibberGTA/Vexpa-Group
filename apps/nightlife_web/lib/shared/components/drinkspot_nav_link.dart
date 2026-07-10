import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DrinkSpotNavLink extends StatefulWidget {
  const DrinkSpotNavLink({
    super.key,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  State<DrinkSpotNavLink> createState() => _DrinkSpotNavLinkState();
}

class _DrinkSpotNavLinkState extends State<DrinkSpotNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active || _hovered
        ? AppColors.white
        : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (widget.active || _hovered)
                    ? AppColors.primaryPink
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
