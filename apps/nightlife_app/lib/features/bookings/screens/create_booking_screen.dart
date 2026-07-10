import 'package:flutter/material.dart';
import '../../../core/widgets/home_icon_button.dart';

import '../../home/models/artist_application_model.dart';
import '../services/booking_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final ArtistApplicationModel application;

  const CreateBookingScreen({
    super.key,
    required this.application,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final agreedFeeController = TextEditingController();
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  bool saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> _createBooking() async {
    setState(() {
      saving = true;
    });

    await BookingService.createBookingFromApplication(
      application: widget.application,
      bookingDate: selectedDate,
      agreedFee: agreedFeeController.text,
      notes: notesController.text,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking created')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    agreedFeeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Booking'),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(app.artistName),
              subtitle: Text(app.venueName),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Booking Date'),
            subtitle: Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: agreedFeeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Agreed Fee',
              border: OutlineInputBorder(),
              prefixText: '£',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Booking Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(saving ? 'Creating...' : 'Confirm Booking'),
            onPressed: saving ? null : _createBooking,
          ),
        ],
      ),
    );
  }
}