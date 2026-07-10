import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../bookings/screens/create_booking_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../home/models/artist_application_model.dart';
import '../../home/services/artist_application_service.dart';
import '../../home/services/event_service.dart';
import '../../monetisation/screens/venue_subscription_required_screen.dart';
import '../../monetisation/services/subscription_service.dart';

class ArtistApplicationDetailsScreen extends StatefulWidget {
  final ArtistApplicationModel application;

  const ArtistApplicationDetailsScreen({
    super.key,
    required this.application,
  });

  @override
  State<ArtistApplicationDetailsScreen> createState() =>
      _ArtistApplicationDetailsScreenState();
}

class _ArtistApplicationDetailsScreenState
    extends State<ArtistApplicationDetailsScreen> {
  bool isLoading = false;

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> acceptApplication() async {
    setState(() => isLoading = true);

    try {
      await ArtistApplicationService.acceptApplication(widget.application);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application accepted')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> rejectApplication() async {
    setState(() => isLoading = true);

    try {
      await ArtistApplicationService.rejectApplication(widget.application);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application rejected')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> acceptAndCreateEvent() async {
    setState(() => isLoading = true);

    try {
      await ArtistApplicationService.acceptApplication(widget.application);
      await EventService.addEvent(
        venueId: widget.application.venueId,
        title: '${widget.application.artistName} Live',
        description: widget.application.bio.isNotEmpty
            ? widget.application.bio
            : widget.application.message,
        startDateTime: widget.application.availableDate,
        endDateTime: widget.application.availableDate.add(const Duration(hours: 4)),
        category: widget.application.performanceType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepted and event created')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> createBooking() async {
    final enabled = await SubscriptionService.isVenueBookingFeatureEnabled(
      widget.application.venueId,
    );

    if (!mounted) return;

    if (!enabled) {
      final activated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VenueSubscriptionRequiredScreen(
            venueId: widget.application.venueId,
            venueName: widget.application.venueName,
          ),
        ),
      );

      if (activated != true) return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingScreen(application: widget.application),
      ),
    );
  }

  Future<void> messageArtist() async {
    if (widget.application.status.toLowerCase() != 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messaging opens after this application is accepted.'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final chatId = await ChatService.createOrGetChatForApplication(
        widget.application,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            title: widget.application.artistName,
            receiverId: widget.application.artistId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget infoRow(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final status = application.status.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(application.artistName),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFEDE9FE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                application.status.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B0764),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  infoRow('Artist', application.artistName),
                  infoRow('Email', application.artistEmail),
                  infoRow('Venue', application.venueName),
                  infoRow('Type', application.performanceType),
                  infoRow('Genre', application.genre),
                  infoRow('Available date', formatDate(application.availableDate)),
                  infoRow('Price', application.priceExpectation),
                  infoRow('Social link', application.socialLink),
                  infoRow('Admin fee paid', application.adminFeePaid ? 'Yes' : 'No'),
                  infoRow('Bio', application.bio),
                  infoRow('Message', application.message),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (status == 'pending') ...[
            ElevatedButton.icon(
              onPressed: isLoading ? null : acceptAndCreateEvent,
              icon: const Icon(Icons.event_available),
              label: const Text('Accept + Create Event'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isLoading ? null : acceptApplication,
              icon: const Icon(Icons.check),
              label: const Text('Accept Only'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isLoading ? null : rejectApplication,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Create Booking'),
              onPressed: isLoading ? null : createBooking,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(
                status == 'accepted'
                    ? 'Message Artist'
                    : 'Message Artist After Acceptance',
              ),
              onPressed: isLoading ? null : messageArtist,
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
