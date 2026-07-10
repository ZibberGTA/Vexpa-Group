
import 'package:flutter/material.dart';
import 'pub_crawls_screen.dart';
import 'table_bookings_screen.dart';
import 'event_ticketing_screen.dart';
import '../../../core/widgets/premium_scaffold.dart';

class NewFeaturesHubScreen extends StatelessWidget {
  const NewFeaturesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: const Text('New Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Pub Crawls'), onTap: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PubCrawlsScreen()))),
          ListTile(title: const Text('Table Bookings'), onTap: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TableBookingsScreen()))),
          ListTile(title: const Text('Event Ticketing'), onTap: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EventTicketingScreen()))),
        ],
      ),
    );
  }
}
