import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_icon_button.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../home/models/event_model.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/event_service.dart';
import '../../home/services/venue_service.dart';
import '../../venues/screens/add_event_screen.dart';
import 'owner_event_calendar_screen.dart';

class OwnerEventCalendarOverviewScreen extends StatefulWidget {
  const OwnerEventCalendarOverviewScreen({super.key});

  @override
  State<OwnerEventCalendarOverviewScreen> createState() =>
      _OwnerEventCalendarOverviewScreenState();
}

class _OwnerEventCalendarOverviewScreenState
    extends State<OwnerEventCalendarOverviewScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const PremiumScaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Event Calendar'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<VenueModel>>(
        stream: VenueService.getVenuesForOwner(user.uid),
        builder: (context, venuesSnapshot) {
          if (venuesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (venuesSnapshot.hasError) {
            return Center(
              child: Text('Error loading venues: ${venuesSnapshot.error}'),
            );
          }

          final venues = venuesSnapshot.data ?? [];

          if (venues.isEmpty) {
            return const Center(
              child: Text('No venues available for events yet.'),
            );
          }

          return StreamBuilder<List<_VenueEventBundle>>(
            stream: _watchAllVenueEvents(venues),
            builder: (context, eventsSnapshot) {
              if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (eventsSnapshot.hasError) {
                return Center(
                  child: Text('Error loading events: ${eventsSnapshot.error}'),
                );
              }

              final bundles = eventsSnapshot.data ?? const <_VenueEventBundle>[];
              final events = bundles
                  .expand(
                    (bundle) => bundle.events.map(
                      (event) => _VenueEventItem(
                        venue: bundle.venue,
                        event: event,
                      ),
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.event.startDateTime.compareTo(
                    b.event.startDateTime,
                  ),
                );

              return _CalendarBody(
                venues: venues,
                events: events,
                visibleMonth: _visibleMonth,
                selectedDay: _selectedDay,
                onPreviousMonth: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                  _selectedDay = null;
                }),
                onNextMonth: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  );
                  _selectedDay = null;
                }),
                onSelectDay: (day) => setState(() => _selectedDay = day),
                onAddEvent: () => _openAddEventFlow(context, venues),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<_VenueEventBundle>> _watchAllVenueEvents(
    List<VenueModel> venues,
  ) async* {
    Future<List<_VenueEventBundle>> load() async {
      final bundles = await Future.wait(
        venues.map((venue) async {
          final events = await EventService.getOwnerEventsForVenue(venue.id).first;
          return _VenueEventBundle(venue: venue, events: events);
        }),
      );
      return bundles;
    }

    yield await load();

    // Keeps the all-venue calendar refreshed without changing the existing
    // per-venue event streams or services.
    yield* Stream.periodic(const Duration(seconds: 30)).asyncMap((_) => load());
  }

  Future<void> _openAddEventFlow(
    BuildContext context,
    List<VenueModel> venues,
  ) async {
    if (venues.length == 1) {
      final venue = venues.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEventScreen(
            venueId: venue.id,
            venueName: venue.name,
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: venues.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Choose venue for new event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                );
              }

              final venue = venues[index - 1];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppColors.primaryPurple.withOpacity(0.25),
                  ),
                ),
                leading: const Icon(Icons.storefront_rounded),
                title: Text(
                  venue.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  venue.category.isEmpty ? 'Venue listing' : venue.category,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEventScreen(
                        venueId: venue.id,
                        venueName: venue.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.venues,
    required this.events,
    required this.visibleMonth,
    required this.selectedDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.onAddEvent,
  });

  final List<VenueModel> venues;
  final List<_VenueEventItem> events;
  final DateTime visibleMonth;
  final int? selectedDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(visibleMonth.month)} ${visibleMonth.year}';

    final monthEvents = events
        .where(
          (item) =>
              item.event.startDateTime.year == visibleMonth.year &&
              item.event.startDateTime.month == visibleMonth.month,
        )
        .toList();

    final byDay = <int, List<_VenueEventItem>>{};
    for (final item in monthEvents) {
      byDay.putIfAbsent(item.event.startDateTime.day, () => []).add(item);
    }

    final selectedEvents =
        selectedDay == null ? <_VenueEventItem>[] : byDay[selectedDay] ?? [];

    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(visibleMonth.year, visibleMonth.month, 1).weekday;
    final cells = daysInMonth + firstWeekday - 1;

    final venueColors = _buildVenueColors(venues);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _CalendarHeroCard(
          venueCount: venues.length,
          eventCount: monthEvents.length,
          onAddEvent: onAddEvent,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _premiumCardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onPreviousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  final day = index - firstWeekday + 2;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dayEvents = byDay[day] ?? const <_VenueEventItem>[];
                  final selected = selectedDay == day;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelectDay(day),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryPurple.withOpacity(0.22)
                            : Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryPurple.withOpacity(0.72)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          if (dayEvents.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            _VenueEventDots(
                              items: dayEvents,
                              venueColors: venueColors,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          selectedDay == null
              ? 'Select a day'
              : 'Events on $selectedDay ${_monthName(visibleMonth.month)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (selectedDay != null && selectedEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _premiumCardDecoration(),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_busy_rounded),
              title: Text('No events on this day'),
            ),
          )
        else
          ...selectedEvents.map(
            (item) => _EventListTile(
              item: item,
              color: venueColors[item.venue.id] ?? AppColors.primaryPurple,
            ),
          ),
        const SizedBox(height: 18),
        _VenueCalendarLegend(
          venues: venues,
          venueColors: venueColors,
        ),
      ],
    );
  }

  static Map<String, Color> _buildVenueColors(List<VenueModel> venues) {
    final palette = <Color>[
      AppColors.primaryPink,
      AppColors.primaryPurple,
      Colors.cyanAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.pinkAccent,
      Colors.lightBlueAccent,
    ];

    return {
      for (var i = 0; i < venues.length; i++) venues[i].id: palette[i % palette.length],
    };
  }

  static String _monthName(int month) {
    const names = [
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
    return names[month - 1];
  }
}

