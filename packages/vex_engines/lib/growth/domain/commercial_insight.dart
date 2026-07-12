import 'growth_action.dart';
import 'growth_priority.dart';

/// Single commercial insight derived from performance or profile state.
final class CommercialInsight {
  const CommercialInsight({
    required this.title,
    required this.message,
    required this.action,
    this.priority = GrowthPriority.medium,
  });

  final String title;
  final String message;
  final GrowthAction action;
  final GrowthPriority priority;
}
