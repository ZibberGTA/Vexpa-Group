import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/premium_effects.dart';

enum DrinkSpotButtonVariant { primary, secondary, ghost }

class DrinkSpotButton extends StatefulWidget {
  const DrinkSpotButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DrinkSpotButtonVariant.primary,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DrinkSpotButtonVariant variant;
  final IconData? icon;
  final bool compact;

  @override
  State<DrinkSpotButton> createState() => _DrinkSpotButtonState();
}

class _DrinkSpotButtonState extends State<DrinkSpotButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    final enabled = widget.onPressed != null;
    final highlighted = enabled && (_hovered || _pressed);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.03 : 1.0),
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          child: AnimatedContainer(
            duration: PremiumEffects.fast,
            curve: PremiumEffects.easeOut,
            decoration: _decoration(highlighted),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: _foregroundColor()),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: _foregroundColor(),
                        fontSize: widget.compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(bool highlighted) {
    return switch (widget.variant) {
      DrinkSpotButtonVariant.primary => BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: highlighted
              ? PremiumEffects.hoverGlow(intensity: 0.85)
              : PremiumEffects.softCardShadow(intensity: 0.45),
        ),
      DrinkSpotButtonVariant.secondary => BoxDecoration(
          gradient: highlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.32),
                    AppColors.surfaceElevated,
                  ],
                )
              : null,
          color: highlighted ? null : AppColors.surfaceElevated.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: highlighted
                ? AppColors.primaryPink.withValues(alpha: 0.35)
                : AppColors.primaryPurple.withValues(alpha: 0.42),
          ),
          boxShadow: highlighted ? PremiumEffects.hoverGlow(intensity: 0.35) : null,
        ),
      DrinkSpotButtonVariant.ghost => BoxDecoration(
          color: highlighted
              ? AppColors.white.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: highlighted
                ? AppColors.white.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
        ),
    };
  }

  Color _foregroundColor() {
    if (widget.variant == DrinkSpotButtonVariant.ghost && _hovered) {
      return AppColors.white;
    }
    return switch (widget.variant) {
      DrinkSpotButtonVariant.primary => AppColors.white,
      DrinkSpotButtonVariant.secondary => AppColors.white,
      DrinkSpotButtonVariant.ghost => AppColors.textSecondary,
    };
  }
}
