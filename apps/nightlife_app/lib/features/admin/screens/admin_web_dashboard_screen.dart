import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../analytics/services/analytics_service.dart';
import '../../trending/services/trending_service.dart';
import '../services/admin_metrics_service.dart';

class AdminWebDashboardScreen extends StatefulWidget {
  const AdminWebDashboardScreen({super.key});

  @override
  State<AdminWebDashboardScreen> createState() => _AdminWebDashboardScreenState();
}

class _AdminWebDashboardScreenState extends State<AdminWebDashboardScreen> {
  AnalyticsRange _range = AnalyticsRange.sevenDays;
  late Future<AdminDashboardMetrics> _metricsFuture;
  late Future<List<TrendingVenue>> _trendingFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _metricsFuture = AdminMetricsService.getDashboardMetrics(range: _range);
    _trendingFuture = TrendingService.getTrendingVenues(range: _range, limit: 10);
  }

  void _setRange(AnalyticsRange range) {
    setState(() {
      _range = range;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Web Panel'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: AnalyticsRange.values.map((range) {
              return ChoiceChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                label: Text(range.label),
                selected: _range.label == range.label,
                onSelected: (_) => _setRange(range),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          FutureBuilder<AdminDashboardMetrics>(
            future: _metricsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorCard(error: snapshot.error.toString());
              }
              final metrics = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      final cards = [
                        _MetricCard(title: 'Venues', value: metrics.venues.toString(), icon: Icons.storefront),
                        _MetricCard(title: 'Users', value: metrics.users.toString(), icon: Icons.people),
                        _MetricCard(title: 'Owners', value: metrics.owners.toString(), icon: Icons.business_center),
                        _MetricCard(title: 'Active Boosts', value: metrics.activeBoosts.toString(), icon: Icons.rocket_launch),
                        _MetricCard(title: 'Paid Boosts', value: metrics.paidBoosts.toString(), icon: Icons.payment),
                        _MetricCard(title: 'Revenue', value: metrics.revenueLabel, icon: Icons.payments),
                      ];
                      return GridView.count(
                        crossAxisCount: wide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: wide ? 2.5 : 1.6,
                        children: cards,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _AnalyticsPanel(metrics: metrics),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<TrendingVenue>>(
            future: _trendingFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <TrendingVenue>[];
              return _TrendingAdminPanel(items: items);
            },
          ),
          const SizedBox(height: 20),
          const _RecentBoostsPanel(),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  final AdminDashboardMetrics metrics;

  const _AnalyticsPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final analytics = metrics.analytics;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Engagement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _Line(label: 'Venue views', value: analytics.venueViews.toString()),
            _Line(label: 'Favourite taps', value: analytics.favouriteTaps.toString()),
            _Line(label: 'Save conversion', value: analytics.formattedConversionRate),
            _Line(label: 'Drink views', value: analytics.drinkViews.toString()),
            _Line(label: 'Deal views', value: analytics.dealViews.toString()),
            _Line(label: 'Event views', value: analytics.eventViews.toString()),
            _Line(label: 'Crowd updates', value: analytics.crowdUpdates.toString()),
          ],
        ),
      ),
    );
  }
}

class _TrendingAdminPanel extends StatelessWidget {
  final List<TrendingVenue> items;

  const _TrendingAdminPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trending Scoreboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No trending data yet.')
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text(item.venue.name),
                  subtitle: Text(
                    'Views ${item.views} • Saves ${item.favourites} • Boost ${item.boostScore} • Conversion ${item.conversionRate.toStringAsFixed(1)}%',
                  ),
                  trailing: Text(item.score.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RecentBoostsPanel extends StatelessWidget {
  const _RecentBoostsPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Boosts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminMetricsService.recentBoostsStream(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No boosts yet.');
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      dense: true,
                      leading: Icon(data['active'] == true ? Icons.rocket_launch : Icons.pause_circle),
                      title: Text(data['venueName']?.toString() ?? 'Venue'),
                      subtitle: Text('${data['planName'] ?? 'Boost'} • ${data['paymentStatus'] ?? 'unknown'}'),
                      trailing: Text(data['priceLabel']?.toString() ?? ''),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error),
      ),
    );
  }
}
