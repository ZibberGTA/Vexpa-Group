import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingDashboardScreen extends StatefulWidget {
  final bool ownerView;

  const BookingDashboardScreen({
    super.key,
    required this.ownerView,
  });

  @override
  State<BookingDashboardScreen> createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends State<BookingDashboardScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _statusFilter = 'accepted';
  DateTime? _selectedDate;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _monthTitle(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesStatus(BookingModel booking) {
    if (_statusFilter == 'all') return true;
    final status = booking.status.toLowerCase();
    if (_statusFilter == 'accepted') {
      return status == 'accepted' || status == 'confirmed';
    }
    return status == _statusFilter;
  }

  List<DateTime?> _calendarDays() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = first.weekday - 1;
    return [
      ...List<DateTime?>.filled(leadingBlanks, null),
      ...List.generate(daysInMonth, (index) => DateTime(_visibleMonth.year, _visibleMonth.month, index + 1)),
    ];
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.ownerView
        ? BookingService.myOwnerBookingsStream()
        : BookingService.myArtistBookingsStream();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ownerView ? 'Venue Bookings' : 'My Bookings'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];
          final bookings = allBookings.where(_matchesStatus).toList();

          if (allBookings.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          final selectedBookings = _selectedDate == null
              ? bookings
                  .where((booking) =>
                      booking.bookingDate.year == _visibleMonth.year &&
                      booking.bookingDate.month == _visibleMonth.month)
                  .toList()
              : bookings.where((booking) => _sameDay(booking.bookingDate, _selectedDate!)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _monthTitle(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final filter in const ['accepted', 'pending', 'completed', 'cancelled', 'all'])
                    ChoiceChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                      label: Text(filter == 'accepted' ? 'Accepted' : filter[0].toUpperCase() + filter.substring(1)),
                      selected: _statusFilter == filter,
                      onSelected: (_) {
                        setState(() {
                          _statusFilter = filter;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          _Weekday('M'),
                          _Weekday('T'),
                          _Weekday('W'),
                          _Weekday('T'),
                          _Weekday('F'),
                          _Weekday('S'),
                          _Weekday('S'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _calendarDays().length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (context, index) {
                          final day = _calendarDays()[index];
                          if (day == null) return const SizedBox.shrink();

                          final dayBookings = bookings.where((booking) => _sameDay(booking.bookingDate, day)).toList();
                          final selected = _selectedDate != null && _sameDay(_selectedDate!, day);
                          final today = _sameDay(DateTime.now(), day);

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedDate = day;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.14)
                                    : today
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                                        : null,
                                borderRadius: BorderRadius.circular(14),
                                border: selected
                                    ? Border.all(color: Theme.of(context).colorScheme.primary)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day.day.toString(),
                                    style: TextStyle(
                                      fontWeight: dayBookings.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (dayBookings.isNotEmpty)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: dayBookings.take(3).map((booking) {
                                        return Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                          decoration: BoxDecoration(
                                            color: _statusColor(booking.status),
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedDate == null
                    ? 'Bookings this month'
                    : 'Bookings on ${_formatDate(_selectedDate!)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (selectedBookings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No bookings match this view.'),
                  ),
                )
              else
                ...selectedBookings.map((booking) {
                  final color = _statusColor(booking.status);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.12),
                              child: Icon(Icons.event_available, color: color),
                            ),
                            title: Text(
                              widget.ownerView ? booking.artistName : booking.venueName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${_formatDate(booking.bookingDate)} • £${booking.agreedFee}\n'
                              'Status: ${booking.status.toUpperCase()}',
                            ),
                            isThreeLine: true,
                          ),
                          if (booking.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(booking.notes),
                          ],
                          if (widget.ownerView) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Completed'),
                                    onPressed: () => BookingService.updateBookingStatus(
                                      booking: booking,
                                      status: 'completed',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
                                    onPressed: () => BookingService.updateBookingStatus(
                                      booking: booking,
                                      status: 'cancelled',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;

  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
