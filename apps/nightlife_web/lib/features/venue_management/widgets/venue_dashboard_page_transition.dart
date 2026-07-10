import 'package:flutter/material.dart';

/// Fast premium transition between venue dashboard tab pages.
class VenueDashboardPageTransition extends StatelessWidget {
  const VenueDashboardPageTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  static const Duration duration = Duration(milliseconds: 260);

  final Animation<double> animation;
  final Widget child;

  static Widget builder(Widget child, Animation<double> animation) {
    return VenueDashboardPageTransition(
      animation: animation,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.016),
      end: Offset.zero,
    ).animate(curved);

    final scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }
}
