import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shared depth, glow, and motion tokens for premium dashboard surfaces.
class PremiumEffects {
  PremiumEffects._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 900);
  static const Curve easeOut = Curves.easeOutCubic;

  static List<BoxShadow> softCardShadow({double intensity = 1}) => [
        BoxShadow(
          color: AppColors.primaryPurple.withValues(alpha: 0.14 * intensity),
          blurRadius: 24 * intensity,
          spreadRadius: -8,
          offset: Offset(0, 10 * intensity),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: -6,
          offset: Offset(0, 6 * intensity),
        ),
      ];

  static List<BoxShadow> hoverGlow({Color? color, double intensity = 1}) {
    final glow = color ?? AppColors.primaryPink;
    return [
      BoxShadow(
        color: glow.withValues(alpha: 0.22 * intensity),
        blurRadius: 28 * intensity,
        spreadRadius: -6,
        offset: Offset(0, 12 * intensity),
      ),
      BoxShadow(
        color: AppColors.primaryPurple.withValues(alpha: 0.12 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: -8,
      ),
    ];
  }

  static List<BoxShadow> activeNavGlow() => [
        BoxShadow(
          color: AppColors.primaryPink.withValues(alpha: 0.28),
          blurRadius: 18,
          spreadRadius: -4,
          offset: const Offset(0, 4),
        ),
      ];

  static LinearGradient cardInnerHighlight(bool hovered) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: hovered ? 0.07 : 0.045),
          Colors.transparent,
          AppColors.primaryPurple.withValues(alpha: hovered ? 0.06 : 0.03),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  static LinearGradient subtleBorderGradient({double intensity = 1}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.trailGold.withValues(alpha: 0.35 * intensity),
          AppColors.primaryPink.withValues(alpha: 0.28 * intensity),
          AppColors.primaryPurple.withValues(alpha: 0.42 * intensity),
        ],
      );

  static LinearGradient brandBorderGradient({double intensity = 1}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryPink.withValues(alpha: 0.85 * intensity),
          AppColors.primaryPurple.withValues(alpha: 0.85 * intensity),
        ],
      );
}

/// Ambient mesh lighting for dashboard backgrounds.
class PremiumAmbientBackground extends StatelessWidget {
  const PremiumAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x2E1A0B2E),
                AppColors.background,
                Color(0x18111218),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.75, -0.85),
              radius: 1.1,
              colors: [
                Color(0x249D28FF),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.2),
              radius: 0.85,
              colors: [
                Color(0x14FF2D95),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.2, 1.1),
              radius: 0.9,
              colors: [
                Color(0x381A0B2E),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft gradient border wrapper used for KPI cards and premium panels.
class PremiumGradientBorder extends StatelessWidget {
  const PremiumGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusLg,
    this.borderWidth = 1,
    this.subtle = false,
    this.glow = false,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final bool subtle;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: subtle
            ? PremiumEffects.subtleBorderGradient()
            : PremiumEffects.brandBorderGradient(),
        boxShadow: glow ? PremiumEffects.hoverGlow(intensity: 0.65) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Count-up animation for dashboard statistics.
class AnimatedStatValue extends StatelessWidget {
  const AnimatedStatValue({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  String _format(int number) {
    final digits = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: PremiumEffects.easeOut,
      builder: (context, animated, _) {
        return Text(
          _format(animated.round()),
          style: style,
        );
      },
    );
  }
}

/// Premium icon badge for KPI and highlight cards.
class PremiumIconBadge extends StatelessWidget {
  const PremiumIconBadge({
    super.key,
    required this.icon,
    this.size = 34,
    this.iconSize = 17,
    this.highlighted = false,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PremiumEffects.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        gradient: highlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPink.withValues(alpha: 0.28),
                  AppColors.primaryPurple.withValues(alpha: 0.32),
                ],
              )
            : null,
        color: highlighted
            ? null
            : AppColors.primaryPurple.withValues(alpha: 0.16),
        border: Border.all(
          color: highlighted
              ? AppColors.primaryPink.withValues(alpha: 0.35)
              : AppColors.primaryPurple.withValues(alpha: 0.24),
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: iconSize, color: AppColors.primaryPink),
    );
  }
}

/// Hover lift wrapper for interactive cards and list rows.
class PremiumHoverLift extends StatefulWidget {
  const PremiumHoverLift({
    super.key,
    required this.child,
    this.lift = 4,
    this.scale = 1.012,
    this.borderRadius = AppSpacing.radiusMd,
    this.enabled = true,
  });

  final Widget child;
  final double lift;
  final double scale;
  final double borderRadius;
  final bool enabled;

  @override
  State<PremiumHoverLift> createState() => _PremiumHoverLiftState();
}

class _PremiumHoverLiftState extends State<PremiumHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -widget.lift : 0.0)
          ..scale(_hovered ? widget.scale : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _hovered ? PremiumEffects.hoverGlow(intensity: 0.75) : null,
        ),
        child: widget.child,
      ),
    );
  }
}
