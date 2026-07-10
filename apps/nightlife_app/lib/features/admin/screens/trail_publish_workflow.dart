import 'package:flutter/material.dart';

import '../../trails/models/trail_model.dart';

enum PublishChecklistResult { publish, cancel }

enum TrailPublishCheckId { name, banner, venues, availability, status }

class TrailPublishChecklistItem {
  const TrailPublishChecklistItem({
    required this.id,
    required this.label,
    required this.passed,
    this.failureMessage,
    this.targetTabIndex,
  });

  final TrailPublishCheckId id;
  final String label;
  final bool passed;
  final String? failureMessage;
  final int? targetTabIndex;
}

class TrailPublishWorkflow {
  TrailPublishWorkflow._();

  static List<TrailPublishChecklistItem> evaluate(DrinkSpotTrailModel trail) {
    final hasName = trail.name.trim().isNotEmpty;
    final hasBanner = trail.bannerImageUrl.trim().isNotEmpty;
    final hasVenues = _venueCount(trail) > 0;
    final validAvailability = trail.availabilityEnd.isAfter(
      trail.availabilityStart,
    );
    final validStatus =
        trail.status == TrailStatus.draft ||
        trail.status == TrailStatus.published;

    return [
      TrailPublishChecklistItem(
        id: TrailPublishCheckId.name,
        label: 'Trail Name',
        passed: hasName,
        failureMessage: hasName
            ? null
            : 'Trail name missing — add a name before publishing.',
        targetTabIndex: 3,
      ),
      TrailPublishChecklistItem(
        id: TrailPublishCheckId.banner,
        label: 'Banner',
        passed: hasBanner,
        failureMessage: hasBanner
            ? null
            : 'Banner missing — choose a banner before publishing.',
        targetTabIndex: 2,
      ),
      TrailPublishChecklistItem(
        id: TrailPublishCheckId.venues,
        label: 'Venues',
        passed: hasVenues,
        failureMessage: hasVenues
            ? null
            : 'No venues added — add at least one venue to this trail.',
        targetTabIndex: 1,
      ),
      TrailPublishChecklistItem(
        id: TrailPublishCheckId.availability,
        label: 'Availability',
        passed: validAvailability,
        failureMessage: validAvailability
            ? null
            : 'Invalid availability — check the start and end times.',
        targetTabIndex: 3,
      ),
      TrailPublishChecklistItem(
        id: TrailPublishCheckId.status,
        label: 'Trail Status',
        passed: validStatus,
        failureMessage: validStatus
            ? null
            : 'Trail status is not valid for publishing.',
        targetTabIndex: 4,
      ),
    ];
  }

  static bool isReady(DrinkSpotTrailModel trail) {
    return evaluate(trail).every((item) => item.passed);
  }

  static int _venueCount(DrinkSpotTrailModel trail) {
    return trail.stops.isNotEmpty ? trail.stops.length : trail.venueCount;
  }
}

class PublishChecklistDialog extends StatelessWidget {
  const PublishChecklistDialog({
    super.key,
    required this.trail,
    required this.onNavigateToTab,
  });

  final DrinkSpotTrailModel trail;
  final ValueChanged<int> onNavigateToTab;

