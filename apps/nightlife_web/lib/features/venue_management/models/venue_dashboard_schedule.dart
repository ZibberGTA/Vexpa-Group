/// Source type for a dashboard schedule entry.
enum VenueDashboardScheduleActivityType {
  event,
  deal,
}

/// A single schedule entry for a dashboard day card.
class VenueDashboardScheduleItem {
  const VenueDashboardScheduleItem({
    required this.id,
    required this.activityType,
    required this.title,
    this.timeLabel,
    required this.sortAt,
  });

  final String id;
  final VenueDashboardScheduleActivityType activityType;
  final String title;
  final String? timeLabel;
  final DateTime sortAt;
}

/// One calendar day in the rolling seven-day dashboard schedule.
class VenueDashboardScheduleDay {
  const VenueDashboardScheduleDay({
    required this.date,
    required this.dayName,
    required this.dateLabel,
    required this.items,
    this.isToday = false,
  });

  final DateTime date;
  final String dayName;
  final String dateLabel;
  final List<VenueDashboardScheduleItem> items;
  final bool isToday;

  bool get hasActivity => items.isNotEmpty;
}

/// Rolling seven-day venue schedule for the dashboard home tab.
class VenueDashboardSchedule {
  const VenueDashboardSchedule({required this.days});

  final List<VenueDashboardScheduleDay> days;

  static const emptyDayMessage = 'No activity scheduled';
}
