import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

import '../../home/models/event_model.dart';
import '../../home/services/event_service.dart';

class AddEventScreen extends StatefulWidget {
  final String venueId;
  final String venueName;

  const AddEventScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();

  DateTime? selectedStartDateTime;
  DateTime? selectedEndDateTime;
  bool isSaving = false;

  String selectedCategory = 'General';

  final categories = [
    'General',
    'DJ Night',
    'Live Music',
    'Happy Hour',
    'Sports',
    'Quiz Night',
    'Karaoke',
    'Student Night',
    'Special Event',
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({required DateTime initialDateTime}) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initialDateTime,
    );

    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> pickStartDateTime() async {
    final picked = await _pickDateTime(
      initialDateTime: selectedStartDateTime ?? DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedStartDateTime = picked;
      if (selectedEndDateTime == null || !selectedEndDateTime!.isAfter(picked)) {
        selectedEndDateTime = ExperienceOwnerWriteService.defaultMobileEventEnd(
          start: picked,
        );
      }
    });
  }

  Future<void> pickEndDateTime() async {
    final initial = selectedEndDateTime ??
        ExperienceOwnerWriteService.defaultMobileEventEnd(
          start: selectedStartDateTime ?? DateTime.now(),
        );
    final picked = await _pickDateTime(initialDateTime: initial);

    if (picked == null) return;

    setState(() {
      selectedEndDateTime = picked;
    });
  }

  Future<void> saveEvent() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    final validationError = ExperienceOwnerWriteService.validateMobileEventCreate(
      title: title,
      description: description,
      startDateTime: selectedStartDateTime,
      endDateTime: selectedEndDateTime,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await EventService.addEvent(
        venueId: widget.venueId,
        title: title,
        description: description,
        startDateTime: selectedStartDateTime!,
        endDateTime: selectedEndDateTime!,
        category: selectedCategory,
        imageUrl: imageUrl,
      );

      titleController.clear();
      descriptionController.clear();
      imageUrlController.clear();

      setState(() {
        selectedStartDateTime = null;
        selectedEndDateTime = null;
        selectedCategory = 'General';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await EventService.deleteEvent(eventId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted')),
    );
  }

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final selectedStartLabel = selectedStartDateTime == null
        ? 'Choose start date and time'
        : 'Starts ${formatDateTime(selectedStartDateTime!)}';
    final selectedEndLabel = selectedEndDateTime == null
        ? 'Choose end date and time'
        : 'Ends ${formatDateTime(selectedEndDateTime!)}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Events - ${widget.venueName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Event',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Event description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedCategory = value);
              },
              decoration: const InputDecoration(
                labelText: 'Event category',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL / poster URL optional',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickStartDateTime,
                icon: const Icon(Icons.event_available_rounded),
                label: Text(selectedStartLabel),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickEndDateTime,
                icon: const Icon(Icons.event_busy_rounded),
                label: Text(selectedEndLabel),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveEvent,
                icon: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Save Event'),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Existing Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<List<EventModel>>(
              stream: EventService.getOwnerEventsForVenue(widget.venueId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No upcoming events added yet.'),
                  );
                }

                return Column(
                  children: events.map((event) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.imageUrl.isNotEmpty)
                            Image.network(
                              event.imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const SizedBox.shrink();
                              },
                            ),

                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.event),
                            ),
                            title: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${event.category}\n${formatDateTime(event.startDateTime)} - ${formatDateTime(event.endDateTime)}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteEvent(event.id),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(event.description),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
