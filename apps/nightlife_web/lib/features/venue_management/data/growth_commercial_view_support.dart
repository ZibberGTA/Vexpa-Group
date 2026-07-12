import 'package:flutter/material.dart';
import 'package:vex_core/entitlements/entitlements.dart';
import 'package:vex_engines/growth/growth_engine.dart';

import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_stat.dart';
import '../models/venue_dashboard_whats_next_action.dart';
import '../models/venue_profile_completion.dart';
import '../widgets/venue_dashboard_controller.dart';
import 'growth_commercial_support.dart';

/// Adapter input for composing growth/commercial dashboard snapshots.
final class GrowthCommercialSnapshotInput {
  const GrowthCommercialSnapshotInput({
    required this.subscriptionPlanId,
    required this.activeVenueCount,
    this.homeData,
    this.daysUntilExpiry = -1,
    this.hasActiveBoost = false,
    this.activeBoostPlanName = '',
    this.activeBoostEndsAt,
    this.underutilizedPremiumFeatures = false,
  });

  final String subscriptionPlanId;
  final int activeVenueCount;
  final VenueDashboardHomeData? homeData;
  final int daysUntilExpiry;
  final bool hasActiveBoost;
  final String activeBoostPlanName;
  final DateTime? activeBoostEndsAt;
  final bool underutilizedPremiumFeatures;

  static GrowthCommercialSnapshotInput fromDashboard(
    VenueDashboardController? controller,
  ) {
    if (controller == null) {
      return const GrowthCommercialSnapshotInput(
        subscriptionPlanId: 'starter',
        activeVenueCount: 1,
      );
    }

    return GrowthCommercialSnapshotInput(
      subscriptionPlanId: controller.contextData.subscriptionPlanId,
      activeVenueCount: controller.contextData.availableVenueIds.isEmpty
          ? 1
          : controller.contextData.availableVenueIds.length,
      homeData: controller.homeData,
      daysUntilExpiry: controller.contextData.daysUntilSubscriptionRenewal,
    );
  }
}

/// View-ready growth/commercial data for venue owner dashboards.
final class GrowthCommercialSnapshot {
  const GrowthCommercialSnapshot({
    required this.commercialSummary,
    required this.campaignSummary,
    required this.subscriptionRecommendations,
    required this.planCards,
    required this.marketingMetrics,
    required this.recommendationCards,
    required this.campaignTiles,
    required this.promotionalTools,
    required this.performanceHeadline,
    required this.performanceInsight,
    required this.forecastRevenueLabel,
    required this.renewalPrompt,
    required this.goPremiumTitle,
    required this.goPremiumBody,
    required this.goalCards,
  });

  final GrowthCommercialSummary commercialSummary;
  final CampaignLifecycleSummary campaignSummary;
  final List<SubscriptionRecommendation> subscriptionRecommendations;
  final List<GrowthSubscriptionPlanCardView> planCards;
  final List<GrowthMarketingMetricView> marketingMetrics;
  final List<GrowthRecommendationCardView> recommendationCards;
  final List<GrowthSummaryTileView> campaignTiles;
  final List<GrowthSummaryTileView> promotionalTools;
  final String performanceHeadline;
  final String performanceInsight;
  final String forecastRevenueLabel;
  final String? renewalPrompt;
  final String goPremiumTitle;
  final String goPremiumBody;
  final List<GrowthGoalCardView> goalCards;
}