  static Future<PublishChecklistResult?> show(
    BuildContext context, {
    required DrinkSpotTrailModel trail,
    required ValueChanged<int> onNavigateToTab,
  }) {
    return showDialog<PublishChecklistResult>(
      context: context,
      builder: (_) => PublishChecklistDialog(
        trail: trail,
        onNavigateToTab: onNavigateToTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = TrailPublishWorkflow.evaluate(trail);
    final ready = items.every((item) => item.passed);
    final failedItems = items.where((item) => !item.passed).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _PublishDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  ready ? Icons.rocket_launch_rounded : Icons.rule_rounded,
                  color: ready
                      ? const Color(0xFFFF2D95)
                      : const Color(0xFFFFB347),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ready ? 'Ready to Publish' : 'Not Ready to Publish',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ready) ...[
              _PublishSummaryRow(label: 'Trail Name', value: trail.name),
              const SizedBox(height: 8),
              _PublishSummaryRow(
                label: 'Number of Venues',
                value: '${TrailPublishWorkflow._venueCount(trail)}',
              ),
              const SizedBox(height: 8),
              _PublishSummaryRow(
                label: 'Availability Date',
                value:
                    '${_formatDateTime(trail.availabilityStart)} – ${_formatDateTime(trail.availabilityEnd)}',
              ),
              const SizedBox(height: 8),
              _PublishSummaryRow(
                label: 'Current Status',
                value: _statusLabel(trail),
              ),
              const SizedBox(height: 20),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PublishChecklistItemRow(item: item),
                ),
            ] else ...[
              const Text(
                'Fix the items below before publishing this trail.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 14),
              for (final item in failedItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PublishChecklistItemRow(item: item),
                ),
            ],
            const SizedBox(height: 20),
            if (ready)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(PublishChecklistResult.publish),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Publish'),
              )
            else
              ..._failedActionButtons(context, failedItems),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(PublishChecklistResult.cancel),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _failedActionButtons(
    BuildContext context,
    List<TrailPublishChecklistItem> failedItems,
  ) {
    final seenTabs = <int>{};
    final buttons = <Widget>[];

    for (final item in failedItems) {
      final tab = item.targetTabIndex;
      if (tab == null || seenTabs.contains(tab)) continue;
      seenTabs.add(tab);
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(PublishChecklistResult.cancel);
              onNavigateToTab(tab);
            },
            icon: Icon(_tabIcon(tab)),
            label: Text(_tabLabel(tab)),
          ),
        ),
      );
    }

    return buttons;
  }

  static IconData _tabIcon(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return Icons.location_on_rounded;
      case 2:
        return Icons.image_rounded;
      case 3:
        return Icons.description_rounded;
      case 4:
        return Icons.settings_rounded;
      case 0:
      default:
        return Icons.dashboard_rounded;
    }
  }

  static String _tabLabel(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'Go to Venues';
      case 2:
        return 'Go to Banner';
      case 3:
        return 'Go to Details';
      case 4:
        return 'Go to Settings';
      case 0:
      default:
        return 'Go to Overview';
    }
  }
}

class PublishChecklistItemRow extends StatelessWidget {
  const PublishChecklistItemRow({required this.item});

  final TrailPublishChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(item.passed ? 0.18 : 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.passed
              ? const Color(0xFFFF2D95).withOpacity(0.22)
              : const Color(0xFFFF6B6B).withOpacity(0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: item.passed
                ? const Color(0xFFFF2D95)
                : const Color(0xFFFF6B6B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.passed ? item.label : item.failureMessage ?? item.label,
              style: TextStyle(
                color: item.passed ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PublishSuccessDialog extends StatelessWidget {
  const PublishSuccessDialog({super.key, required this.onPreviewRoute});

  final VoidCallback onPreviewRoute;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPreviewRoute,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PublishSuccessDialog(onPreviewRoute: onPreviewRoute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: _PublishDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFFF2D95),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'Trail Published Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your trail is now available to users during its scheduled availability window.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onPreviewRoute();
              },
              icon: const Icon(Icons.map_rounded),
              label: const Text('Preview Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class UnpublishConfirmDialog extends StatelessWidget {
  const UnpublishConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const UnpublishConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: _PublishDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Move trail back to Draft?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This trail will no longer be published to users until you publish it again.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Move to Draft'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishDialogShell extends StatelessWidget {
  const _PublishDialogShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111218).withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PublishSummaryRow extends StatelessWidget {
  const _PublishSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$hour:$minute';
}

String _statusLabel(DrinkSpotTrailModel trail) {
  switch (trail.status) {
    case TrailStatus.published:
      return 'Published';
    case TrailStatus.draft:
      return 'Draft';
    case TrailStatus.archived:
    case TrailStatus.disabled:
      return 'Archived';
  }
}
