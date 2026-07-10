import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../monetisation/services/boost_service.dart';
import '../services/stripe_checkout_service.dart';

class StripeCheckoutStatusScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> checkoutRef;
  final String venueId;
  final String venueName;
  final BoostPlan plan;

  const StripeCheckoutStatusScreen({
    super.key,
    required this.checkoutRef,
    required this.venueId,
    required this.venueName,
    required this.plan,
  });

  @override
  State<StripeCheckoutStatusScreen> createState() => _StripeCheckoutStatusScreenState();
}

class _StripeCheckoutStatusScreenState extends State<StripeCheckoutStatusScreen> {
  bool _activating = false;
  bool _activated = false;

  Future<void> _activatePaidBoost() async {
    if (_activating || _activated) return;
    setState(() => _activating = true);

    try {
      await BoostService.activateBoostAfterPayment(
        checkoutRef: widget.checkoutRef,
        venueId: widget.venueId,
        venueName: widget.venueName,
        plan: widget.plan,
      );
      if (!mounted) return;
      setState(() => _activated = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.plan.name} activated for ${widget.venueName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not activate boost: $e')),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stripe Checkout')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: StripeCheckoutService.checkoutSessionStream(widget.checkoutRef),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final status = StripeCheckoutService.checkoutStatusLabel(data);
          final checkoutUrl = StripeCheckoutService.checkoutUrl(data);
          final paid = StripeCheckoutService.isPaidCheckoutSession(data);

          if (paid && !_activated && !_activating) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _activatePaidBoost());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plan.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.venueName),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(paid ? Icons.check_circle : Icons.pending_actions),
                          const SizedBox(width: 10),
                          Expanded(child: Text(status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (data?['error'] != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(data!['error'].toString()),
                  ),
                ),
              if (checkoutUrl != null && !paid) ...[
                const Text(
                  'Open Stripe Checkout to complete payment.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await StripeCheckoutService.openCheckoutUrl(checkoutUrl);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open checkout: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open checkout'),
                ),
                const SizedBox(height: 10),
                SelectableText(checkoutUrl),
              ],
              if (paid && !_activated) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _activating ? null : _activatePaidBoost,
                  icon: _activating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.rocket_launch),
                  label: const Text('Activate paid boost'),
                ),
              ],
              if (_activated) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
