import 'package:flutter/material.dart';

import '../services/subscription_service.dart';

class OwnerUpgradeScreen extends StatefulWidget {
  const OwnerUpgradeScreen({super.key});

  @override
  State<OwnerUpgradeScreen> createState() => _OwnerUpgradeScreenState();
}

class _OwnerUpgradeScreenState extends State<OwnerUpgradeScreen> {
  bool loading = false;

  Future<void> _startCheckout() async {
    setState(() => loading = true);
    try {
      await SubscriptionService.startVenueProCheckout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start checkout: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _activateForTesting() async {
    setState(() => loading = true);
    await SubscriptionService.markOwnerVenueProActiveForTesting();
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Owner Pro activated for testing.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final features = const [
      'Advanced owner analytics and revenue estimates',
      'Venue boost and featured map placement',
      'Priority placement in Best Right Now',
      'Deal and event engagement insights',
      'Artist booking tools and business notifications',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Pro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.workspace_premium, size: 72),
          const SizedBox(height: 18),
          const Text(
            'Grow your venue with Owner Pro',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unlock the tools owners need to understand demand, increase visibility, and convert users into customers.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Included', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payment),
            label: Text(loading ? 'Starting checkout...' : 'Subscribe with Stripe'),
            onPressed: loading ? null : _startCheckout,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: const Text('Activate Owner Pro for testing'),
            onPressed: loading ? null : _activateForTesting,
          ),
        ],
      ),
    );
  }
}
