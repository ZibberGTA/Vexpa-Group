import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TrailsNavigationButton extends StatefulWidget {
  const TrailsNavigationButton({
    super.key,
    required this.selected,
    required this.shouldGlow,
    required this.onTap,
    this.width = 62,
    this.labelFontSize = 12,
  });

  static const Key buttonKey = Key('trails-navigation-button');

  final bool selected;
  final bool shouldGlow;
  final VoidCallback onTap;
  final double width;
  final double labelFontSize;

  @override
  State<TrailsNavigationButton> createState() => _TrailsNavigationButtonState();
}

class _TrailsNavigationButtonState extends State<TrailsNavigationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimation());
  }

  @override
  void didUpdateWidget(covariant TrailsNavigationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.shouldGlow && !reduceMotion) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final glow = widget.shouldGlow;

    return Semantics(
      button: true,
      label: 'Trails',
      selected: selected,
      child: GestureDetector(
        key: TrailsNavigationButton.buttonKey,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final pulseOpacity = glow ? _pulseAnimation.value : 0.0;
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.purple.withOpacity(0.24)
                          : AppColors.surface.withOpacity(0.72),
                      border: Border.all(
                        color: glow
                            ? AppColors.purpleSoft
                            : AppColors.purple.withOpacity(0.72),
                        width: glow ? 2.2 : 1.6,
                      ),
                      boxShadow: glow
                          ? [
                              BoxShadow(
                                color: AppColors.purple.withOpacity(
                                  0.18 + pulseOpacity * 0.22,
                                ),
                                blurRadius: 14 + pulseOpacity * 8,
                                spreadRadius: 1 + pulseOpacity,
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  );
                },
                child: Icon(
                  Icons.route_outlined,
                  color: selected
                      ? AppColors.purpleSoft
                      : AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Trails',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.labelFontSize,
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
