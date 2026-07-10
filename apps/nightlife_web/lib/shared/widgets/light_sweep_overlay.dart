import 'dart:async';

import 'package:flutter/material.dart';

/// Subtle light sweep animation for premium showcase banners.
class LightSweepOverlay extends StatefulWidget {
  const LightSweepOverlay({
    super.key,
    this.pause = const Duration(seconds: 4),
  });

  final Duration pause;

  @override
  State<LightSweepOverlay> createState() => _LightSweepOverlayState();
}

class _LightSweepOverlayState extends State<LightSweepOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await _controller.forward(from: 0);
      if (!mounted) return;

      final completer = Completer<void>();
      _pauseTimer = Timer(widget.pause, () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
      _pauseTimer = null;
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -width * 0.35 + _controller.value * width * 1.7,
                  top: 0,
                  bottom: 0,
                  width: width * 0.35,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
