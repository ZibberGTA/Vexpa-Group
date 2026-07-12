import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../home/models/deal_model.dart';
import '../../search/services/search_index_service.dart';
import '../data/mobile_deal_write_payload.dart';

class EditDealScreen extends StatefulWidget {
  const EditDealScreen({
    super.key,
    required this.deal,
  });

  final DealModel deal;

  @override
  State<EditDealScreen> createState() => _EditDealScreenState();
}

class _EditDealScreenState extends State<EditDealScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.deal.title);
    descriptionController = TextEditingController(text: widget.deal.description);
    startTimeController = TextEditingController(text: widget.deal.startTime);
    endTimeController = TextEditingController(text: widget.deal.endTime);
    startDate = widget.deal.startDateTime ?? DateTime.now();
    endDate = widget.deal.endDateTime ?? startDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  Future<void> _syncVenueHasDeals() async {
    final remainingDeals = await FirebaseFirestore.instance
        .collection('deals')
        .where('venueId', isEqualTo: widget.deal.venueId)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    await FirebaseFirestore.instance
        .collection('venues')
        .doc(widget.deal.venueId)
        .update({
      'hasDeals': remainingDeals.docs.isNotEmpty,
    });
  }

  Future<void> _updateDeal() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final startTime = startTimeController.text.trim();
    final endTime = endTimeController.text.trim();

    final validationError = ExperienceOwnerWriteService.validateMobileDealUpdate(
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
      final startDateTime =
          ExperienceOwnerWriteService.combineDateAndTime(startDate!, startTime)!;
      final endDateTime =
          ExperienceOwnerWriteService.combineDateAndTime(endDate!, endTime)!;

      await FirebaseFirestore.instance
          .collection('deals')
          .doc(widget.deal.id)
          .update(
            MobileDealWritePayload.buildUpdate(
              title: title,
              description: description,
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              startTime: startTime,
              endTime: endTime,
            ),
          );

      // ✅ Update search index
      await SearchIndexService.updateVenueSearchTerms(widget.deal.venueId);

      if (!mounted) return;
      _showMessage('Deal updated successfully.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to update deal: $e');
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

  Future<void> _deleteDeal() async {
    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('deals')
          .doc(widget.deal.id)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUser?.uid,
        'deletedByEmail': currentUser?.email,
      });

      await _syncVenueHasDeals();

      // ✅ Update search index
      await SearchIndexService.updateVenueSearchTerms(widget.deal.venueId);

      if (!mounted) return;
      _showMessage('Deal moved to recovery.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to delete deal: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Deal'),
          content: const Text('Are you sure you want to delete this deal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDeal();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Edit Deal'),
        actions: const [HomeIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Deal Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updateDeal,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : _confirmDelete,
                child: const Text('Delete Deal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}