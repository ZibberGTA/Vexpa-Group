import 'growth_priority.dart';

/// Identified growth blocker or warning.
final class GrowthIssue {
  const GrowthIssue({
    required this.code,
    required this.message,
    this.priority = GrowthPriority.medium,
  });

  final String code;
  final String message;
  final GrowthPriority priority;
}
