import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/vexda_background.dart';

/// Root shell that paints the standard application canvas behind route content.
///
/// The immersive homepage background is owned by [HomeScreen] — not this shell.
/// The map route is excluded so the map remains unobstructed.
class VexdaAppShell extends StatelessWidget {
  const VexdaAppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  static bool showsBackgroundForRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return true;
    return routeName != AppRouter.map;
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    final showBackground = showsBackgroundForRoute(routeName);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showBackground)
          const Positioned.fill(
            child: IgnorePointer(
              child: VexdaAppBackground(),
            ),
          ),
        child,
      ],
    );
  }
}
