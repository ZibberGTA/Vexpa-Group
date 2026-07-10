import 'package:flutter/material.dart';

import '../../../shared/layouts/content_container.dart';
import 'home_layout.dart';

/// Homepage section aligned to the shared 12-column grid canvas.
class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      maxWidth: HomeLayout.maxContentWidth(context),
      padding: HomeLayout.gridPadding(context),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Shared vertical rhythm presets for homepage sections.
class HomeSectionSpacing {
  HomeSectionSpacing._();

  static EdgeInsets hero(BuildContext context) => HomeLayout.heroPadding(context);
}
