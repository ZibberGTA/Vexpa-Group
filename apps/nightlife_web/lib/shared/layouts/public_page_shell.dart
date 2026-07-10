import 'package:flutter/material.dart';

import '../../features/home/widgets/home_nav_bar.dart';
import '../components/public_footer.dart';

/// Standard scrollable shell for public pages with fixed nav and footer.
class PublicPageShell extends StatelessWidget {
  const PublicPageShell({
    super.key,
    required this.child,
    this.showFooter = true,
    this.navActiveRoute,
  });

  final Widget child;
  final bool showFooter;
  final String? navActiveRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          HomeNavBar(activeRoute: navActiveRoute),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  child,
                  if (showFooter) const PublicFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
