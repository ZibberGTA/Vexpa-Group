import 'growth_action.dart';
import 'growth_priority.dart';

/// Ordered recommendation presented to a venue owner.
final class GrowthRecommendation {
  const GrowthRecommendation({
    required this.id,
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    this.buttonLabel = '',
    this.targetKey = '',
  });

  final String id;
  final String title;
  final String message;
  final GrowthAction action;
  final GrowthPriority priority;
  final String buttonLabel;
  final String targetKey;
}
