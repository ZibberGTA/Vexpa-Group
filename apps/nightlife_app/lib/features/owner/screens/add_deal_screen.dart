import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

import '../../home/models/venue_model.dart';
import '../../search/services/search_index_service.dart';
import '../../notifications/services/smart_notification_service.dart';
import '../data/mobile_deal_write_payload.dart';

class AddDealScreen extends StatefulWidget {
  const AddDealScreen({
    super.key,
    required this.venue,
  });

  final VenueModel venue;

  @override
  State<AddDealScreen> createState() => _AddDealScreenState();
}

class _AddDealScreenState extends State<AddDealScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveDeal() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final startTime = startTimeController.text.trim();
    final endTime = endTimeController.text.trim();

    final validationError = ExperienceOwnerWriteService.validateMobileDealCreate(
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      startDate: startDate,
      endDate: endDate,
    );
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final dealRef = firestore.collection('deals').doc();
      final venueRef = firestore.collection('venues').doc(widget.venue.id);

      final batch = firestore.batch();

      final startDateTime =
          ExperienceOwnerWriteService.combineDateAndTime(startDate!, startTime)!;
      final endDateTime =
          ExperienceOwnerWriteService.combineDateAndTime(endDate!, endTime)!;

      batch.set(
        dealRef,
        MobileDealWritePayload.buildCreate(
          venueId: widget.venue.id,
          venueName: widget.venue.name,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          startTime: startTime,
          endTime: endTime,
        ),
      );

      batch.update(venueRef, {
        'hasDeals': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await SearchIndexService.updateVenueSearchTerms(widget.venue.id);
      await SmartNotificationService.notifyFavouriteUsersNewDeal(
        venueId: widget.venue.id,
        venueName: widget.venue.name,
        dealTitle: title,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );

      if (!mounted) return;
      _showMessage('Deal added successfully.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to save deal: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final current = start ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        startDate = picked;
        endDate ??= picked;
      } else {
        endDate = picked;
      }
    });
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Select date';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Deal - ${widget.venue.name}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Deal Title',
                  hintText: 'e.g. 2 for 1 Cocktails',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Available before 8pm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Start: ${_dateLabel(startDate)}'),
                      onPressed: () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_available),
                      label: Text('End: ${_dateLabel(endDate)}'),
                      onPressed: () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: 'e.g. 17:00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: 'e.g. 20:00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveDeal,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Deal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}