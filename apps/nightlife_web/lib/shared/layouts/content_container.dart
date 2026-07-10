import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_spacing.dart';

/// Master layout grid for the Vexda homepage and future web sections.
///
/// Every homepage block should render inside this container so content shares
/// the same max width, horizontal padding, and centre alignment.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  static EdgeInsets horizontalPaddingOf(BuildContext context) {
    final horizontal = Breakpoints.horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  static double contentWidthOf(
    BuildContext context, {
    double maxWidth = AppSpacing.maxContentWidth,
  }) {
    final viewport = MediaQuery.sizeOf(context).width;
    final horizontal = Breakpoints.horizontalPadding(context);
    final outerWidth = viewport < maxWidth ? viewport : maxWidth;
    return outerWidth - (horizontal * 2);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? horizontalPaddingOf(context),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}