class _CalendarHeroCard extends StatelessWidget {
  const _CalendarHeroCard({
    required this.venueCount,
    required this.eventCount,
    required this.onAddEvent,
  });

  final int venueCount;
  final int eventCount;
  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(
        gradient: true,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All venue events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$eventCount events this month • $venueCount venue${venueCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onAddEvent,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
          ),
        ],
      ),
    );
  }
}

class _VenueEventDots extends StatelessWidget {
  const _VenueEventDots({
    required this.items,
    required this.venueColors,
  });

  final List<_VenueEventItem> items;
  final Map<String, Color> venueColors;

  @override
  Widget build(BuildContext context) {
    final venueIds = items.map((item) => item.venue.id).toSet().take(4).toList();

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      alignment: WrapAlignment.center,
      children: [
        for (final venueId in venueIds)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: venueColors[venueId] ?? AppColors.primaryPurple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (venueColors[venueId] ?? AppColors.primaryPurple)
                      .withOpacity(0.55),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({
    required this.item,
    required this.color,
  });

  final _VenueEventItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final event = item.event;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _premiumCardDecoration(),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.55)),
          ),
          child: Icon(Icons.event_available_rounded, color: color),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${item.venue.name} • ${event.category}\n'
          '${TimeOfDay.fromDateTime(event.startDateTime).format(context)} - '
          '${TimeOfDay.fromDateTime(event.endDateTime).format(context)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OwnerEventCalendarScreen(venue: item.venue),
            ),
          );
        },
      ),
    );
  }
}

class _VenueCalendarLegend extends StatelessWidget {
  const _VenueCalendarLegend({
    required this.venues,
    required this.venueColors,
  });

  final List<VenueModel> venues;
  final Map<String, Color> venueColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _premiumCardDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final venue in venues)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: venueColors[venue.id] ?? AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  venue.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VenueEventBundle {
  const _VenueEventBundle({
    required this.venue,
    required this.events,
  });

  final VenueModel venue;
  final List<EventModel> events;
}

class _VenueEventItem {
  const _VenueEventItem({
    required this.venue,
    required this.event,
  });

  final VenueModel venue;
  final EventModel event;
}

BoxDecoration _premiumCardDecoration({bool gradient = false}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: gradient ? null : const Color(0xFF1E2030).withOpacity(0.62),
    gradient: gradient
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purpleDark.withOpacity(0.92),
              AppColors.purple.withOpacity(0.74),
              const Color(0xFF1E2030).withOpacity(0.72),
            ],
          )
        : null,
    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.28)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.24),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
