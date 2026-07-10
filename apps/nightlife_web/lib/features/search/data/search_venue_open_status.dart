/// Opening-hours helpers for search venue cards.
class SearchVenueOpenStatus {
  const SearchVenueOpenStatus({
    required this.isOpen,
    this.hasHours = false,
  });

  final bool isOpen;
  final bool hasHours;

  static const _dayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Returns whether a venue is open now based on Firestore [openingHours].
  ///
  /// When hours are missing, [isOpen] defaults to true so venues without
  /// schedule data still appear discoverable outside the Open Now filter.
  static SearchVenueOpenStatus fromOpeningHours(Map<String, dynamic> hours) {
    if (hours.isEmpty) {
      return const SearchVenueOpenStatus(isOpen: true, hasHours: false);
    }

    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final nowMinutes = now.hour * 60 + now.minute;

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

    final today = dayData(todayIndex);
    final yesterday = dayData((todayIndex + 6) % 7);

    if (!isClosed(yesterday)) {
      final yOpen = parseMinutes(yesterday?['open']);
      final yClose = parseMinutes(yesterday?['close']);
      if (yOpen != null &&
          yClose != null &&
          yClose <= yOpen &&
          nowMinutes < yClose) {
        return const SearchVenueOpenStatus(isOpen: true, hasHours: true);
      }
    }

    if (!isClosed(today)) {
      final open = parseMinutes(today?['open']);
      final close = parseMinutes(today?['close']);
      if (open != null && close != null) {
        final openNow = close <= open
            ? nowMinutes >= open || nowMinutes < close
            : nowMinutes >= open && nowMinutes < close;
        return SearchVenueOpenStatus(isOpen: openNow, hasHours: true);
      }
    }

    return const SearchVenueOpenStatus(isOpen: false, hasHours: true);
  }
}