final class GrowthSubscriptionPlanCardView {
  const GrowthSubscriptionPlanCardView({
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
  final List<GrowthPlanFeatureView> features;
  final String ctaLabel;
  final GrowthSubscriptionPlanCardState state;
  final String? badgeLabel;
}

enum GrowthSubscriptionPlanCardState { current, recommended, premium, standard }

final class GrowthPlanFeatureView {
  const GrowthPlanFeatureView(this.label, {this.included = true});

  final String label;
  final bool included;
}

final class GrowthMarketingMetricView {
  const GrowthMarketingMetricView({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

final class GrowthRecommendationCardView {
  const GrowthRecommendationCardView({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

final class GrowthSummaryTileView {
  const GrowthSummaryTileView({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

final class GrowthGoalCardView {
  const GrowthGoalCardView({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;
}

/// Maps dashboard signals to Growth Engine summaries for production UI.
final class GrowthCommercialViewSupport {
  GrowthCommercialViewSupport._();

  static const _entitlements = EntitlementService();

  static GrowthCommercialSnapshot build(GrowthCommercialSnapshotInput input) {
    final signals = _VenueGrowthSignals.fromHomeData(input.homeData);
    final planId = _normalizePlanId(input.subscriptionPlanId);
    final hasMedia = _entitlements.hasMediaCentreAccess(planId);
    final hasAnalytics = _hasAdvancedAnalytics(planId);
    final hasCampaignTools = _hasCampaignTools(planId);

    final performanceInput = GrowthPerformanceInput(
      venueViews: signals.profileViews,
      favouriteTaps: signals.saves,
      dealViews: signals.dealViews,
      eventViews: signals.eventViews,
      conversionRatePercent: signals.conversionRatePercent,
    );
    final performance = GrowthCommercialSupport.interpretPerformance(
      performanceInput,
    );

    final summaryInput = GrowthSummaryInput(
      currentPlanId: planId,
      hasMediaCentreAccess: hasMedia,
      hasAdvancedAnalyticsAccess: hasAnalytics,
      hasCampaignToolsAccess: hasCampaignTools,
      hasGalleryPhotos: signals.hasGalleryPhotos,
      hasUpcomingDealOrEvent: signals.hasUpcomingDealOrEvent,
      hasActiveBoost: input.hasActiveBoost,
      activeBoostPlanName: input.activeBoostPlanName,
      activeBoostEndsAt: input.activeBoostEndsAt,
      performance: performance,
      dealCount: signals.dealCount,
      profileCompletionRemaining: signals.profileCompletionRemaining,
    );

    final adviceInput = GrowthAdviceInput(
      hasGalleryPhotos: signals.hasGalleryPhotos,
      dealCount: signals.dealCount,
      hasUpcomingEvent: signals.hasUpcomingEvent,
      profileCompletionRemaining: signals.profileCompletionRemaining,
      hasActiveBoost: input.hasActiveBoost,
      performance: performance,
    );

    final commercialSummary = GrowthCommercialSupport.buildCommercialSummary(
      summaryInput: summaryInput,
      performanceInput: performanceInput,
      adviceInput: adviceInput,
    );

    final campaignSummary = GrowthCommercialSupport.summarizeCampaign(
      hasUpcomingDealOrEvent: signals.hasUpcomingDealOrEvent,
      hasGalleryPhotos: signals.hasGalleryPhotos,
      hasActiveBoost: input.hasActiveBoost,
      hasDraftCampaign: campaignSummaryDraft(signals),
      hasScheduledCampaign: campaignSummaryScheduled(signals, performance),
      hasLiveCampaign: input.hasActiveBoost || performance.roiSignalLabel == 'Strong',
      campaignEnded: false,
      notificationsEnabled: true,
      notificationOpenRatePercent: signals.conversionRatePercent,
      impressions: signals.profileViews,
    );

    final growthScore = commercialSummary.score.value;
    final subscriptionRecommendations =
        GrowthCommercialSupport.subscriptionRecommendations(
      currentPlanId: planId,
      hasMediaCentreAccess: hasMedia,
      hasAdvancedAnalyticsAccess: hasAnalytics,
      hasCampaignToolsAccess: hasCampaignTools,
      underutilizedPremiumFeatures: input.underutilizedPremiumFeatures,
      activeVenueCount: input.activeVenueCount,
      daysUntilExpiry: input.daysUntilExpiry,
      growthScoreValue: growthScore,
      hasActiveSubscription: planId != 'free' && planId.isNotEmpty,
      hasPublishedContent: signals.hasPublishedContent,
    );

    final renewalPrompt = GrowthCommercialSupport.renewalPrompt(
      daysUntilRenewal: input.daysUntilExpiry,
    );

    final upgrade = commercialSummary.upgradeRecommendation;
    final marketing = commercialSummary.marketing;

    return GrowthCommercialSnapshot(
      commercialSummary: commercialSummary,
      campaignSummary: campaignSummary,
      subscriptionRecommendations: subscriptionRecommendations,
      planCards: _planCards(
        currentPlanId: planId,
        upgradeTargetId: upgrade?.recommendedPlanId,
      ),
      marketingMetrics: _marketingMetrics(
        campaignSummary: campaignSummary,
        marketing: marketing,
        performance: performance,
      ),
      recommendationCards: _recommendationCards(
        marketing: marketing,
        campaignSummary: campaignSummary,
        subscriptionRecommendations: subscriptionRecommendations,
      ),
      campaignTiles: _campaignTiles(campaignSummary, marketing),
      promotionalTools: _promotionalTools(
        marketing: marketing,
        campaignSummary: campaignSummary,
        hasActiveBoost: input.hasActiveBoost,
        boostSuggestion: GrowthCommercialSupport.suggestBoost(
          performance: performance,
          hasUpcomingEvent: signals.hasUpcomingEvent,
          hasWeekendDeal: signals.dealCount > 0,
        ),
      ),
      performanceHeadline: marketing.headline,
      performanceInsight: marketing.performance.insightMessage,
      forecastRevenueLabel:
          '£${_formatNumber(commercialSummary.forecastRevenueGbp)} forecast (3 mo)',
      renewalPrompt: renewalPrompt,
      goPremiumTitle: upgrade?.title ?? 'Grow with Vexda Premium',
      goPremiumBody: upgrade?.message ??
          marketing.performance.revenueInsightMessage,
      goalCards: _goalCards(
        signals: signals,
        commercialSummary: commercialSummary,
        performance: performance,
      ),
    );
  }

  static GrowthCommercialSnapshot fromDashboard(
    VenueDashboardController? controller,
  ) {
    return build(GrowthCommercialSnapshotInput.fromDashboard(controller));
  }

  static bool campaignSummaryDraft(_VenueGrowthSignals signals) {
    return signals.hasGalleryPhotos &&
        signals.hasUpcomingDealOrEvent &&
        signals.dealCount > 0;
  }

  static bool campaignSummaryScheduled(
    _VenueGrowthSignals signals,
    GrowthPerformance performance,
  ) {
    return signals.hasUpcomingDealOrEvent &&
        performance.roiSignalLabel != 'Weak';
  }

  static List<GrowthSubscriptionPlanCardView> _planCards({
    required String currentPlanId,
    required String? upgradeTargetId,
  }) {
    const displayPlanIds = ['starter', 'professional', 'premium'];
    final cards = <GrowthSubscriptionPlanCardView>[];

    for (final id in displayPlanIds) {
      final product = GrowthCommercialSupport.productSummary(id);
      if (product == null) continue;

      final isCurrent = id == currentPlanId;
      final isRecommended = id == upgradeTargetId;
      final state = isCurrent
          ? GrowthSubscriptionPlanCardState.current
          : isRecommended
          ? GrowthSubscriptionPlanCardState.recommended
          : id == 'premium'
          ? GrowthSubscriptionPlanCardState.premium
          : GrowthSubscriptionPlanCardState.standard;

      cards.add(
        GrowthSubscriptionPlanCardView(
          name: product.name,
          description: product.audience,
          price: '£${product.discountedMonthlyPriceGbp}',
          priceSuffix: '/ month',
          badgeLabel: isCurrent
              ? null
              : product.highlighted
              ? 'Most Popular'
              : id == 'premium'
              ? 'Maximum Growth'
              : null,
          ctaLabel: isCurrent
              ? 'Current Plan'
              : 'Upgrade to ${product.name}',
          state: state,
          features: product.features
              .map((feature) => GrowthPlanFeatureView(feature))
              .toList(growable: false),
        ),
      );
    }

    return cards;
  }

  static List<GrowthMarketingMetricView> _marketingMetrics({
    required CampaignLifecycleSummary campaignSummary,
    required GrowthMarketingSummary marketing,
    required GrowthPerformance performance,
  }) {
    final activeCampaigns = switch (campaignSummary.status) {
      CampaignCompletionStatus.live => '1 live',
      CampaignCompletionStatus.scheduled => '1 scheduled',
      CampaignCompletionStatus.draft => '1 draft',
      CampaignCompletionStatus.completed => '0 active',
      CampaignCompletionStatus.expired => '0 active',
      CampaignCompletionStatus.notStarted => '0 active',
    };

    return [
      GrowthMarketingMetricView(
        label: 'Active campaigns',
        value: activeCampaigns,
        icon: Icons.campaign_outlined,
      ),
      GrowthMarketingMetricView(
        label: 'Profile impressions',
        value: _formatNumber(marketing.performance.estimatedVisits * 10),
        icon: Icons.notifications_active_outlined,
      ),
      GrowthMarketingMetricView(
        label: 'Conversion rate',
        value: marketing.conversion.conversionRatePercent == 0
            ? marketing.conversion.label
            : '${marketing.conversion.conversionRatePercent.round()}%',
        icon: Icons.qr_code_2_outlined,
      ),
      GrowthMarketingMetricView(
        label: 'ROI signal',
        value: performance.roiSignalLabel,
        icon: Icons.trending_up_rounded,
      ),
    ];
  }

  static List<GrowthRecommendationCardView> _recommendationCards({
    required GrowthMarketingSummary marketing,
    required CampaignLifecycleSummary campaignSummary,
    required List<SubscriptionRecommendation> subscriptionRecommendations,
  }) {
    final cards = <GrowthRecommendationCardView>[];

    for (final recommendation in marketing.recommendations) {
      cards.add(
        GrowthRecommendationCardView(
          icon: _iconForAction(recommendation.action),
          title: recommendation.title,
          body: recommendation.message,
        ),
      );
    }

    for (final recommendation in campaignSummary.recommendations) {
      cards.add(
        GrowthRecommendationCardView(
          icon: _iconForAction(recommendation.action),
          title: recommendation.title,
          body: recommendation.message,
        ),
      );
    }

    for (final recommendation in subscriptionRecommendations.take(2)) {
      cards.add(
        GrowthRecommendationCardView(
          icon: Icons.workspace_premium_rounded,
          title: recommendation.title,
          body: recommendation.message,
        ),
      );
    }

    if (cards.isEmpty) {
      return const [
        GrowthRecommendationCardView(
          icon: Icons.auto_awesome_outlined,
          title: 'Build your marketing signal',
          body: 'Add photos, deals and events to unlock growth recommendations.',
        ),
      ];
    }

    return cards.take(5).toList(growable: false);
  }

  static List<GrowthSummaryTileView> _campaignTiles(
    CampaignLifecycleSummary summary,
    GrowthMarketingSummary marketing,
  ) {
    return [
      GrowthSummaryTileView(
        label: 'Campaign status',
        value: _campaignStatusLabel(summary.status),
        icon: Icons.campaign_outlined,
      ),
      GrowthSummaryTileView(
        label: 'Campaign readiness',
        value: summary.readinessLabel,
        icon: Icons.fact_check_outlined,
      ),
      GrowthSummaryTileView(
        label: 'Marketing headline',
        value: marketing.headline,
        icon: Icons.insights_outlined,
      ),
    ];
  }

  static List<GrowthSummaryTileView> _promotionalTools({
    required GrowthMarketingSummary marketing,
    required CampaignLifecycleSummary campaignSummary,
    required bool hasActiveBoost,
    required BoostSuggestion? boostSuggestion,
  }) {
    final boostLabel = marketing.activeBoostLabel.trim().isEmpty
        ? hasActiveBoost
            ? 'Active boost running'
            : boostSuggestion?.plan.name ?? 'No active boost'
        : marketing.activeBoostLabel;

    return [
      GrowthSummaryTileView(
        label: 'Boosted venue placement',
        value: boostLabel,
        icon: Icons.rocket_launch_outlined,
      ),
      GrowthSummaryTileView(
        label: 'Campaign health',
        value: '${campaignSummary.health.label} · ${campaignSummary.health.score}%',
        icon: Icons.health_and_safety_outlined,
      ),
      GrowthSummaryTileView(
        label: 'ROI insight',
        value: marketing.roi.insightMessage,
        icon: Icons.payments_outlined,
      ),
    ];
  }

  static List<GrowthGoalCardView> _goalCards({
    required _VenueGrowthSignals signals,
    required GrowthCommercialSummary commercialSummary,
    required GrowthPerformance performance,
  }) {
    final growthTarget = 75;
    final growthScore = commercialSummary.score.value;
    final viewsTarget = (signals.profileViews * 1.35).round().clamp(1, 999999);
    final savesTarget = (signals.saves * 1.25).round().clamp(1, 999999);

    return [
      GrowthGoalCardView(
        label: 'Growth score goal',
        value: '$growthScore / $growthTarget',
        progress: (growthScore / growthTarget).clamp(0.0, 1.0),
      ),
      GrowthGoalCardView(
        label: 'Profile views goal',
        value: '${_formatNumber(signals.profileViews)} / ${_formatNumber(viewsTarget)}',
        progress: signals.profileViews == 0
            ? 0
            : (signals.profileViews / viewsTarget).clamp(0.0, 1.0),
      ),
      GrowthGoalCardView(
        label: 'Venue saves goal',
        value: '${_formatNumber(signals.saves)} / ${_formatNumber(savesTarget)}',
        progress: signals.saves == 0
            ? 0
            : (signals.saves / savesTarget).clamp(0.0, 1.0),
      ),
      GrowthGoalCardView(
        label: 'Revenue forecast goal',
        value:
            '£${_formatNumber(performance.estimatedRevenueGbp)} / £${_formatNumber(commercialSummary.forecastRevenueGbp)}',
        progress: commercialSummary.forecastRevenueGbp == 0
            ? 0
            : (performance.estimatedRevenueGbp / commercialSummary.forecastRevenueGbp)
                .clamp(0.0, 1.0),
      ),
    ];
  }

  static String _normalizePlanId(String planId) {
    final normalized = planId.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'free') {
      return 'starter';
    }
    return normalized;
  }

  static bool _hasAdvancedAnalytics(String planId) {
    final tier = _entitlements.normalizeVenueTier(planId);
    return tier == SubscriptionTier.premium ||
        tier == SubscriptionTier.corporate;
  }

  static bool _hasCampaignTools(String planId) => _hasAdvancedAnalytics(planId);

  static IconData _iconForAction(GrowthAction action) {
    return switch (action) {
      GrowthAction.upgradeSubscription => Icons.workspace_premium_rounded,
      GrowthAction.purchaseBoost => Icons.rocket_launch_outlined,
      GrowthAction.createCampaign => Icons.campaign_outlined,
      GrowthAction.improveProfile => Icons.storefront_outlined,
      GrowthAction.addDeal => Icons.local_offer_outlined,
      GrowthAction.addEvent => Icons.event_outlined,
      GrowthAction.addGalleryPhotos => Icons.photo_library_outlined,
      GrowthAction.reviewAnalytics => Icons.insights_outlined,
    };
  }

  static String _campaignStatusLabel(CampaignCompletionStatus status) {
    return switch (status) {
      CampaignCompletionStatus.live => 'Live',
      CampaignCompletionStatus.scheduled => 'Scheduled',
      CampaignCompletionStatus.draft => 'Draft',
      CampaignCompletionStatus.completed => 'Completed',
      CampaignCompletionStatus.expired => 'Expired',
      CampaignCompletionStatus.notStarted => 'Not started',
    };
  }

  static String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

final class _VenueGrowthSignals {
  const _VenueGrowthSignals({
    required this.profileViews,
    required this.saves,
    required this.dealViews,
    required this.eventViews,
    required this.conversionRatePercent,
    required this.hasGalleryPhotos,
    required this.hasUpcomingEvent,
    required this.hasUpcomingDealOrEvent,
    required this.dealCount,
    required this.profileCompletionRemaining,
    required this.hasPublishedContent,
  });

  final int profileViews;
  final int saves;
  final int dealViews;
  final int eventViews;
  final double conversionRatePercent;
  final bool hasGalleryPhotos;
  final bool hasUpcomingEvent;
  final bool hasUpcomingDealOrEvent;
  final int dealCount;
  final int profileCompletionRemaining;
  final bool hasPublishedContent;

  static _VenueGrowthSignals fromHomeData(VenueDashboardHomeData? homeData) {
    if (homeData == null) {
      return const _VenueGrowthSignals(
        profileViews: 0,
        saves: 0,
        dealViews: 0,
        eventViews: 0,
        conversionRatePercent: 0,
        hasGalleryPhotos: false,
        hasUpcomingEvent: false,
        hasUpcomingDealOrEvent: false,
        dealCount: 0,
        profileCompletionRemaining: VenueProfileCompletion.totalChecklistSteps,
        hasPublishedContent: false,
      );
    }

    final stats = homeData.stats;
    final profileViews = _statValue(stats, 'Profile Views');
    final saves = _statValue(stats, 'Saves');
    final dealViews = _statValue(stats, 'Deal Views');
    final eventViews = _statValue(stats, 'Event Views');
    final conversionRatePercent = profileViews == 0
        ? 0.0
        : ((saves / profileViews) * 100).clamp(0.0, 100.0);

    final whatsNext = homeData.whatsNext;
    final needsGallery = _whatsNextTargets(whatsNext, 'Add more photos');
    final needsDeal = _whatsNextTargets(whatsNext, 'Create a new deal');
    final needsEvent = _whatsNextTargets(whatsNext, 'Add an upcoming event');

    final completion = homeData.profileCompletion;
    final profileCompletionRemaining =
        (completion.totalSteps - completion.completedSteps).clamp(0, 999);

    return _VenueGrowthSignals(
      profileViews: profileViews,
      saves: saves,
      dealViews: dealViews,
      eventViews: eventViews,
      conversionRatePercent: conversionRatePercent,
      hasGalleryPhotos: !needsGallery,
      hasUpcomingEvent: !needsEvent,
      hasUpcomingDealOrEvent: !needsEvent || !needsDeal,
      dealCount: needsDeal ? 0 : 1,
      profileCompletionRemaining: profileCompletionRemaining,
      hasPublishedContent:
          completion.completedSteps > 0 || profileViews > 0 || saves > 0,
    );
  }

  static int _statValue(List<VenueDashboardStat> stats, String label) {
    for (final stat in stats) {
      if (stat.label == label) return stat.value;
    }
    return 0;
  }

  static bool _whatsNextTargets(
    List<VenueDashboardWhatsNextAction> actions,
    String title,
  ) {
    return actions.any((action) => action.title == title);
  }
}
