/// Resolved opening status for customer-facing venue hero surfaces.
final class VenueOpeningStatus {
  const VenueOpeningStatus({
    required this.label,
    required this.hasHours,
    required this.isOpen,
  });

  final String label;
  final bool hasHours;
  final bool isOpen;
}

/// Customer-facing opening status labels — mirrors mobile hero/map logic.
final class VenueOpeningStatusPresentation {
  VenueOpeningStatusPresentation._();

  static const _dayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static VenueOpeningStatus resolve(
    Map<String, dynamic> hours, {
    DateTime? now,
  }) {
    if (hours.isEmpty) {
      return const VenueOpeningStatus(
        label: '',
        hasHours: false,
        isOpen: false,
      );
    }

    final clock = now ?? DateTime.now();
    final todayIndex = clock.weekday - 1;
    final nowMinutes = clock.hour * 60 + clock.minute;

    Map<String, dynamic>? dayData(int index) {
      final value = hours[_dayKeys[index % 7]];
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    int? parseMinutes(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      final parts = text.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return hour * 60 + minute;
    }

    bool isClosed(Map<String, dynamic>? data) =>
        data == null || data['closed'] == true || data['isClosed'] == true;

    String formatMinutes(int minutes) {
      final normalized = minutes % (24 * 60);
      final hour24 = normalized ~/ 60;
      final minute = normalized % 60;
      final suffix = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
    }

    final today = dayData(todayIndex);
    final yesterday = dayData((todayIndex + 6) % 7);

    if (!isClosed(yesterday)) {
      final yOpen = parseMinutes(yesterday?['open']);
      final yClose = parseMinutes(yesterday?['close']);
      if (yOpen != null &&
          yClose != null &&
          yClose <= yOpen &&
          nowMinutes < yClose) {
        return VenueOpeningStatus(
          label: 'Open • Closes ${formatMinutes(yClose)}',
          hasHours: true,
          isOpen: true,
        );
      }
    }

    if (!isClosed(today)) {
      final open = parseMinutes(today?['open']);
      final close = parseMinutes(today?['close']);
      if (open != null && close != null) {
        final openNow = close <= open
            ? nowMinutes >= open || nowMinutes < close
            : nowMinutes >= open && nowMinutes < close;
        if (openNow) {
          return VenueOpeningStatus(
            label: 'Open • Closes ${formatMinutes(close)}',
            hasHours: true,
            isOpen: true,
          );
        }
        if (nowMinutes < open) {
          return VenueOpeningStatus(
            label: 'Closed • Opens ${formatMinutes(open)}',
            hasHours: true,
            isOpen: false,
          );
        }
      }
    }

    for (var offset = 1; offset <= 7; offset++) {
      final index = (todayIndex + offset) % 7;
      final data = dayData(index);
      if (isClosed(data)) continue;
      final open = parseMinutes(data?['open']);
      if (open == null) continue;
      final dayLabel = offset == 1
          ? 'tomorrow'
          : _dayKeys[index][0].toUpperCase() + _dayKeys[index].substring(1);
      return VenueOpeningStatus(
        label: 'Closed • Opens $dayLabel ${formatMinutes(open)}',
        hasHours: true,
        isOpen: false,
      );
    }

    return const VenueOpeningStatus(
      label: 'Closed',
      hasHours: true,
      isOpen: false,
    );
  }
}
