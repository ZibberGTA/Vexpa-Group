import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../home/models/event_model.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/event_service.dart';
import '../../venues/screens/add_event_screen.dart';

class OwnerEventCalendarScreen extends StatefulWidget {
  const OwnerEventCalendarScreen({super.key, required this.venue});

  final VenueModel venue;

  @override
  State<OwnerEventCalendarScreen> createState() => _OwnerEventCalendarScreenState();
}

class _OwnerEventCalendarScreenState extends State<OwnerEventCalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Events - ${widget.venue.name}'),
        actions: const [HomeIconButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEventScreen(
              venueId: widget.venue.id,
              venueName: widget.venue.name,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService.getOwnerEventsForVenue(widget.venue.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          final monthEvents = events
              .where((event) => event.startDateTime.year == _visibleMonth.year && event.startDateTime.month == _visibleMonth.month)
              .toList();
          final byDay = <int, List<EventModel>>{};
          for (final event in monthEvents) {
            byDay.putIfAbsent(event.startDateTime.day, () => []).add(event);
          }

          final selectedEvents = _selectedDay == null ? <EventModel>[] : byDay[_selectedDay] ?? <EventModel>[];
          final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
          final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
          final cells = daysInMonth + firstWeekday - 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                      _selectedDay = null;
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(monthLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                      _selectedDay = null;
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) => Expanded(child: Center(child: Text(day, style: TextStyle(fontWeight: FontWeight.bold)))))
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
                itemBuilder: (context, index) {
                  final day = index - firstWeekday + 2;
                  if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                  final eventCount = byDay[day]?.length ?? 0;
                  final selected = _selectedDay == day;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedDay = day),
                    child: Card(
                      elevation: selected ? 2 : 0,
                      color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (eventCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            Text('$eventCount', style: const TextStyle(fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                _selectedDay == null ? 'Select a day' : 'Bookings on $_selectedDay ${_monthName(_visibleMonth.month)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_selectedDay != null && selectedEvents.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.event_busy),
                    title: Text('No bookings/events on this day'),
                  ),
                )
              else
                ...selectedEvents.map((event) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${event.category} • ${TimeOfDay.fromDateTime(event.startDateTime).format(context) + ' - ' + TimeOfDay.fromDateTime(event.endDateTime).format(context)}\n${event.description}'),
                        isThreeLine: true,
                      ),
                    )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}
