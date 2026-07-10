import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../widgets/home_download_section.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_layout.dart';
import '../widgets/home_nav_bar.dart';
import '../widgets/home_page_background.dart';
import '../widgets/home_stats_strip.dart';
import '../widgets/home_why_vexda_section.dart';

/// Production homepage — continuous premium desktop experience.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: HomePageBackground(),
            ),
          ),
          Column(
            children: [
              const HomeNavBar(
                activeRoute: AppRouter.home,
                fullWidth: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      HomeHeroSection(),
                      HomeSectionGap(HomeLayout.gapHeroToWhy),
                      HomeWhyVexdaSection(),
                      HomeSectionGap(HomeLayout.gapCardsToStats),
                      HomeStatsStrip(),
                      HomeSectionGap(HomeLayout.gapStatsToDownload),
                      HomeDownloadSection(),
                      HomeSectionGap(HomeLayout.gapDownloadToFooter),
                      HomeFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
