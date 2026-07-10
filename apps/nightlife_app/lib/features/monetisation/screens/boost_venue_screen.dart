import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../payments/screens/stripe_checkout_status_screen.dart';
import '../../payments/services/stripe_checkout_service.dart';
import '../services/boost_service.dart';

class BoostVenueScreen extends StatelessWidget {
  final String venueId;
  final String venueName;

  const BoostVenueScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  Future<void> _startStripeCheckout(BuildContext context, BoostPlan plan) async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to boost a venue.')),
      );
      return;
    }

    try {
      final checkout = await StripeCheckoutService.createBoostCheckout(
        venueId: venueId,
        venueName: venueName,
        plan: plan,
      );

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StripeCheckoutStatusScreen(
            checkoutRef: checkout.reference,
            venueId: venueId,
            venueName: venueName,
            plan: plan,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe checkout could not start: $e')),
      );
    }
  }

  Future<void> _activateTestBoost(BuildContext context, BoostPlan plan) async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId == null) return;

    await BoostService.activateBoost(
      venueId: venueId,
      venueName: venueName,
      ownerId: ownerId,
      plan: plan,
      paymentStatus: 'manual_test',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test ${plan.name} activated for $venueName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boost Venue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Promote $venueName',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a paid boost plan. Stripe Checkout is created through Firebase, then the boost activates after Stripe marks the session as paid.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 20),
          StreamBuilder<Map<String, dynamic>?>(
            stream: BoostService.activeBoostStream(venueId),
            builder: (context, snapshot) {
              final active = snapshot.data;
              if (active == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.rocket_launch),
                  title: Text('Active boost: ${active['planName'] ?? 'Boost'}'),
                  subtitle: const Text('This venue is currently promoted.'),
                  trailing: TextButton(
                    onPressed: () => BoostService.cancelBoost(venueId),
                    child: const Text('Cancel'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ...BoostService.plans.map((plan) => _BoostPlanCard(
                plan: plan,
                onTap: () => _startStripeCheckout(context, plan),
                onTestTap: () => _activateTestBoost(context, plan),
              )),
        ],
      ),
    );
  }
}

class _BoostPlanCard extends StatelessWidget {
  final BoostPlan plan;
  final VoidCallback onTap;
  final VoidCallback onTestTap;

  const _BoostPlanCard({required this.plan, required this.onTap, required this.onTestTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(plan.priceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(plan.description),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: const Text('Pay with Stripe'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onTestTap,
                child: const Text('Activate test boost'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
