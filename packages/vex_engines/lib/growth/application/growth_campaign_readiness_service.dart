import '../domain/campaign_readiness.dart';
import '../domain/growth_issue.dart';
import '../domain/growth_priority.dart';

/// Campaign readiness validation from adapter-supplied venue state.
final class GrowthCampaignReadinessService {
  const GrowthCampaignReadinessService();

  CampaignReadiness assess({
    required bool hasUpcomingDealOrEvent,
    required bool hasGalleryPhotos,
    required bool hasActiveBoost,
    required bool hasDraftCampaign,
    required bool notificationsEnabled,
  }) {
    final issues = <GrowthIssue>[];
    final missing = <String>[];

    if (!hasGalleryPhotos) {
      missing.add('gallery-photos');
      issues.add(
        const GrowthIssue(
          code: 'missing-gallery',
          message: 'Add venue photos before launching a campaign.',
          priority: GrowthPriority.high,
        ),
      );
    }

    if (!hasUpcomingDealOrEvent) {
      missing.add('promotion-content');
      issues.add(
        const GrowthIssue(
          code: 'missing-promotion-content',
          message: 'Create a deal or event to promote.',
          priority: GrowthPriority.high,
        ),
      );
    }

    if (!notificationsEnabled) {
      missing.add('notifications');
      issues.add(
        const GrowthIssue(
          code: 'notifications-disabled',
          message: 'Enable business notifications before sending campaigns.',
          priority: GrowthPriority.medium,
        ),
      );
    }

    if (hasDraftCampaign && !hasUpcomingDealOrEvent) {
      issues.add(
        const GrowthIssue(
          code: 'draft-without-content',
          message: 'Campaign draft needs live deal or event content.',
          priority: GrowthPriority.medium,
        ),
      );
    }

    final ready = issues
        .where((issue) => issue.priority != GrowthPriority.low)
        .isEmpty;

    return CampaignReadiness(
      ready: ready,
      issues: issues,
      missingRequirements: missing,
    );
  }

  String readinessLabel(CampaignReadiness readiness) {
    if (readiness.ready) return 'Ready to launch';
    if (readiness.missingRequirements.isEmpty) return 'Needs review';
    return 'Missing ${readiness.missingRequirements.length} requirement(s)';
  }
}
