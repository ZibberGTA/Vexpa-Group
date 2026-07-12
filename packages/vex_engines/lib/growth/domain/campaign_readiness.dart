import 'growth_issue.dart';

/// Campaign readiness assessment for a venue.
final class CampaignReadiness {
  const CampaignReadiness({
    required this.ready,
    required this.issues,
    this.missingRequirements = const [],
  });

  final bool ready;
  final List<GrowthIssue> issues;
  final List<String> missingRequirements;
}
