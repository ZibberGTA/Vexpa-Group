import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RotatingFadeText extends StatefulWidget {
  const RotatingFadeText({
    super.key,
    required this.prompts,
    this.interval = const Duration(milliseconds: 3500),
    this.style,
    this.textAlign = TextAlign.center,
  });

  final List<String> prompts;
  final Duration interval;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<RotatingFadeText> createState() => _RotatingFadeTextState();
}

class _RotatingFadeTextState extends State<RotatingFadeText> {
  late Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || widget.prompts.isEmpty) return;
      setState(() => _index = (_index + 1) % widget.prompts.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prompts.isEmpty) return const SizedBox.shrink();

    final style = widget.style ??
        const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.3,
        );

    return SizedBox(
      width: double.infinity,
      height: (style.fontSize ?? 20) * (style.height ?? 1.3) * 1.1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          widget.prompts[_index],
          key: ValueKey<String>(widget.prompts[_index]),
          textAlign: widget.textAlign,
          style: style,
        ),
      ),
    );
  }
}
