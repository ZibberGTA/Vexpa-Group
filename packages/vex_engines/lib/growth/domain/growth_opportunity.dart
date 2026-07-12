import 'growth_action.dart';
import 'growth_priority.dart';

/// Identified commercial growth opportunity for a venue.
final class GrowthOpportunity {
  const GrowthOpportunity({
    required this.id,
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    this.score = 0,
  });

  final String id;
  final String title;
  final String message;
  final GrowthAction action;
  final GrowthPriority priority;
  final int score;
}
