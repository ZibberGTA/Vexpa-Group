
import 'package:flutter/material.dart';
import '../../../core/widgets/premium_scaffold.dart';

class EventTicketingScreen extends StatelessWidget {
  const EventTicketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumScaffold(
      appBar: null,
      body: Center(child: Text('Event Ticketing - Phase 2', style: TextStyle(fontSize: 24))),
    );
  }
}
