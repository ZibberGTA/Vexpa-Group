import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../payments/services/stripe_checkout_service.dart';
import '../services/subscription_service.dart';


class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class ArtistSubscriptionRequiredScreen extends StatefulWidget {
  const ArtistSubscriptionRequiredScreen({super.key});

  @override
  State<ArtistSubscriptionRequiredScreen> createState() =>
      _ArtistSubscriptionRequiredScreenState();
}

class _ArtistSubscriptionRequiredScreenState
    extends State<ArtistSubscriptionRequiredScreen> {
  bool loading = false;
  DocumentReference<Map<String, dynamic>>? checkoutRef;

  Future<void> _startStripeCheckout() async {
    setState(() => loading = true);

    try {
      final ref = await StripeCheckoutService.createSubscriptionCheckout(
        priceId: StripeCheckoutService.artistMonthlyPriceId,
        metadata: {
          'plan': 'artist_monthly_499',
          'feature': 'artist_applications',
        },
      );

      if (!mounted) return;
      setState(() {
        checkoutRef = ref;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe checkout failed: $e')),
      );
    }
  }

  Future<void> _activateForTesting() async {
    setState(() => loading = true);

    await SubscriptionService.markArtistSubscriptionActiveForTesting();

    if (!mounted) return;

    setState(() => loading = false);
    Navigator.pop(context, true);
  }

  Widget _checkoutStatus() {
    final ref = checkoutRef;
    if (ref == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: StripeCheckoutService.checkoutSessionStream(ref),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final url = data['url']?.toString() ?? '';
        final error = data['error'];

        if (error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Stripe error: $error'),
            ),
          );
        }

        if (url.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Waiting for Stripe Checkout URL...'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stripe Checkout URL created',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open checkout'),
                      onPressed: () async {
                        try {
                          await StripeCheckoutService.openCheckoutUrl(url);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open checkout: $e')),
                          );
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy checkout link'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checkout link copied')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Subscription'),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.workspace_premium, size: 70),
          const SizedBox(height: 20),
          const Text(
            'Artist Monthly Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            '£4.99 / month',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Artists need an active subscription to apply to perform at venues.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Included with Artist Pro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  _FeatureRow('Apply to perform at venues'),
                  _FeatureRow('Appear in venue artist searches'),
                  _FeatureRow('Receive booking requests'),
                  _FeatureRow('Monthly booking calendar'),
                  _FeatureRow('Gig notifications and venue messaging'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
            label: Text(loading ? 'Starting checkout...' : 'Subscribe with Stripe'),
            onPressed: loading ? null : _startStripeCheckout,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: const Text('Activate for testing'),
            onPressed: loading ? null : _activateForTesting,
          ),
          const SizedBox(height: 16),
          _checkoutStatus(),
        ],
      ),
    );
  }
}
