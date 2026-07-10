import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'hero_search_panel.dart';
import 'home_layout.dart';
import 'home_section.dart';

/// Premium homepage hero — transparent, centred copy over the global background.
class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key});

  static const double maxContentWidth = 1250;
  static const double widthFactor = 0.7;
  static const Duration entranceDuration = Duration(milliseconds: 600);
  static const Duration searchDelay = Duration(milliseconds: 180);

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _textController;
  late final AnimationController _searchController;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textOffsetY;
  late final Animation<double> _searchOpacity;
  late final Animation<double> _searchOffsetY;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: HomeHeroSection.entranceDuration,
    );
    _searchController = AnimationController(
      vsync: this,
      duration: HomeHeroSection.entranceDuration,
    );

    final textCurve = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );
    _textOpacity = textCurve;
    _textOffsetY = Tween<double>(begin: 20, end: 0).animate(textCurve);

    final searchCurve = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOutCubic,
    );
    _searchOpacity = searchCurve;
    _searchOffsetY = Tween<double>(begin: 20, end: 0).animate(searchCurve);

    _textController.forward();
    Future<void>.delayed(HomeHeroSection.searchDelay, () {
      if (mounted) _searchController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double _heroContentWidth(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final horizontalPad = HomeLayout.horizontalPadding(context) * 2;
    final available = (viewport - horizontalPad).clamp(0.0, double.infinity);
    final capped = available.clamp(0.0, HomeHeroSection.maxContentWidth);
    return capped * HomeHeroSection.widthFactor;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final headlineSize = isMobile ? 44.0 : (isDesktop ? 76.0 : 58.0);
    final subheadingSize = isMobile ? 17.0 : 19.0;
    final heroMinHeight = isDesktop ? 520.0 : (isMobile ? 420.0 : 460.0);

    return HomeSection(
      padding: EdgeInsets.only(
        top: HomeLayout.heroPadding(context).top + (isDesktop ? 24 : 12),
        bottom: HomeLayout.heroContentBottomPadding,
      ),
      child: Center(
        child: SizedBox(
          width: _heroContentWidth(context),
          child: SizedBox(
            height: heroMinHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textOffsetY.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.heroHeadlineLine1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w900,
                          height: 0.92,
                          letterSpacing: isDesktop ? -2.2 : -1.4,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.brandGradient.createShader(bounds),
                        child: Text(
                          AppStrings.heroHeadlineLine2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: headlineSize,
                            fontWeight: FontWeight.w900,
                            height: 0.92,
                            letterSpacing: isDesktop ? -2.2 : -1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxxl),
                AnimatedBuilder(
                  animation: _searchController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _searchOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _searchOffsetY.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroSearchPanel(fullWidth: true),
                      SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          AppStrings.heroSubheading,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.82),
                            fontSize: subheadingSize,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                      const _HeroDownloadLink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDownloadLink extends StatefulWidget {
  const _HeroDownloadLink();

  @override
  State<_HeroDownloadLink> createState() => _HeroDownloadLinkState();
}

class _HeroDownloadLinkState extends State<_HeroDownloadLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRouter.download),
        child: Text(
          AppStrings.heroDownloadLink,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hovered
                ? AppColors.white.withValues(alpha: 0.88)
                : AppColors.textSecondary.withValues(alpha: 0.72),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
            decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.primaryPink.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
