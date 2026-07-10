import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../monetisation/screens/artist_subscription_required_screen.dart';
import '../../monetisation/services/subscription_service.dart';
import '../services/artist_service.dart';

class ArtistApplyScreen extends StatefulWidget {
  const ArtistApplyScreen({super.key});

  @override
  State<ArtistApplyScreen> createState() => _ArtistApplyScreenState();
}

class _ArtistApplyScreenState extends State<ArtistApplyScreen> {
  final messageController = TextEditingController();
  final preferredDateController = TextEditingController();
  final proposedFeeController = TextEditingController();

  String? selectedVenueId;
  String? selectedVenueName;
  String performanceType = 'Live Music';
  bool submitting = false;

  final performanceTypes = [
    'Live Music',
    'DJ Set',
    'Acoustic Set',
    'Band Performance',
    'Comedy Night',
    'Special Performance',
    'Other',
  ];

  Future<void> _submitApplication() async {
    final hasSubscription =
        await SubscriptionService.isArtistSubscriptionActive();

    if (!hasSubscription) {
      if (!mounted) return;

      final activated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const ArtistSubscriptionRequiredScreen(),
        ),
      );

      if (activated != true) return;
    }

    if (selectedVenueId == null || selectedVenueName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a venue')),
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    await ArtistService.applyToVenue(
      venueId: selectedVenueId!,
      venueName: selectedVenueName!,
      message: messageController.text,
      preferredDate: preferredDateController.text,
      performanceType: performanceType,
      proposedFee: proposedFeeController.text,
    );

    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application submitted')),
    );

    Navigator.pop(context);
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    preferredDateController.dispose();
    proposedFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venuesQuery =
        FirebaseFirestore.instance.collection('venues').orderBy('name');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply To Perform'),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: venuesQuery.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final venues = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                value: selectedVenueId,
                decoration: _decoration('Select Venue'),
                items: venues.map((doc) {
                  final data = doc.data();
                  final venueName = data['name'] ?? 'Unnamed Venue';

                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(venueName),
                  );
                }).toList(),
                onChanged: (venueId) {
                  final venue = venues.firstWhere((doc) => doc.id == venueId);
                  final data = venue.data();

                  setState(() {
                    selectedVenueId = venue.id;
                    selectedVenueName = data['name'] ?? 'Unnamed Venue';
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: performanceType,
            decoration: _decoration('Performance Type'),
            items: performanceTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  performanceType = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: preferredDateController,
            decoration: _decoration('Preferred Date / Availability'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: proposedFeeController,
            keyboardType: TextInputType.number,
            decoration: _decoration('Proposed Fee'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            maxLines: 5,
            decoration: _decoration('Message to Venue'),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Artists need an active £4.99/month subscription to apply.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(submitting ? 'Submitting...' : 'Submit Application'),
            onPressed: submitting ? null : _submitApplication,
          ),
        ],
      ),
    );
  }
}