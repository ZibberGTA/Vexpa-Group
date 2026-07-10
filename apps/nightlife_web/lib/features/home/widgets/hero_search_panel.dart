import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';

class HeroSearchPanel extends StatefulWidget {
  const HeroSearchPanel({
    super.key,
    this.alignLeft = false,
    this.fullWidth = false,
  });

  final bool alignLeft;
  final bool fullWidth;

  @override
  State<HeroSearchPanel> createState() => _HeroSearchPanelState();
}

class _HeroSearchPanelState extends State<HeroSearchPanel> {
  static const _animationDuration = Duration(milliseconds: 200);

  bool _hovered = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _maxWidth(BuildContext context) {
    if (widget.fullWidth) return double.infinity;
    return switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 650,
      ScreenSize.tablet => 560,
      ScreenSize.mobile => double.infinity,
    };
  }

  double _barHeight(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 60,
      ScreenSize.tablet => 60,
      ScreenSize.mobile => 56,
    };
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final elevated = focused || _hovered;
    final maxWidth = _maxWidth(context);
    final barHeight = _barHeight(context);
    final isMobile = Breakpoints.isMobile(context);
    const borderRadius = BorderRadius.all(Radius.circular(999));

    return Align(
      alignment: widget.alignLeft ? Alignment.centerLeft : Alignment.center,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeOut,
          width: maxWidth,
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: elevated
                  ? AppColors.primaryPink.withValues(alpha: 0.85)
                  : AppColors.primaryPink.withValues(alpha: 0.45),
              width: elevated ? 1.8 : 1.2,
            ),
            color: AppColors.surfaceElevated.withValues(alpha: 0.72),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withValues(
                  alpha: elevated ? 0.42 : 0.24,
                ),
                blurRadius: elevated ? 40 : 28,
                spreadRadius: elevated ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Icon(
                        Icons.search_rounded,
                        color: elevated
                            ? AppColors.primaryPink
                            : AppColors.textSecondary,
                        size: isMobile ? 22 : 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      child: TextField(
                        focusNode: _focusNode,
                        onTapOutside: (_) => _focusNode.unfocus(),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          Navigator.of(context).pushNamed(AppRouter.map);
                        },
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: AppStrings.searchPlaceholder,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                            fontSize: isMobile ? 14 : 16,
                            height: 1,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 24,
                            vertical: 0,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRouter.map),
                          customBorder: const CircleBorder(),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: elevated
                                ? AppColors.primaryPink
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
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
