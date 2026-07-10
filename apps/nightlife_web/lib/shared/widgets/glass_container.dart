import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_effects.dart';

enum GlassElevation {
  none,
  soft,
  medium,
}

class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSpacing.radiusMd,
    this.blur = 18,
    this.opacity = 0.72,
    this.elevation = GlassElevation.none,
    this.innerHighlight = false,
    this.interactiveHover = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final GlassElevation elevation;
  final bool innerHighlight;
  final bool interactiveHover;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity =
        widget.interactiveHover && _hovered ? widget.opacity + 0.08 : widget.opacity;

    final shadows = switch (widget.elevation) {
      GlassElevation.none =>
        _hovered && widget.interactiveHover ? PremiumEffects.softCardShadow(intensity: 0.7) : null,
      GlassElevation.soft => PremiumEffects.softCardShadow(
          intensity: _hovered && widget.interactiveHover ? 1.15 : 1,
        ),
      GlassElevation.medium => PremiumEffects.softCardShadow(
          intensity: _hovered && widget.interactiveHover ? 1.35 : 1.15,
        ),
    };

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blur,
          sigmaY: widget.blur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: effectiveOpacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _hovered && widget.interactiveHover
                  ? AppColors.primaryPink.withValues(alpha: 0.22)
                  : AppColors.glassBorder,
            ),
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              if (widget.innerHighlight)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: PremiumEffects.cardInnerHighlight(_hovered),
                    ),
                  ),
                ),
              Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.interactiveHover) return content;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.008 : 1,
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        child: content,
      ),
    );
  }
}
