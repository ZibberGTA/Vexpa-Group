import '../../venue/data/models/deal_model.dart';
import '../../venue/data/models/event_model.dart';
import '../../venue/data/venue_deals_repository.dart';
import '../../venue/data/venue_events_repository.dart';
import '../models/deal_status.dart';
import '../models/event_status.dart';
import '../models/venue_dashboard_schedule.dart';

/// Loads and composes the rolling seven-day dashboard schedule.
class VenueDashboardScheduleService {
  VenueDashboardScheduleService({
    VenueEventsRepository? eventsRepository,
    VenueDealsRepository? dealsRepository,
  }) : _eventsRepository = eventsRepository ?? VenueEventsRepository(),
       _dealsRepository = dealsRepository ?? VenueDealsRepository();

  final VenueEventsRepository _eventsRepository;
  final VenueDealsRepository _dealsRepository;

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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Loads published events and active deals for the next seven calendar days.
  Future<VenueDashboardSchedule> loadUpcomingSchedule({
    required String venueId,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final windowStart = _startOfDay(clock);
    final windowEndExclusive = windowStart.add(const Duration(days: 7));

    final results = await Future.wait([
      _eventsRepository.fetchScheduleEvents(
        venueId: venueId,
        windowStart: windowStart,
        windowEndExclusive: windowEndExclusive,
      ),
      _dealsRepository.fetchScheduleDeals(venueId: venueId),
    ]);

    return compose(
      events: results[0] as List<EventModel>,
      deals: results[1] as List<DealModel>,
      now: clock,
    );
  }

  /// Pure composition for tests and future schedule sources.
  VenueDashboardSchedule compose({
    required List<EventModel> events,
    required List<DealModel> deals,
    required DateTime now,
  }) {
    final windowStart = _startOfDay(now);
    final days = <VenueDashboardScheduleDay>[];

    for (var offset = 0; offset < 7; offset++) {
      final date = windowStart.add(Duration(days: offset));
      final items = <VenueDashboardScheduleItem>[];

      for (final event in events) {
        if (!_eventAppliesOnDay(event, date)) continue;
        items.add(_eventItem(event));
      }

      for (final deal in deals) {
        if (!_dealAppliesOnDay(deal, date, now: now)) continue;
        items.add(_dealItem(deal, date));
      }

      items.sort((a, b) {
        final compare = a.sortAt.compareTo(b.sortAt);
        if (compare != 0) return compare;
        return a.title.compareTo(b.title);
      });

      days.add(
        VenueDashboardScheduleDay(
          date: date,
          dayName: _weekdayLabels[date.weekday - 1],
          dateLabel: _formatDayDateLabel(date),
          items: items,
          isToday: _startOfDay(date) == _startOfDay(now),
        ),
      );
    }

    return VenueDashboardSchedule(days: days);
  }

  bool _eventAppliesOnDay(EventModel event, DateTime day) {
    if (event.isDeleted || !event.isActive) return false;

    final status = computeEventStatus(event, now: day);
    if (status == EventStatus.draft || status == EventStatus.ended) {
      return false;
    }

    final eventDay = _startOfDay(event.startDateTime);
    return eventDay == _startOfDay(day);
  }

  bool _dealAppliesOnDay(
    DealModel deal,
    DateTime day, {
    required DateTime now,
  }) {
    if (deal.isDeleted || !deal.isActive) return false;

    final status = computeDealStatus(deal, now: now);
    if (status == DealStatus.paused || status == DealStatus.expired) {
      return false;
    }

    final dayStart = _startOfDay(day);
    final dayEndExclusive = dayStart.add(const Duration(days: 1));

    if (deal.startDateTime != null &&
        !deal.startDateTime!.isBefore(dayEndExclusive)) {
      return false;
    }

    final effectiveEnd = deal.effectiveEndDateTime;
    if (effectiveEnd != null && !effectiveEnd.isAfter(dayStart)) {
      return false;
    }

    if (deal.availableDays.isNotEmpty) {
      final weekday = _weekdayLabels[day.weekday - 1];
      return deal.availableDays.any(
        (availableDay) =>
            availableDay.trim().toLowerCase() == weekday.toLowerCase(),
      );
    }

    return true;
  }

  VenueDashboardScheduleItem _eventItem(EventModel event) {
    final title = event.title.trim().isEmpty ? 'Event' : event.title.trim();
    final hasExplicitTime =
        event.startDateTime.hour != 0 || event.startDateTime.minute != 0;

    return VenueDashboardScheduleItem(
      id: event.id,
      activityType: VenueDashboardScheduleActivityType.event,
      title: title,
      timeLabel: hasExplicitTime
          ? '${_format24Hour(event.startDateTime)} – ${_format24Hour(event.endDateTime)}'
          : 'All Day',
      sortAt: event.startDateTime,
    );
  }

  VenueDashboardScheduleItem _dealItem(DealModel deal, DateTime day) {
    final title = deal.title.trim().isEmpty ? 'Deal' : deal.title.trim();
    final timeRange = _formatDealTimeRange24(deal.startTime, deal.endTime);

    return VenueDashboardScheduleItem(
      id: deal.id,
      activityType: VenueDashboardScheduleActivityType.deal,
      title: title,
      timeLabel: timeRange,
      sortAt: _dealSortAt(deal, day),
    );
  }

  DateTime _dealSortAt(DealModel deal, DateTime day) {
    final parsedStart = _parseTimeOnDay(deal.startTime, day);
    if (parsedStart != null) return parsedStart;

    if (deal.startDateTime != null &&
        _startOfDay(deal.startDateTime!) == _startOfDay(day)) {
      return deal.startDateTime!;
    }

    return _startOfDay(day);
  }

  String? _formatDealTimeRange24(String startTime, String endTime) {
    final start = _formatTimeString24(startTime);
    final end = _formatTimeString24(endTime);

    if (start != null && end != null) return '$start – $end';
    if (start != null) return start;
    if (end != null) return end;
    return null;
  }

  String? _formatTimeString24(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(':');
    if (parts.length < 2) return trimmed;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return trimmed;

    return _format24Hour(DateTime(2000, 1, 1, hour, minute));
  }

  DateTime? _parseTimeOnDay(String raw, DateTime day) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return null;

    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  String _format24Hour(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDayDateLabel(DateTime date) {
    return '${date.day} ${_monthLabels[date.month - 1]}';
  }

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
