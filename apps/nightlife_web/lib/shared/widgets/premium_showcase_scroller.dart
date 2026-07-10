import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'carousel_edge_fade.dart';

/// Netflix-style horizontal showcase with wheel scroll, drag, swipe, and arrows.
class PremiumShowcaseScroller extends StatefulWidget {
  const PremiumShowcaseScroller({
    super.key,
    required this.height,
    required this.standardItemWidth,
    required this.featuredItem,
    required this.items,
    this.featuredWidthFactor = 1.4,
    this.itemSpacing = AppSpacing.lg,
  });

  final double height;
  final double standardItemWidth;
  final Widget featuredItem;
  final List<Widget> items;
  final double featuredWidthFactor;
  final double itemSpacing;

  @override
  State<PremiumShowcaseScroller> createState() =>
      _PremiumShowcaseScrollerState();
}

class _PremiumShowcaseScrollerState extends State<PremiumShowcaseScroller> {
  late final ScrollController _controller;
  bool _hovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _isScrollPositionReady {
    if (!_controller.hasClients) return false;
    return _controller.position.hasContentDimensions;
  }

  void _onScroll() {
    if (!mounted || !_isScrollPositionReady) return;

    final position = _controller.position;
    final offset = position.pixels;
    final max = position.maxScrollExtent;
    final nextLeft = offset > 4;
    final nextRight = offset < max - 4;
    if (nextLeft != _canScrollLeft || nextRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = nextLeft;
        _canScrollRight = nextRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_isScrollPositionReady) return;

    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showArrows = Breakpoints.isDesktop(context);
    final featuredWidth = widget.standardItemWidth * widget.featuredWidthFactor;
    final allItems = [widget.featuredItem, ...widget.items];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CarouselEdgeFade(
              child: Listener(
                onPointerSignal: (signal) {
                  if (signal is PointerScrollEvent &&
                      signal.scrollDelta.dy != 0) {
                    _scrollBy(signal.scrollDelta.dy);
                  }
                },
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!_isScrollPositionReady) return;
                    final position = _controller.position;
                    _controller.jumpTo(
                      (position.pixels - details.delta.dx).clamp(
                        0.0,
                        position.maxScrollExtent,
                      ),
                    );
                  },
                  child: ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.zero,
                    itemCount: allItems.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: widget.itemSpacing),
                    itemBuilder: (context, index) {
                      final isFeatured = index == 0;
                      return SizedBox(
                        width: isFeatured
                            ? featuredWidth
                            : widget.standardItemWidth,
                        child: allItems[index],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showArrows) ...[
              _ScrollArrow(
                visible: _hovered && _canScrollLeft,
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left_rounded,
                onTap: () => _scrollBy(-widget.standardItemWidth * 0.85),
              ),
              _ScrollArrow(
                visible: _hovered && _canScrollRight,
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right_rounded,
                onTap: () => _scrollBy(widget.standardItemWidth * 0.85),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    required this.visible,
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  final bool visible;
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
