import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import '../services/analytics_service.dart';


int _estimatedVisits(AnalyticsSummary summary) {
  final intentSignals = summary.favouriteTaps + summary.dealViews + summary.eventViews;
  return ((summary.venueViews * 0.08) + (intentSignals * 0.35)).round();
}

int _estimatedRevenue(AnalyticsSummary summary) {
  // Conservative placeholder until real POS/redemption tracking is connected.
  return _estimatedVisits(summary) * 18;
}

String _roiSignal(AnalyticsSummary summary) {
  final intentSignals = summary.favouriteTaps + summary.dealViews + summary.eventViews;
  if (summary.venueViews == 0) return 'New';
  final rate = intentSignals / summary.venueViews;
  if (rate >= 0.35) return 'Strong';
  if (rate >= 0.15) return 'Good';
  return 'Build';
}

class VenueAnalyticsCard extends StatefulWidget {
  final String venueId;

  const VenueAnalyticsCard({
    super.key,
    required this.venueId,
  });

  @override
  State<VenueAnalyticsCard> createState() => _VenueAnalyticsCardState();
}

class _VenueAnalyticsCardState extends State<VenueAnalyticsCard> {
  AnalyticsRange _range = AnalyticsRange.sevenDays;


  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined),
                SizedBox(width: 8),
                Text(
                  'Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RangeSelector(
              selected: _range,
              onChanged: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 16),
            FutureBuilder<AnalyticsSummary>(
              future: AnalyticsService.getVenueSummary(
                venueId: widget.venueId,
                range: _range,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Analytics unavailable: ${snapshot.error}');
                }

                final summary = snapshot.data;
                if (summary == null) {
                  return const Text('No analytics yet.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricPill(
                          icon: Icons.visibility,
                          label: 'Views',
                          value: summary.venueViews.toString(),
                        ),
                        _MetricPill(
                          icon: Icons.favorite,
                          label: 'Favourites',
                          value: summary.favouriteTaps.toString(),
                        ),
                        _MetricPill(
                          icon: Icons.percent,
                          label: 'Conversion',
                          value: summary.formattedConversionRate,
                        ),
                        _MetricPill(
                          icon: Icons.groups,
                          label: 'Crowd updates',
                          value: summary.crowdUpdates.toString(),
                        ),
                        _MetricPill(
                          icon: Icons.local_bar,
                          label: 'Drink views',
                          value: summary.drinkViews.toString(),
                        ),
                        _MetricPill(
                          icon: Icons.local_offer,
                          label: 'Deal views',
                          value: summary.dealViews.toString(),
                        ),
                        _MetricPill(
                          icon: Icons.event,
                          label: 'Event views',
                          value: summary.eventViews.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _TopList(
                      title: 'Top drinks',
                      emptyText: 'No drink views yet.',
                      items: summary.topDrinks,
                    ),
                    const SizedBox(height: 16),
                    _TopList(
                      title: 'Top deals',
                      emptyText: 'No deal views yet.',
                      items: summary.topDeals,
                    ),
                    const SizedBox(height: 16),
                    _CrowdTrendList(items: summary.crowdTrends),
                    const SizedBox(height: 16),
                    _InsightBox(summary: summary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerAnalyticsSummaryCard extends StatefulWidget {
  final List<String> venueIds;

  const OwnerAnalyticsSummaryCard({
    super.key,
    required this.venueIds,
  });

  @override
  State<OwnerAnalyticsSummaryCard> createState() => _OwnerAnalyticsSummaryCardState();
}

class _OwnerAnalyticsSummaryCardState extends State<OwnerAnalyticsSummaryCard> {
  AnalyticsRange _range = AnalyticsRange.sevenDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RangeSelector(
          selected: _range,
          onChanged: (range) => setState(() => _range = range),
        ),
        const SizedBox(height: 14),
        FutureBuilder<AnalyticsSummary>(
          future: AnalyticsService.getOwnerSummary(
            venueIds: widget.venueIds,
            range: _range,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Analytics unavailable: ${snapshot.error}');
            }

            final summary = snapshot.data;
            if (summary == null) return const Text('No analytics yet.');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Views',
                        value: summary.venueViews.toString(),
                        icon: Icons.visibility,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Favourites',
                        value: summary.favouriteTaps.toString(),
                        icon: Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Conversion',
                        value: summary.formattedConversionRate,
                        icon: Icons.percent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Drinks',
                        value: summary.drinkViews.toString(),
                        icon: Icons.local_bar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Deals',
                        value: summary.dealViews.toString(),
                        icon: Icons.local_offer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Crowd',
                        value: summary.crowdUpdates.toString(),
                        icon: Icons.groups,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Est. visits',
                        value: _estimatedVisits(summary).toString(),
                        icon: Icons.directions_walk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Est. revenue',
                        value: '£${_estimatedRevenue(summary)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'ROI signal',
                        value: _roiSignal(summary),
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RevenueInsightBox(summary: summary),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onChanged;

  const _RangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnalyticsRange.values.map((range) {
        return ChoiceChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
          label: Text(range.label),
          selected: selected.label == range.label,
          onSelected: (_) => onChanged(range),
        );
      }).toList(),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<TopAnalyticsItem> items;

  const _TopList({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(emptyText)
        else
          ...items.map(
            (item) => _AnalyticsRow(
              label: item.name,
              value: item.count,
            ),
          ),
      ],
    );
  }
}

class _CrowdTrendList extends StatelessWidget {
  final List<CrowdTrendPoint> items;

  const _CrowdTrendList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crowd trends',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('No crowd trend data yet.')
        else
          ...items.map(
            (item) => _AnalyticsRow(
              label: item.label,
              value: item.count,
            ),
          ),
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  final AnalyticsSummary summary;

  const _InsightBox({required this.summary});

  @override
  Widget build(BuildContext context) {
    final message = summary.venueViews == 0
        ? 'Views will appear here once users start opening this venue.'
        : summary.favouriteConversionRate < 5
            ? 'People are viewing this venue, but favourites are low. Try improving photos, deals or event details.'
            : 'This venue is converting views into favourites well. Keep deals and crowd levels updated.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final int value;

  const _AnalyticsRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}


class _RevenueInsightBox extends StatelessWidget {
  const _RevenueInsightBox({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final visits = _estimatedVisits(summary);
    final revenue = _estimatedRevenue(summary);
    final message = visits == 0
        ? 'Start driving saves, deal views and event interest to build a revenue signal.'
        : 'Estimated from views, saves, deal taps and event interest. Connect redemptions or POS later for exact revenue.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Revenue signal: £$revenue projected from $visits likely visit${visits == 1 ? '' : 's'}. $message',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
