import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/subscription_plans.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/growth_commercial_view_support.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_profile_completion.dart';
import '../venue_dashboard_controller.dart';
import '../venue_dashboard_profile_completion_card.dart';
import 'venue_dashboard_page_widgets.dart';

/// Main workspace content for each venue management tab.
class VenueManagementTabPages {
  VenueManagementTabPages._();

  static Widget contentFor(VenueDashboardTab tab) {
    return switch (tab) {
      VenueDashboardTab.venueProfile => const _VenueProfilePageContent(),
      VenueDashboardTab.deals => const _DealsPageContent(),
      VenueDashboardTab.events => const _EventsPageContent(),
      VenueDashboardTab.gallery => const _GalleryPageContent(),
      VenueDashboardTab.trails => const _TrailsPageContent(),
      VenueDashboardTab.analytics => const _AnalyticsPageContent(),
      VenueDashboardTab.reviews => const _ReviewsPageContent(),
      VenueDashboardTab.team => const _TeamPageContent(),
      VenueDashboardTab.subscription => const _SubscriptionPageContent(),
      VenueDashboardTab.marketing => const _MarketingPageContent(),
      VenueDashboardTab.settings => const _SettingsPageContent(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _VenueProfilePageContent extends StatelessWidget {
  const _VenueProfilePageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 760;
            final preview = _ProfilePreviewCard();
            final completion = VenueDashboardProfileCompletionCard(
              completion: VenueProfileCompletion.mock,
              stretchContent: false,
            );

            if (stack) {
              return Column(
                children: [
                  preview,
                  const SizedBox(height: AppSpacing.lg),
                  completion,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 62, child: preview),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 38, child: completion),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Business Information',
          child: Column(
            children: const [
              VenuePageSummaryTile(
                label: 'Venue name',
                value: 'The Copper Lantern',
                icon: Icons.storefront_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Description',
                value:
                    'Premium cocktail bar and late-night dining in the city centre.',
                icon: Icons.description_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Tags',
                value: 'Cocktails · Live Music · Late Night · Rooftop',
                icon: Icons.label_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 760;
            final hours = VenuePageSection(
              title: 'Opening Hours',
              child: Column(
                children: const [
                  VenuePageSummaryTile(
                    label: 'Mon – Thu',
                    value: '5:00 PM – 12:00 AM',
                    icon: Icons.schedule_outlined,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  VenuePageSummaryTile(
                    label: 'Fri – Sat',
                    value: '5:00 PM – 2:00 AM',
                    icon: Icons.nightlife_outlined,
                  ),
                ],
              ),
            );
            final contact = VenuePageSection(
              title: 'Contact & Links',
              child: Column(
                children: const [
                  VenuePageSummaryTile(
                    label: 'Phone & email',
                    value: '+44 20 7946 0958 · hello@copperlantern.co.uk',
                    icon: Icons.contact_phone_outlined,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  VenuePageSummaryTile(
                    label: 'Website & social',
                    value: 'copperlantern.co.uk · @copperlantern',
                    icon: Icons.link_outlined,
                  ),
                ],
              ),
            );

            if (stack) {
              return Column(
                children: [
                  hours,
                  const SizedBox(height: AppSpacing.lg),
                  contact,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: hours),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: contact),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfilePreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Public Profile Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.55),
                  AppColors.primaryPink.withValues(alpha: 0.35),
                ],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    gradient: AppColors.brandGradient,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'CL',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'The Copper Lantern',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Banner, logo and venue identity as customers see them on Vexda.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealsPageContent extends StatelessWidget {
  const _DealsPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: const [
            VenuePageMetricCard(
              label: 'Active deals',
              value: '6',
              icon: Icons.local_offer_outlined,
            ),
            VenuePageMetricCard(
              label: 'Scheduled',
              value: '2',
              icon: Icons.schedule_outlined,
            ),
            VenuePageMetricCard(
              label: 'Views this week',
              value: '1,842',
              icon: Icons.visibility_outlined,
            ),
            VenuePageMetricCard(
              label: 'Engagement',
              value: '+11%',
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Deal Pipeline',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              VenuePageFilterChips(labels: ['Active', 'Scheduled', 'Expired']),
              SizedBox(height: AppSpacing.lg),
              VenuePageDataTable(
                columns: ['Deal', 'Status', 'Views', 'Ends'],
                rows: [
                  ['2-for-1 Cocktails', 'Active', '612', 'Sunday'],
                  ['Happy Hour Pints', 'Active', '488', 'Daily 5–7 PM'],
                  ['Student Night', 'Scheduled', '—', 'Friday'],
                  ['Winter Warmers', 'Expired', '214', 'Last week'],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Deal Performance',
          child: Column(
            children: const [
              VenuePageChartPlaceholder(title: 'Engagement over time'),
              SizedBox(height: AppSpacing.md),
              VenuePageSummaryTile(
                label: 'Best performing deal',
                value: '2-for-1 Cocktails · 612 views · 84 redemptions',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventsPageContent extends StatelessWidget {
  const _EventsPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: const [
            VenuePageMetricCard(
              label: 'Upcoming',
              value: '4',
              icon: Icons.event_outlined,
            ),
            VenuePageMetricCard(
              label: 'Drafts',
              value: '2',
              icon: Icons.edit_note_outlined,
            ),
            VenuePageMetricCard(
              label: 'Views',
              value: '2,410',
              icon: Icons.visibility_outlined,
            ),
            VenuePageMetricCard(
              label: 'Attendance',
              value: 'Future-ready',
              icon: Icons.groups_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 760;
            final upcoming = VenuePageSection(
              title: 'Upcoming Events',
              child: Column(
                children: const [
                  VenuePageSummaryTile(
                    label: 'Friday DJ Night',
                    value: 'Fri 9:00 PM · Live · 842 views',
                    icon: Icons.event_outlined,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  VenuePageSummaryTile(
                    label: 'Jazz & Cocktails',
                    value: 'Thu 8:00 PM · Published · 516 views',
                    icon: Icons.music_note_outlined,
                  ),
                ],
              ),
            );
            final calendar = VenuePageSection(
              title: 'Calendar',
              child: Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  color: AppColors.surfaceElevated.withValues(alpha: 0.45),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.16),
                  ),
                ),
                child: const Text(
                  'June 2026 · 4 events scheduled',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
            if (stack) {
              return Column(
                children: [
                  upcoming,
                  const SizedBox(height: AppSpacing.lg),
                  calendar,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: upcoming),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: calendar),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Draft Events & Performance',
          child: Column(
            children: const [
              VenuePageSummaryTile(
                label: 'Sunday Brunch Sessions',
                value: 'Draft · not yet published',
                icon: Icons.edit_note_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Top event this month',
                value: 'Friday DJ Night · 842 views',
                icon: Icons.insights_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryPageContent extends StatelessWidget {
  const _GalleryPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: const [
            VenuePageMetricCard(
              label: 'Photos',
              value: '24',
              icon: Icons.photo_library_outlined,
            ),
            VenuePageMetricCard(
              label: 'Featured',
              value: '6',
              icon: Icons.star_outline_rounded,
            ),
            VenuePageMetricCard(
              label: 'Storage used',
              value: '38%',
              icon: Icons.storage_outlined,
            ),
            VenuePageMetricCard(
              label: 'Pending uploads',
              value: '2',
              icon: Icons.cloud_upload_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Photo Grid',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final featured = index < 2;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withValues(
                        alpha: 0.35 + (index * 0.04),
                      ),
                      AppColors.primaryPink.withValues(
                        alpha: 0.22 + (index * 0.03),
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: featured
                        ? AppColors.primaryPink.withValues(alpha: 0.45)
                        : AppColors.primaryPurple.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: featured
                    ? const Text(
                        'Featured',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Upload Status & Organisation',
          child: Column(
            children: const [
              VenuePageSummaryTile(
                label: 'Latest upload batch',
                value: '2 photos processing · 1 hour ago',
                icon: Icons.cloud_upload_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Gallery order',
                value: 'Interior → Bar → Events → Food',
                icon: Icons.reorder_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailsPageContent extends StatelessWidget {
  const _TrailsPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageSection(
          title: 'Trails Near You',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Discover local trails your venue can appear in and manage your trail participation.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 760;
                  final cardWidth = twoColumns
                      ? (constraints.maxWidth - AppSpacing.md) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children:
                        const [
                              _NearbyTrailCard(
                                name: 'Manchester Cocktail Trail',
                                status: 'Published',
                                venueCount: '12 venues',
                                distance: '0.4 mi away',
                                type: 'Cocktail bars',
                                eligibility: _TrailEligibility.alreadyIncluded,
                              ),
                              _NearbyTrailCard(
                                name: 'Northern Quarter Night Out',
                                status: 'Scheduled',
                                venueCount: '8 venues',
                                distance: '0.7 mi away',
                                type: 'Nightlife',
                                eligibility: _TrailEligibility.eligible,
                              ),
                              _NearbyTrailCard(
                                name: 'Live Music Weekend Route',
                                status: 'Draft',
                                venueCount: '6 venues',
                                distance: '1.2 mi away',
                                type: 'Live music',
                                eligibility: _TrailEligibility.requestAccess,
                              ),
                              _NearbyTrailCard(
                                name: 'Late Night Student Trail',
                                status: 'Closed',
                                venueCount: '10 venues',
                                distance: 'Nearby',
                                type: 'Student nights',
                                eligibility: _TrailEligibility.notEligible,
                              ),
                            ]
                            .map(
                              (card) => SizedBox(width: cardWidth, child: card),
                            )
                            .toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const _TrailEmptyState(
                title: 'No trails nearby yet.',
                message:
                    'When local trails are created, eligible venues will appear here.',
                actionLabel: 'Learn about Trails',
                icon: Icons.route_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'My Trail Participation',
          child: Column(
            children: [
              const _TrailParticipationTile(
                name: 'Manchester Cocktail Trail',
                status: 'Published',
                position: 'Stop 4 of 12',
                availability: 'Available now',
                actionLabel: 'View',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _TrailParticipationTile(
                name: 'Northern Quarter Night Out',
                status: 'Scheduled',
                position: 'Proposed stop',
                availability: 'Starts next Friday',
                actionLabel: 'Contact Support',
              ),
              const SizedBox(height: AppSpacing.lg),
              _TrailEmptyState(
                title:
                    'Complete your venue profile to become eligible for local trails.',
                message:
                    'Trails work best when customers can see your photos, opening hours and location clearly.',
                actionLabel: 'Improve Venue Profile',
                icon: Icons.auto_fix_high_rounded,
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Trail Opportunities',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _TrailOpportunityCard(
                name: 'Northern Quarter Night Out',
                type: 'Late-night venue trail',
                requirements:
                    'Open after 11 PM · verified location · banner uploaded',
                eligibility: 'Eligible',
              ),
              SizedBox(height: AppSpacing.sm),
              _TrailOpportunityCard(
                name: 'Happy Hour Discovery Route',
                type: 'Deals-led trail',
                requirements:
                    'At least one active deal · public profile complete',
                eligibility: 'Request access',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const VenuePageSection(
          title: 'Trail Readiness Checklist',
          child: _TrailReadinessChecklist(),
        ),
      ],
    );
  }
}

enum _TrailEligibility { eligible, alreadyIncluded, notEligible, requestAccess }

class _NearbyTrailCard extends StatelessWidget {
  const _NearbyTrailCard({
    required this.name,
    required this.status,
    required this.venueCount,
    required this.distance,
    required this.type,
    required this.eligibility,
  });

  final String name;
  final String status;
  final String venueCount;
  final String distance;
  final String type;
  final _TrailEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TrailIconBadge(icon: Icons.route_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _TrailStatusPill(label: status),
                        _TrailEligibilityPill(eligibility: eligibility),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _TrailMetaChip(
                icon: Icons.storefront_outlined,
                label: venueCount,
              ),
              _TrailMetaChip(icon: Icons.near_me_outlined, label: distance),
              _TrailMetaChip(icon: Icons.category_outlined, label: type),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TrailActionButton(
                label: 'View Trail',
                icon: Icons.open_in_new_rounded,
              ),
              _TrailActionButton(
                label: eligibility == _TrailEligibility.alreadyIncluded
                    ? 'Included'
                    : 'Request to Join',
                icon: Icons.how_to_reg_outlined,
                enabled:
                    eligibility != _TrailEligibility.alreadyIncluded &&
                    eligibility != _TrailEligibility.notEligible,
              ),
              _TrailActionButton(
                label: 'Preview Route',
                icon: Icons.map_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrailParticipationTile extends StatelessWidget {
  const _TrailParticipationTile({
    required this.name,
    required this.status,
    required this.position,
    required this.availability,
    required this.actionLabel,
  });

  final String name;
  final String status;
  final String position;
  final String availability;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassTile(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailIconBadge(icon: Icons.alt_route_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _TrailStatusPill(label: status),
                    _TrailMetaChip(
                      icon: Icons.format_list_numbered_rounded,
                      label: position,
                    ),
                    _TrailMetaChip(
                      icon: Icons.event_available_outlined,
                      label: availability,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TrailActionButton(
            label: actionLabel,
            icon: Icons.chevron_right_rounded,
          ),
        ],
      ),
    );
  }
}

class _TrailOpportunityCard extends StatelessWidget {
  const _TrailOpportunityCard({
    required this.name,
    required this.type,
    required this.requirements,
    required this.eligibility,
  });

  final String name;
  final String type;
  final String requirements;
  final String eligibility;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassTile(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailIconBadge(icon: Icons.add_road_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  type,
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  requirements,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TrailEligibilityText(label: eligibility),
              const SizedBox(height: AppSpacing.sm),
              const _TrailActionButton(
                label: 'Request to Join',
                icon: Icons.how_to_reg_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrailReadinessChecklist extends StatelessWidget {
  const _TrailReadinessChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Venue profile complete', true),
      ('Banner uploaded', true),
      ('Logo uploaded', true),
      ('Opening hours complete', true),
      ('Address/location verified', true),
      ('At least one deal/event/drink available if required', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: 280,
                  child: _TrailChecklistRow(label: item.$1, completed: item.$2),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Trail readiness helps the Vexda team understand which venues are ready to appear in curated local routes.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.95),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TrailEmptyState extends StatelessWidget {
  const _TrailEmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.42),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          _TrailIconBadge(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TrailActionButton(
            label: actionLabel,
            icon: Icons.chevron_right_rounded,
          ),
        ],
      ),
    );
  }
}

class _TrailGlassTile extends StatelessWidget {
  const _TrailGlassTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.52),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TrailIconBadge extends StatelessWidget {
  const _TrailIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        color: AppColors.primaryPurple.withValues(alpha: 0.16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(icon, size: 19, color: AppColors.primaryPink),
    );
  }
}

class _TrailMetaChip extends StatelessWidget {
  const _TrailMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrailStatusPill extends StatelessWidget {
  const _TrailStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _SmallPill(
      label: label,
      color: switch (label.toLowerCase()) {
        'published' => AppColors.primaryPink,
        'scheduled' => AppColors.primaryPurple,
        'draft' => AppColors.trailGold,
        _ => AppColors.textSecondary,
      },
    );
  }
}

class _TrailEligibilityPill extends StatelessWidget {
  const _TrailEligibilityPill({required this.eligibility});

  final _TrailEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final label = switch (eligibility) {
      _TrailEligibility.eligible => 'Eligible',
      _TrailEligibility.alreadyIncluded => 'Already included',
      _TrailEligibility.notEligible => 'Not eligible',
      _TrailEligibility.requestAccess => 'Request access',
    };
    final color = switch (eligibility) {
      _TrailEligibility.eligible => AppColors.primaryPink,
      _TrailEligibility.alreadyIncluded => AppColors.primaryPurple,
      _TrailEligibility.notEligible => AppColors.textSecondary,
      _TrailEligibility.requestAccess => AppColors.trailGold,
    };
    return _SmallPill(label: label, color: color);
  }
}

class _TrailEligibilityText extends StatelessWidget {
  const _TrailEligibilityText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryPink,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == AppColors.textSecondary
              ? AppColors.textSecondary
              : AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TrailActionButton extends StatelessWidget {
  const _TrailActionButton({
    required this.label,
    required this.icon,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled
          ? () => showVenuePagePlaceholderAction(context, label)
          : null,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.white : AppColors.textSecondary,
        side: BorderSide(
          color: enabled
              ? AppColors.primaryPurple.withValues(alpha: 0.38)
              : AppColors.border.withValues(alpha: 0.28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

class _TrailChecklistRow extends StatelessWidget {
  const _TrailChecklistRow({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: completed
              ? AppColors.primaryPink
              : AppColors.textSecondary.withValues(alpha: 0.48),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: completed
                  ? AppColors.white
                  : AppColors.textSecondary.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsPageContent extends StatefulWidget {
  const _AnalyticsPageContent();

  @override
  State<_AnalyticsPageContent> createState() => _AnalyticsPageContentState();
}

class _AnalyticsPageContentState extends State<_AnalyticsPageContent> {
  String _dateRange = 'Last 30 Days';
  String _discoveryFilter = 'Views';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnalyticsToolbar(
          selectedRange: _dateRange,
          onRangeSelected: (range) => setState(() => _dateRange = range),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _AnalyticsKpiGrid(),
        const SizedBox(height: AppSpacing.lg),
        _DiscoveryLineChartSection(
          selectedFilter: _discoveryFilter,
          onFilterSelected: (filter) =>
              setState(() => _discoveryFilter = filter),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _DiscoverySourcesSection(),
        const SizedBox(height: AppSpacing.lg),
        const _MostSearchedItemsSection(),
        const SizedBox(height: AppSpacing.lg),
        const _PopularTimesSection(),
        const SizedBox(height: AppSpacing.lg),
        const _CustomerEngagementSection(),
        const SizedBox(height: AppSpacing.lg),
        const _EventPerformanceSection(),
        const SizedBox(height: AppSpacing.lg),
        const _DealsPerformanceSection(),
        const SizedBox(height: AppSpacing.lg),
        const _DrinkIntelligenceSection(),
        const SizedBox(height: AppSpacing.lg),
        const _CompetitiveInsightsSection(),
        const SizedBox(height: AppSpacing.lg),
        const _CustomerDemographicsSection(),
        const SizedBox(height: AppSpacing.lg),
        const _MapIntelligenceSection(),
        const SizedBox(height: AppSpacing.lg),
        const _MarketingInsightsSection(),
        const SizedBox(height: AppSpacing.lg),
        const _GoalsSection(),
        const SizedBox(height: AppSpacing.lg),
        const _AnalyticsRecentActivitySection(),
      ],
    );
  }
}

class _AnalyticsToolbar extends StatelessWidget {
  const _AnalyticsToolbar({
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final String selectedRange;
  final ValueChanged<String> onRangeSelected;

  static const _ranges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'Custom',
  ];

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Performance Controls',
      padding: const EdgeInsets.all(AppSpacing.md),
      trailing: PopupMenuButton<String>(
        tooltip: 'Export analytics',
        color: AppColors.surfaceElevated,
        onSelected: (format) => showVenuePagePlaceholderAction(context, format),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'Download PDF', child: Text('Download PDF')),
          PopupMenuItem(value: 'Download CSV', child: Text('Download CSV')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_outlined, color: AppColors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Export',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final range in _ranges)
            _AnalyticsFilterChip(
              label: range,
              selected: selectedRange == range,
              onTap: () => onRangeSelected(range),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsKpiGrid extends StatelessWidget {
  const _AnalyticsKpiGrid();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsResponsiveGrid(
      minCardWidth: 190,
      children: const [
        _AnalyticsKpiCard(
          title: 'Profile Views',
          value: '18,420',
          change: '▲ 24% vs previous period',
          icon: Icons.visibility_outlined,
          insight: 'More customers are opening your public venue page.',
        ),
        _AnalyticsKpiCard(
          title: 'Search Appearances',
          value: '42,890',
          change: '▲ 18% vs previous period',
          icon: Icons.search_rounded,
          insight: 'How often the venue appeared in customer search.',
        ),
        _AnalyticsKpiCard(
          title: 'Direction Requests',
          value: '1,286',
          change: '▲ 31% vs previous period',
          icon: Icons.directions_outlined,
          insight: 'High-intent visitors requesting navigation.',
        ),
        _AnalyticsKpiCard(
          title: 'Venue Saves',
          value: '3,214',
          change: '▲ 12% vs previous period',
          icon: Icons.bookmark_outline_rounded,
          insight: 'People who favourited the venue for later.',
        ),
      ],
    );
  }
}

class _AnalyticsKpiCard extends StatefulWidget {
  const _AnalyticsKpiCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.insight,
  });

  final String title;
  final String value;
  final String change;
  final IconData icon;
  final String insight;

  @override
  State<_AnalyticsKpiCard> createState() => _AnalyticsKpiCardState();
}

class _AnalyticsKpiCardState extends State<_AnalyticsKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPink.withValues(alpha: _hovered ? 0.22 : 0.16),
                AppColors.primaryPurple.withValues(
                  alpha: _hovered ? 0.20 : 0.12,
                ),
                AppColors.surfaceElevated.withValues(alpha: 0.78),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryPink.withValues(
                alpha: _hovered ? 0.42 : 0.22,
              ),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Icon(widget.icon, color: AppColors.primaryPink, size: 22),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.change,
                style: const TextStyle(
                  color: Color(0xFF44D7A8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.insight,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryLineChartSection extends StatelessWidget {
  const _DiscoveryLineChartSection({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  static const filters = [
    'Views',
    'Searches',
    'Map Opens',
    'Directions',
    'Venue Saves',
  ];

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Customer Discovery Over Time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final filter in filters)
                _AnalyticsFilterChip(
                  label: filter,
                  selected: selectedFilter == filter,
                  onTap: () => onFilterSelected(filter),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _AnalyticsLineChartPainter(),
              child: const _ChartOverlayLabels(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverySourcesSection extends StatelessWidget {
  const _DiscoverySourcesSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Discovery Sources',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 760;
          final chart = SizedBox(
            height: 260,
            child: CustomPaint(painter: _DonutChartPainter()),
          );
          final legend = Column(
            children: const [
              _AnalyticsLegendRow(
                label: 'Search',
                value: '38%',
                color: AppColors.primaryPink,
              ),
              _AnalyticsLegendRow(
                label: 'Map',
                value: '24%',
                color: AppColors.primaryPurple,
              ),
              _AnalyticsLegendRow(
                label: "Tonight's Trails",
                value: '15%',
                color: AppColors.trailGold,
              ),
              _AnalyticsLegendRow(
                label: 'Saved Venues',
                value: '11%',
                color: Color(0xFF44D7A8),
              ),
              _AnalyticsLegendRow(
                label: 'External Website',
                value: '8%',
                color: Color(0xFF75A7FF),
              ),
              _AnalyticsLegendRow(
                label: 'QR Codes (future)',
                value: '4%',
                color: Color(0xFFFF8FC7),
              ),
            ],
          );
          if (stack) {
            return Column(
              children: [
                chart,
                const SizedBox(height: AppSpacing.lg),
                legend,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: chart),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class _MostSearchedItemsSection extends StatelessWidget {
  const _MostSearchedItemsSection();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsInsightTable(
      title: 'Most Searched Items',
      columns: const ['Category', 'Top item', 'Searches', 'Trend'],
      rows: const [
        ['Top Drinks', 'Pornstar Martini', '2,840', '▲ 34%'],
        ['Top Drinks', 'Espresso Martini', '2,410', '▲ 21%'],
        ['Top Deals', '2 for 1 Cocktails', '1,872', '▲ 18%'],
        ['Top Events', 'Live DJ Friday', '1,506', '▲ 27%'],
        ['Top Search Terms', 'cocktails near me', '4,920', '▲ 22%'],
      ],
    );
  }
}

class _PopularTimesSection extends StatelessWidget {
  const _PopularTimesSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Popular Times',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Busiest periods are highlighted so teams can plan promotions, staffing and events with confidence.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _AnalyticsHeatmap(),
        ],
      ),
    );
  }
}

class _CustomerEngagementSection extends StatelessWidget {
  const _CustomerEngagementSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Customer Engagement',
      child: _AnalyticsResponsiveGrid(
        minCardWidth: 150,
        children: const [
          _MiniAnalyticsCard(
            label: 'Average Visit Duration',
            value: 'Future',
            icon: Icons.timer_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Venue Saves',
            value: '3,214',
            icon: Icons.bookmark_outline_rounded,
          ),
          _MiniAnalyticsCard(
            label: 'Repeat Visitors',
            value: '28%',
            icon: Icons.repeat_rounded,
          ),
          _MiniAnalyticsCard(
            label: 'Notification Opt-ins',
            value: '842',
            icon: Icons.notifications_active_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Gallery Views',
            value: '9,840',
            icon: Icons.photo_library_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Website Clicks',
            value: '1,126',
            icon: Icons.language_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Phone Calls',
            value: '384',
            icon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }
}

class _EventPerformanceSection extends StatelessWidget {
  const _EventPerformanceSection();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsLeaderboard(
      title: 'Event Performance',
      items: const [
        _LeaderboardItem(
          'Live DJ Friday',
          'Most Viewed Events',
          '2,410 views',
          0.92,
        ),
        _LeaderboardItem(
          'Rooftop House Night',
          'Most Saved Events',
          '642 saves',
          0.78,
        ),
        _LeaderboardItem(
          'Bank Holiday Brunch',
          'Attendance Estimate',
          '184 guests',
          0.66,
        ),
        _LeaderboardItem('Open Decks', 'Conversion Rate', '7.8%', 0.58),
      ],
    );
  }
}

class _DealsPerformanceSection extends StatelessWidget {
  const _DealsPerformanceSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Deals Performance',
      child: _AnalyticsResponsiveGrid(
        minCardWidth: 180,
        children: const [
          _MiniAnalyticsCard(
            label: 'Best Performing Deal',
            value: '2 for 1 Cocktails',
            icon: Icons.emoji_events_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Most Viewed Deal',
            value: 'Happy Hour Pints',
            icon: Icons.visibility_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Most Saved Deal',
            value: 'Student Night',
            icon: Icons.bookmark_outline_rounded,
          ),
          _MiniAnalyticsCard(
            label: 'Redemption Rate',
            value: 'Future',
            icon: Icons.qr_code_2_rounded,
          ),
        ],
      ),
    );
  }
}

class _DrinkIntelligenceSection extends StatelessWidget {
  const _DrinkIntelligenceSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Drink Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "One of Vexda's flagship insights: understand what customers want before they arrive.",
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AnalyticsResponsiveGrid(
            minCardWidth: 180,
            children: const [
              _MiniAnalyticsCard(
                label: 'Trending Drinks',
                value: 'Mojito',
                icon: Icons.trending_up_rounded,
              ),
              _MiniAnalyticsCard(
                label: 'Most Viewed Drinks',
                value: 'Pornstar Martini',
                icon: Icons.visibility_outlined,
              ),
              _MiniAnalyticsCard(
                label: 'Fastest Growing Drinks',
                value: 'Guinness',
                icon: Icons.rocket_launch_outlined,
              ),
              _MiniAnalyticsCard(
                label: 'Declining Drinks',
                value: 'Aperol Spritz',
                icon: Icons.trending_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _CategoryPerformanceBars(),
        ],
      ),
    );
  }
}

class _CompetitiveInsightsSection extends StatelessWidget {
  const _CompetitiveInsightsSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Competitive Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _RecommendationCard(
            icon: Icons.shield_outlined,
            title: 'Anonymous local benchmark',
            body:
                'Your venue ranks in the top 18% locally. Cocktail searches are up 22% and wine searches increased 14%.',
          ),
          SizedBox(height: AppSpacing.md),
          _RecommendationCard(
            icon: Icons.local_bar_outlined,
            title:
                'Customers nearby are searching for Mojito, Guinness and Pornstar Martini.',
            body:
                'Suggested action: consider creating a Mojito promotion this week.',
          ),
        ],
      ),
    );
  }
}

class _CustomerDemographicsSection extends StatelessWidget {
  const _CustomerDemographicsSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Customer Demographics',
      child: _AnalyticsResponsiveGrid(
        minCardWidth: 160,
        children: const [
          _MiniAnalyticsCard(
            label: 'Age Groups',
            value: '25-34 leads',
            icon: Icons.cake_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'Gender',
            value: 'Future ready',
            icon: Icons.people_outline,
          ),
          _MiniAnalyticsCard(
            label: 'Visitor Types',
            value: 'Social groups',
            icon: Icons.groups_outlined,
          ),
          _MiniAnalyticsCard(
            label: 'New vs Returning',
            value: '64 / 36',
            icon: Icons.compare_arrows_rounded,
          ),
          _MiniAnalyticsCard(
            label: 'Local vs Tourist',
            value: '71 / 29',
            icon: Icons.map_outlined,
          ),
        ],
      ),
    );
  }
}

class _MapIntelligenceSection extends StatelessWidget {
  const _MapIntelligenceSection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Map Intelligence',
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepPurple.withValues(alpha: 0.82),
              AppColors.surfaceElevated.withValues(alpha: 0.74),
            ],
          ),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.18),
          ),
        ),
        child: CustomPaint(
          painter: _MapHeatPainter(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AnalyticsPill(label: 'Future heat overlay'),
                const Spacer(),
                const Text(
                  'Where visitors are discovering your venue',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Live map intelligence will connect discovery density, nearby searches and route requests.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.86),
                    height: 1.45,
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

class _MarketingInsightsSection extends StatelessWidget {
  const _MarketingInsightsSection();

  @override
  Widget build(BuildContext context) {
    final snapshot = GrowthCommercialViewSupport.fromDashboard(
      VenueDashboardController.maybeOf(context),
    );

    return VenuePageSection(
      title: 'Marketing Insights',
      child: _AnalyticsResponsiveGrid(
        minCardWidth: 240,
        children: [
          for (final card in snapshot.recommendationCards)
            _RecommendationCard(
              icon: card.icon,
              title: card.title,
              body: card.body,
            ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) {
    final snapshot = GrowthCommercialViewSupport.fromDashboard(
      VenueDashboardController.maybeOf(context),
    );

    return VenuePageSection(
      title: 'Goals',
      child: _AnalyticsResponsiveGrid(
        minCardWidth: 180,
        children: [
          for (final goal in snapshot.goalCards)
            _GoalCard(
              label: goal.label,
              value: goal.value,
              progress: goal.progress,
            ),
        ],
      ),
    );
  }
}

class _AnalyticsRecentActivitySection extends StatelessWidget {
  const _AnalyticsRecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Recent Activity',
      child: Column(
        children: const [
          _TimelineItem(
            title: 'Profile updated',
            time: 'Today, 10:42',
            icon: Icons.storefront_outlined,
          ),
          _TimelineItem(
            title: 'Deal created',
            time: 'Yesterday',
            icon: Icons.local_offer_outlined,
          ),
          _TimelineItem(
            title: 'Gallery uploaded',
            time: '2 days ago',
            icon: Icons.photo_library_outlined,
          ),
          _TimelineItem(
            title: 'Event published',
            time: '4 days ago',
            icon: Icons.event_outlined,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsResponsiveGrid extends StatelessWidget {
  const _AnalyticsResponsiveGrid({
    required this.children,
    this.minCardWidth = 220,
  });

  final List<Widget> children;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final columns = (constraints.maxWidth / minCardWidth).floor().clamp(
          1,
          4,
        );
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _AnalyticsFilterChip extends StatelessWidget {
  const _AnalyticsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected ? AppColors.brandGradient : null,
            color: selected
                ? null
                : AppColors.surfaceElevated.withValues(alpha: 0.58),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.primaryPurple.withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsPill extends StatelessWidget {
  const _AnalyticsPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.primaryPink.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniAnalyticsCard extends StatelessWidget {
  const _MiniAnalyticsCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.58),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 20),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsInsightTable extends StatelessWidget {
  const _AnalyticsInsightTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: title,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          columns: columns
              .map((column) => DataColumn(label: Text(column)))
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (cell) => DataCell(
                          Text(
                            cell,
                            style: TextStyle(
                              color: cell.startsWith('▲')
                                  ? const Color(0xFF44D7A8)
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.92,
                                    ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AnalyticsHeatmap extends StatelessWidget {
  const _AnalyticsHeatmap();

  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const hours = ['12', '15', '18', '21', '00'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 42),
            for (final hour in hours)
              Expanded(
                child: Text(
                  hour,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var dayIndex = 0; dayIndex < days.length; dayIndex++) ...[
          Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  days[dayIndex],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (var hourIndex = 0; hourIndex < hours.length; hourIndex++)
                Expanded(
                  child: _HeatCell(
                    intensity: ((dayIndex + 2) * (hourIndex + 3) % 10) / 10,
                    highlight: dayIndex >= 3 && hourIndex >= 2,
                  ),
                ),
            ],
          ),
          if (dayIndex < days.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.intensity, required this.highlight});

  final double intensity;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primaryPink : AppColors.primaryPurple;
    return Tooltip(
      message: highlight ? 'Busiest period' : 'Moderate discovery',
      child: Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: color.withValues(alpha: 0.10 + (intensity * 0.42)),
          border: Border.all(
            color: color.withValues(alpha: highlight ? 0.45 : 0.18),
          ),
        ),
      ),
    );
  }
}

class _CategoryPerformanceBars extends StatelessWidget {
  const _CategoryPerformanceBars();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ProgressInsightRow(label: 'Cocktails', value: '42%', progress: 0.84),
        _ProgressInsightRow(label: 'Beer', value: '23%', progress: 0.56),
        _ProgressInsightRow(label: 'Wine', value: '18%', progress: 0.48),
        _ProgressInsightRow(label: 'Spirits', value: '11%', progress: 0.34),
        _ProgressInsightRow(label: 'Shots', value: '6%', progress: 0.22),
      ],
    );
  }
}

class _ProgressInsightRow extends StatelessWidget {
  const _ProgressInsightRow({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceElevated.withValues(
                  alpha: 0.72,
                ),
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 42,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.16),
            AppColors.surfaceElevated.withValues(alpha: 0.62),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLeaderboard extends StatelessWidget {
  const _AnalyticsLeaderboard({required this.title, required this.items});

  final String title;
  final List<_LeaderboardItem> items;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _LeaderboardRow(rank: i + 1, item: items[i]),
            if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardItem {
  const _LeaderboardItem(this.title, this.metric, this.value, this.progress);

  final String title;
  final String metric;
  final String value;
  final double progress;
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.item});

  final int rank;
  final _LeaderboardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: const TextStyle(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.metric,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 110,
            child: _LeaderboardMetric(
              value: item.value,
              progress: item.progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardMetric extends StatelessWidget {
  const _LeaderboardMetric({required this.value, required this.progress});

  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.background.withValues(alpha: 0.65),
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.58),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.background.withValues(alpha: 0.65),
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.time,
    required this.icon,
  });

  final String title;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withValues(alpha: 0.16),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLegendRow extends StatelessWidget {
  const _AnalyticsLegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartOverlayLabels extends StatelessWidget {
  const _ChartOverlayLabels();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Align(
        alignment: Alignment.topRight,
        child: _AnalyticsPill(label: 'Live data ready'),
      ),
    );
  }
}

class _AnalyticsLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [0.38, 0.52, 0.48, 0.62, 0.58, 0.72, 0.68, 0.82, 0.76, 0.90];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryPink.withValues(alpha: 0.22),
          AppColors.primaryPurple.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.brandGradient.createShader(Offset.zero & size);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const values = [38.0, 24.0, 15.0, 11.0, 8.0, 4.0];
    const colors = [
      AppColors.primaryPink,
      AppColors.primaryPurple,
      AppColors.trailGold,
      Color(0xFF44D7A8),
      Color(0xFF75A7FF),
      Color(0xFFFF8FC7),
    ];
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / 100 * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      canvas.drawArc(rect, start, sweep - 0.06, false, paint);
      start += sweep;
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '38%\nSearch',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          height: 1.35,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapHeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.16);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 30), roadPaint);
    }
    for (final point in const [
      Offset(0.28, 0.38),
      Offset(0.58, 0.48),
      Offset(0.72, 0.32),
      Offset(0.42, 0.68),
    ]) {
      final center = Offset(size.width * point.dx, size.height * point.dy);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryPink.withValues(alpha: 0.38),
            AppColors.primaryPurple.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 70));
      canvas.drawCircle(center, 70, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReviewsPageContent extends StatelessWidget {
  const _ReviewsPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: const [
            VenuePageMetricCard(
              label: 'Average rating',
              value: '4.7',
              icon: Icons.star_rounded,
            ),
            VenuePageMetricCard(
              label: 'Total reviews',
              value: '128',
              icon: Icons.rate_review_outlined,
            ),
            VenuePageMetricCard(
              label: 'Pending responses',
              value: '3',
              icon: Icons.reply_outlined,
            ),
            VenuePageMetricCard(
              label: 'Sentiment',
              value: '92% positive',
              icon: Icons.sentiment_satisfied_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Recent Reviews',
          child: Column(
            children: const [
              VenuePageSummaryTile(
                label: '★★★★★ · Great atmosphere',
                value: '"Amazing cocktails and friendly staff." · 2 hours ago',
                icon: Icons.rate_review_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: '★★★★☆ · Loved the DJ set',
                value: '"Perfect Friday night spot." · Yesterday',
                icon: Icons.music_note_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Response management',
                value: '3 reviews awaiting a venue response',
                icon: Icons.reply_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamPageContent extends StatefulWidget {
  const _TeamPageContent();

  @override
  State<_TeamPageContent> createState() => _TeamPageContentState();
}

class _TeamPageContentState extends State<_TeamPageContent> {
  int _selectedRoleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedRole = _teamRoles[_selectedRoleIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: const [
            VenuePageMetricCard(
              label: 'Team Members',
              value: '5',
              icon: Icons.groups_outlined,
            ),
            VenuePageMetricCard(
              label: 'Pending Invites',
              value: '1',
              icon: Icons.mail_outline_rounded,
            ),
            VenuePageMetricCard(
              label: 'Roles',
              value: '4',
              icon: Icons.badge_outlined,
            ),
            VenuePageMetricCard(
              label: 'Active Today',
              value: '3',
              icon: Icons.online_prediction_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Team Members',
          child: Column(
            children: [
              for (var i = 0; i < _teamMembers.length; i++) ...[
                _TeamMemberRow(member: _teamMembers[i]),
                if (i < _teamMembers.length - 1)
                  Divider(
                    height: AppSpacing.lg,
                    color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Roles & Permissions',
          trailing: _CreateCustomRoleButton(
            onPressed: () =>
                _showTeamPlaceholder(context, 'Create Custom Role'),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 900;
              final roles = _RoleList(
                roles: _teamRoles,
                selectedIndex: _selectedRoleIndex,
                onSelected: (index) =>
                    setState(() => _selectedRoleIndex = index),
              );
              final permissions = _RolePermissionsEditor(role: selectedRole);

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    roles,
                    const SizedBox(height: AppSpacing.lg),
                    permissions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 36, child: roles),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 64, child: permissions),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

const _teamMembers = [
  _TeamMember(
    name: 'Alex Morgan',
    email: 'alex@copperlantern.co.uk',
    role: 'Owner',
    status: 'Active',
    lastActive: 'Now',
    initials: 'AM',
  ),
  _TeamMember(
    name: 'Jamie Lee',
    email: 'jamie@copperlantern.co.uk',
    role: 'Manager',
    status: 'Active',
    lastActive: '12 min ago',
    initials: 'JL',
  ),
  _TeamMember(
    name: 'Maya Chen',
    email: 'maya@copperlantern.co.uk',
    role: 'Supervisor',
    status: 'Active',
    lastActive: 'Today',
    initials: 'MC',
  ),
  _TeamMember(
    name: 'Sam Patel',
    email: 'sam@copperlantern.co.uk',
    role: 'Staff',
    status: 'Disabled',
    lastActive: '2 weeks ago',
    initials: 'SP',
  ),
  _TeamMember(
    name: 'Taylor Reed',
    email: 'taylor@copperlantern.co.uk',
    role: 'Staff',
    status: 'Invited',
    lastActive: 'Invite sent 3h ago',
    initials: 'TR',
  ),
];

const _teamRoles = [
  _TeamRole(
    name: 'Owner',
    memberCount: 1,
    description:
        'Full venue control, billing, team management and publishing access.',
  ),
  _TeamRole(
    name: 'Manager',
    memberCount: 1,
    description:
        'Runs daily venue operations across content, events and staff workflows.',
  ),
  _TeamRole(
    name: 'Supervisor',
    memberCount: 1,
    description:
        'Supports shift operations with limited publishing and team controls.',
  ),
  _TeamRole(
    name: 'Staff',
    memberCount: 2,
    description:
        'Handles day-to-day updates with restricted administrative access.',
  ),
];

const _permissionGroups = [
  _PermissionGroup(
    title: 'Venue Management',
    permissions: [
      'Edit venue details',
      'Upload branding',
      'Opening hours',
      'Tags',
    ],
  ),
  _PermissionGroup(
    title: 'Drinks',
    permissions: ['View drinks', 'Add drinks', 'Edit drinks', 'Delete drinks'],
  ),
  _PermissionGroup(
    title: 'Deals',
    permissions: ['View', 'Create', 'Edit', 'Delete'],
  ),
  _PermissionGroup(
    title: 'Events',
    permissions: ['View', 'Create', 'Edit', 'Delete'],
  ),
  _PermissionGroup(
    title: 'Gallery',
    permissions: ['Upload', 'Delete', 'Reorder'],
  ),
  _PermissionGroup(
    title: 'Trails',
    permissions: ['View', 'Create', 'Publish', 'Archive'],
  ),
  _PermissionGroup(
    title: 'Marketing',
    permissions: ['Campaigns', 'Notifications'],
  ),
  _PermissionGroup(
    title: 'Analytics',
    permissions: ['Basic Analytics', 'Advanced Analytics'],
  ),
  _PermissionGroup(
    title: 'Subscription',
    permissions: ['View plan', 'Upgrade subscription'],
  ),
  _PermissionGroup(
    title: 'Team',
    permissions: ['Invite members', 'Remove members', 'Edit roles'],
  ),
];

class _TeamMember {
  const _TeamMember({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.lastActive,
    required this.initials,
  });

  final String name;
  final String email;
  final String role;
  final String status;
  final String lastActive;
  final String initials;
}

class _TeamRole {
  const _TeamRole({
    required this.name,
    required this.memberCount,
    required this.description,
  });

  final String name;
  final int memberCount;
  final String description;
}

class _PermissionGroup {
  const _PermissionGroup({required this.title, required this.permissions});

  final String title;
  final List<String> permissions;
}

class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final identity = Row(
          children: [
            _TeamAvatar(
              initials: member.initials,
              disabled: member.status == 'Disabled',
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.88),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final details = compact
            ? Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _RolePill(label: member.role),
                  _StatusPill(label: member.status),
                  _LastActivePill(label: member.lastActive),
                ],
              )
            : Row(
                children: [
                  SizedBox(width: 118, child: _RolePill(label: member.role)),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 110,
                    child: _StatusPill(label: member.status),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _LastActivePill(label: member.lastActive)),
                ],
              );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TeamEditButton(member: member),
            const SizedBox(width: AppSpacing.sm),
            _TeamIconButton(
              icon: Icons.person_remove_outlined,
              tooltip: 'Remove account',
              onPressed: () =>
                  _showTeamPlaceholder(context, 'Remove ${member.name}'),
              danger: true,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: AppSpacing.md),
              details,
              const SizedBox(height: AppSpacing.md),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 30, child: identity),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 44, child: details),
            const SizedBox(width: AppSpacing.lg),
            actions,
          ],
        );
      },
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.initials, required this.disabled});

  final String initials;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: disabled ? null : AppColors.brandGradient,
        color: disabled
            ? AppColors.surfaceElevated.withValues(alpha: 0.78)
            : null,
        border: Border.all(
          color: disabled
              ? AppColors.primaryPurple.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: disabled ? AppColors.textSecondary : AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TeamEditButton extends StatelessWidget {
  const _TeamEditButton({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Edit team member',
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
      ),
      onSelected: (value) =>
          _showTeamPlaceholder(context, '$value: ${member.name}'),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Change assigned role',
          child: Text('Change assigned role'),
        ),
        const PopupMenuItem(
          value: 'Disable account',
          child: Text('Disable account'),
        ),
        const PopupMenuItem(
          value: 'Remove account',
          child: Text('Remove account'),
        ),
        if (member.status == 'Invited')
          const PopupMenuItem(
            value: 'Resend invite',
            child: Text('Resend invite'),
          ),
      ],
      child: _TeamIconButton(
        icon: Icons.edit_outlined,
        tooltip: 'Edit team member',
        onPressed: null,
      ),
    );
  }
}

class _TeamIconButton extends StatelessWidget {
  const _TeamIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF5C7A) : AppColors.primaryPink;
    final button = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: 18),
    );

    if (onPressed == null) return Tooltip(message: tooltip, child: button);
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onPressed, child: button),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _TeamPill(
      icon: Icons.badge_outlined,
      label: label,
      color: AppColors.primaryPink,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Active' => const Color(0xFF44D7A8),
      'Invited' => AppColors.trailGold,
      'Disabled' => const Color(0xFFFF5C7A),
      _ => AppColors.textSecondary,
    };
    return _TeamPill(icon: Icons.circle, label: label, color: color);
  }
}

class _LastActivePill extends StatelessWidget {
  const _LastActivePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _TeamPill(
      icon: Icons.access_time_rounded,
      label: label,
      color: AppColors.primaryPurple,
    );
  }
}

class _TeamPill extends StatelessWidget {
  const _TeamPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCustomRoleButton extends StatelessWidget {
  const _CreateCustomRoleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Create Custom Role'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPink,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    );
  }
}

class _RoleList extends StatelessWidget {
  const _RoleList({
    required this.roles,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_TeamRole> roles;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Default roles',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < roles.length; i++) ...[
          _RoleCard(
            role: roles[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
          if (i < roles.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Examples: Bar Manager, Events Manager, Marketing Manager',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final _TeamRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: selected
                ? AppColors.primaryPurple.withValues(alpha: 0.18)
                : AppColors.surfaceElevated.withValues(alpha: 0.58),
            border: Border.all(
              color: selected
                  ? AppColors.primaryPink.withValues(alpha: 0.55)
                  : AppColors.primaryPurple.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      role.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _TeamPill(
                    icon: Icons.groups_outlined,
                    label: '${role.memberCount}',
                    color: selected
                        ? AppColors.primaryPink
                        : AppColors.primaryPurple,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                role.description,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.88),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePermissionsEditor extends StatelessWidget {
  const _RolePermissionsEditor({required this.role});

  final _TeamRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: AppColors.background.withValues(alpha: 0.34),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${role.name} permissions',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Staff assigned to this role inherit these permissions automatically.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.86),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _TeamPill(
                icon: Icons.sync_alt_rounded,
                label: 'Inherited',
                color: AppColors.primaryPink,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _permissionGroups.length; i++) ...[
            _PermissionGroupCard(
              group: _permissionGroups[i],
              initiallyExpanded: i < 3,
              roleName: role.name,
            ),
            if (i < _permissionGroups.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PermissionGroupCard extends StatefulWidget {
  const _PermissionGroupCard({
    required this.group,
    required this.initiallyExpanded,
    required this.roleName,
  });

  final _PermissionGroup group;
  final bool initiallyExpanded;
  final String roleName;

  @override
  State<_PermissionGroupCard> createState() => _PermissionGroupCardState();
}

class _PermissionGroupCardState extends State<_PermissionGroupCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _PermissionGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleName != widget.roleName) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.52),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.group.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.group.permissions.length} permissions',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  for (final permission in widget.group.permissions)
                    _PermissionToggle(label: permission),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatefulWidget {
  const _PermissionToggle({required this.label});

  final String label;

  @override
  State<_PermissionToggle> createState() => _PermissionToggleState();
}

class _PermissionToggleState extends State<_PermissionToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _enabled,
      onChanged: (value) => setState(() => _enabled = value ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primaryPink,
      checkColor: AppColors.white,
      contentPadding: EdgeInsets.zero,
      title: Text(
        widget.label,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.94),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void _showTeamPlaceholder(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label is a UI preview until RBAC persistence is added.'),
    ),
  );
}

class _SubscriptionPageContent extends StatelessWidget {
  const _SubscriptionPageContent();

  @override
  Widget build(BuildContext context) {
    final snapshot = GrowthCommercialViewSupport.fromDashboard(
      VenueDashboardController.maybeOf(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 920;
        final cards = [
          for (final plan in snapshot.planCards)
            _SubscriptionPlanCard(
              plan: _SubscriptionPlan(
                name: plan.name,
                description: plan.description,
                price: plan.price,
                priceSuffix: plan.priceSuffix,
                ctaLabel: plan.ctaLabel,
                state: _mapPlanState(plan.state),
                badgeLabel: plan.badgeLabel,
                features: [
                  for (final feature in plan.features)
                    _PlanFeature(feature.label, included: feature.included),
                ],
              ),
            ),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.renewalPrompt != null) ...[
              VenuePageSection(
                title: 'Renewal',
                child: VenuePageSummaryTile(
                  label: 'Subscription renewal',
                  value: snapshot.renewalPrompt!,
                  icon: Icons.event_repeat_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (snapshot.subscriptionRecommendations.isNotEmpty) ...[
              VenuePageSection(
                title: 'Recommendations',
                child: Column(
                  children: [
                    for (final recommendation
                        in snapshot.subscriptionRecommendations.take(2)) ...[
                      VenuePageSummaryTile(
                        label: recommendation.title,
                        value: recommendation.message,
                        icon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              SubscriptionPlans.launchDiscountLabel,
              style: TextStyle(
                color: AppColors.primaryPink.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (stack)
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: AppSpacing.lg),
              ]
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: AppSpacing.lg),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  _SubscriptionPlanState _mapPlanState(GrowthSubscriptionPlanCardState state) {
    return switch (state) {
      GrowthSubscriptionPlanCardState.current =>
        _SubscriptionPlanState.current,
      GrowthSubscriptionPlanCardState.recommended =>
        _SubscriptionPlanState.recommended,
      GrowthSubscriptionPlanCardState.premium => _SubscriptionPlanState.premium,
      GrowthSubscriptionPlanCardState.standard =>
        _SubscriptionPlanState.recommended,
    };
  }
}

enum _SubscriptionPlanState { current, recommended, premium }

class _SubscriptionPlan {
  const _SubscriptionPlan({
    required this.name,
    required this.description,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.ctaLabel,
    required this.state,
    this.badgeLabel,
  });

  final String name;
  final String description;
  final String price;
  final String priceSuffix;
  final List<_PlanFeature> features;
  final String ctaLabel;
  final _SubscriptionPlanState state;
  final String? badgeLabel;
}

class _PlanFeature {
  const _PlanFeature(this.label, {this.included = true});

  final String label;
  final bool included;
}

class _SubscriptionPlanCard extends StatefulWidget {
  const _SubscriptionPlanCard({required this.plan});

  final _SubscriptionPlan plan;

  @override
  State<_SubscriptionPlanCard> createState() => _SubscriptionPlanCardState();
}

class _SubscriptionPlanCardState extends State<_SubscriptionPlanCard> {
  bool _hovered = false;

  bool get _highlighted =>
      widget.plan.state == _SubscriptionPlanState.recommended ||
      widget.plan.state == _SubscriptionPlanState.premium;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isPremium = plan.state == _SubscriptionPlanState.premium;
    final isCurrent = plan.state == _SubscriptionPlanState.current;
    final accent = isPremium ? AppColors.trailGold : AppColors.primaryPink;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: _highlighted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isPremium ? 0.20 : 0.18),
                      AppColors.primaryPurple.withValues(alpha: 0.14),
                      AppColors.surfaceElevated.withValues(alpha: 0.76),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.72),
                      AppColors.surface.withValues(alpha: 0.72),
                    ],
                  ),
            border: Border.all(
              color: _highlighted
                  ? accent.withValues(alpha: _hovered ? 0.58 : 0.38)
                  : AppColors.primaryPurple.withValues(alpha: 0.18),
              width: _highlighted ? 1.4 : 1,
            ),
            boxShadow: _hovered || _highlighted
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: _hovered ? 0.22 : 0.12),
                      blurRadius: _hovered ? 30 : 22,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          plan.description,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.badgeLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _PlanBadge(label: plan.badgeLabel!, color: accent),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      plan.priceSuffix,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final feature in plan.features) ...[
                    _PlanFeatureRow(feature: feature),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PlanCtaButton(
                label: plan.ctaLabel,
                current: isCurrent,
                premium: isPremium,
                onPressed: isCurrent
                    ? null
                    : () => showVenuePagePlaceholderAction(
                        context,
                        plan.ctaLabel,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PlanFeatureRow extends StatelessWidget {
  const _PlanFeatureRow({required this.feature});

  final _PlanFeature feature;

  @override
  Widget build(BuildContext context) {
    final included = feature.included;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          size: 18,
          color: included
              ? AppColors.primaryPink
              : AppColors.textSecondary.withValues(alpha: 0.45),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            feature.label,
            style: TextStyle(
              color: included
                  ? AppColors.white.withValues(alpha: 0.92)
                  : AppColors.textSecondary.withValues(alpha: 0.48),
              fontWeight: included ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCtaButton extends StatelessWidget {
  const _PlanCtaButton({
    required this.label,
    required this.current,
    required this.premium,
    required this.onPressed,
  });

  final String label;
  final bool current;
  final bool premium;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (current) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: AppColors.textSecondary,
          side: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: premium ? AppColors.trailGold : AppColors.primaryPink,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}

class _MarketingPageContent extends StatelessWidget {
  const _MarketingPageContent();

  @override
  Widget build(BuildContext context) {
    final snapshot = GrowthCommercialViewSupport.fromDashboard(
      VenueDashboardController.maybeOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageMetricRow(
          metrics: [
            for (final metric in snapshot.marketingMetrics)
              VenuePageMetricCard(
                label: metric.label,
                value: metric.value,
                icon: metric.icon,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 760;
            final campaigns = VenuePageSection(
              title: 'Campaign Overview',
              child: Column(
                children: [
                  for (var i = 0; i < snapshot.campaignTiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    VenuePageSummaryTile(
                      label: snapshot.campaignTiles[i].label,
                      value: snapshot.campaignTiles[i].value,
                      icon: snapshot.campaignTiles[i].icon,
                    ),
                  ],
                ],
              ),
            );
            final tools = VenuePageSection(
              title: 'Promotional Tools',
              child: Column(
                children: [
                  for (var i = 0; i < snapshot.promotionalTools.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    VenuePageSummaryTile(
                      label: snapshot.promotionalTools[i].label,
                      value: snapshot.promotionalTools[i].value,
                      icon: snapshot.promotionalTools[i].icon,
                    ),
                  ],
                ],
              ),
            );
            if (stack) {
              return Column(
                children: [
                  campaigns,
                  const SizedBox(height: AppSpacing.lg),
                  tools,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: campaigns),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: tools),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Marketing Performance',
          child: Column(
            children: [
              const VenuePageChartPlaceholder(
                title: 'Campaign impressions & clicks',
              ),
              const SizedBox(height: AppSpacing.md),
              VenuePageSummaryTile(
                label: snapshot.performanceHeadline,
                value: snapshot.performanceInsight,
                icon: Icons.insights_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'Revenue forecast',
                value: snapshot.forecastRevenueLabel,
                icon: Icons.payments_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPageContent extends StatelessWidget {
  const _SettingsPageContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 760;
            final account = VenuePageSection(
              title: 'Account Settings',
              child: Column(
                children: const [
                  VenuePageSummaryTile(
                    label: 'Login email',
                    value: 'alex@copperlantern.co.uk',
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  VenuePageSummaryTile(
                    label: 'Security',
                    value: 'Password last changed 2 weeks ago',
                    icon: Icons.lock_outline_rounded,
                  ),
                ],
              ),
            );
            final venue = VenuePageSection(
              title: 'Venue Settings',
              child: Column(
                children: const [
                  VenuePageSummaryTile(
                    label: 'Default venue',
                    value: 'The Copper Lantern',
                    icon: Icons.storefront_outlined,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  VenuePageSummaryTile(
                    label: 'Notification preferences',
                    value: 'Reviews, deals and weekly analytics enabled',
                    icon: Icons.notifications_outlined,
                  ),
                ],
              ),
            );
            if (stack) {
              return Column(
                children: [
                  account,
                  const SizedBox(height: AppSpacing.lg),
                  venue,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: account),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: venue),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Integrations',
          child: Column(
            children: const [
              VenuePageSummaryTile(
                label: 'Connected accounts',
                value: 'Google Business Profile connected',
                icon: Icons.link_outlined,
              ),
              SizedBox(height: AppSpacing.sm),
              VenuePageSummaryTile(
                label: 'API integrations',
                value: 'Future-ready · connect POS and booking tools',
                icon: Icons.api_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
