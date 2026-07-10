
import 'package:flutter/material.dart';
import '../../../core/widgets/premium_scaffold.dart';

class TableBookingsScreen extends StatelessWidget {
  const TableBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumScaffold(
      appBar: null,
      body: Center(child: Text('Table Bookings - Phase 2', style: TextStyle(fontSize: 24))),
    );
  }
}
