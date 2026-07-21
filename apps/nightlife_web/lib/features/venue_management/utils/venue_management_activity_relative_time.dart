/// Relative timestamps for venue management activity feed rows.
abstract final class VenueManagementActivityRelativeTime {
  static const _weekdayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String format(DateTime timestamp, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      return _weekdayLabels[timestamp.weekday - 1];
    }

    return '${timestamp.day} '
        '${_monthLabels[timestamp.month - 1]} '
        '${timestamp.year}';
  }
}
