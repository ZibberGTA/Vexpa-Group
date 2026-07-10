import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/vexda_logo.dart';
import '../../../shared/layouts/content_container.dart';
import 'home_layout.dart';

/// Premium homepage footer with platform, business, company and support columns.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  static const _platformLinks = [
    ('Map', AppRouter.map),
    ('Search', AppRouter.search),
    ('Saved', AppRouter.saved),
  ];

  static const _businessLinks = [
    ('Advertise', AppRouter.business),
    ('Claim Your Venue', AppRouter.businessClaim),
    ('Pricing', AppRouter.businessPricing),
  ];

  static const _companyLinks = [
    ('About', AppRouter.home),
    ('Careers', AppRouter.home),
    ('Press', AppRouter.home),
  ];

  static const _supportLinks = [
    ('Help Centre', AppRouter.account),
    ('Contact Us', AppRouter.account),
    ('Feedback', AppRouter.account),
  ];

  static const _socialIcons = [
    Icons.camera_alt_outlined,
    Icons.facebook_outlined,
    Icons.music_note_outlined,
    Icons.close_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.35)),
        ),
      ),
      child: ContentContainer(
        maxWidth: HomeLayout.maxContentWidth(context),
        padding: HomeLayout.gridPadding(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: Breakpoints.isDesktop(context) ? 28 : AppSpacing.xxl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final isMedium = constraints.maxWidth >= 640;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VexdaLogo(height: 44),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              AppStrings.homeFooterTagline,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isWide) const SizedBox(height: AppSpacing.xxl),
                      Expanded(
                        flex: isWide ? 4 : 0,
                        child: Wrap(
                          spacing: isMedium ? AppSpacing.xxxl : AppSpacing.xl,
                          runSpacing: AppSpacing.xl,
                          children: [
                            _FooterColumn(
                              title: 'Platform',
                              links: _platformLinks,
                            ),
                            _FooterColumn(
                              title: 'Business',
                              links: _businessLinks,
                            ),
                            _FooterColumn(
                              title: 'Company',
                              links: _companyLinks,
                            ),
                            _FooterColumn(
                              title: 'Support',
                              links: _supportLinks,
                            ),
                          ],
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: AppSpacing.xl),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Follow Vexda',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: _socialIcons
                                  .map(
                                    (icon) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpacing.sm,
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (!isWide) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Follow Vexda',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: _socialIcons
                          .map(
                            (icon) => Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: Icon(
                                icon,
                                size: 20,
                                color: AppColors.textSecondary.withValues(alpha: 0.75),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.homeFooterCopyright,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),

                      ),
                      _FooterTextLink(label: 'Privacy Policy', route: AppRouter.home),
                      _FooterTextLink(label: 'Terms of Service', route: AppRouter.home),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
  });

  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FooterTextLink(label: link.$1, route: link.$2),
          ),
        ),
      ],
    );
  }
}

class _FooterTextLink extends StatefulWidget {
  const _FooterTextLink({
    required this.label,
    required this.route,
  });

  final String label;
  final String route;

  @override
  State<_FooterTextLink> createState() => _FooterTextLinkState();
}

class _FooterTextLinkState extends State<_FooterTextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.route == AppRouter.home && widget.label == 'About') return;
          Navigator.pushNamed(context, widget.route);
        },
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hovered ? AppColors.white : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
