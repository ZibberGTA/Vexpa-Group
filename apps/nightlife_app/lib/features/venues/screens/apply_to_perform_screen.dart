import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/services/artist_application_service.dart';

class ApplyToPerformScreen extends StatefulWidget {
  final String venueId;
  final String venueName;

  const ApplyToPerformScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<ApplyToPerformScreen> createState() => _ApplyToPerformScreenState();
}

class _ApplyToPerformScreenState extends State<ApplyToPerformScreen> {
  final artistNameController = TextEditingController();
  final genreController = TextEditingController();
  final bioController = TextEditingController();
  final messageController = TextEditingController();
  final socialLinkController = TextEditingController();
  final priceExpectationController = TextEditingController();

  String selectedPerformanceType = 'Singer';
  DateTime? selectedDate;
  bool isSubmitting = false;

  final performanceTypes = [
    'Singer',
    'Band',
    'DJ',
    'Comedian',
    'Live Performer',
    'Acoustic Artist',
    'Tribute Act',
    'Other',
  ];

  @override
  void dispose() {
    artistNameController.dispose();
    genreController.dispose();
    bioController.dispose();
    messageController.dispose();
    socialLinkController.dispose();
    priceExpectationController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> submitApplication() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to apply')),
      );
      return;
    }

    final artistName = artistNameController.text.trim();
    final genre = genreController.text.trim();
    final bio = bioController.text.trim();
    final message = messageController.text.trim();

    if (artistName.isEmpty ||
        genre.isEmpty ||
        bio.isEmpty ||
        message.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ArtistApplicationService.submitApplication(
        artistId: user.uid,
        artistName: artistName,
        artistEmail: user.email ?? '',
        venueId: widget.venueId,
        venueName: widget.venueName,
        performanceType: selectedPerformanceType,
        genre: genre,
        bio: bio,
        message: message,
        socialLink: socialLinkController.text,
        priceExpectation: priceExpectationController.text,
        availableDate: selectedDate!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit application: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        selectedDate == null ? 'Choose available date' : formatDate(selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply to ${widget.venueName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFEDE9FE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Apply to perform at ${widget.venueName}. '
                'An admin fee/payment step can be added here later.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B0764),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: artistNameController,
            decoration: const InputDecoration(
              labelText: 'Artist / Band name *',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedPerformanceType,
            items: performanceTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedPerformanceType = value);
            },
            decoration: const InputDecoration(
              labelText: 'Performance type *',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: genreController,
            decoration: const InputDecoration(
              labelText: 'Genre *',
              hintText: 'Example: Acoustic, Rock, Pop, House',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Artist bio *',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message to venue *',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: socialLinkController,
            decoration: const InputDecoration(
              labelText: 'Social / music link optional',
              hintText: 'Instagram, YouTube, Spotify, website',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: priceExpectationController,
            decoration: const InputDecoration(
              labelText: 'Price expectation optional',
              hintText: 'Example: £150',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(dateLabel),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: isSubmitting ? null : submitApplication,
            icon: isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(isSubmitting ? 'Submitting...' : 'Submit Application'),
          ),
        ],
      ),
    );
  }
}