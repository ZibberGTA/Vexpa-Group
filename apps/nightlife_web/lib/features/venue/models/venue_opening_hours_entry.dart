/// A single day row for the venue information panel opening hours section.
class VenueOpeningHoursEntry {
  const VenueOpeningHoursEntry({
    required this.dayLabel,
    required this.hoursLabel,
    this.isToday = false,
    this.isClosed = false,
  });

  final String dayLabel;
  final String hoursLabel;
  final bool isToday;
  final bool isClosed;
}
