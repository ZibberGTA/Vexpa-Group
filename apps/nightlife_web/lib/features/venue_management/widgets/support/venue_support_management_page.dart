import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_config.dart';
import '../../models/venue_page_quick_action.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';

/// Support workspace — styled framework until ticketing is implemented.
class VenueSupportManagementPage extends StatelessWidget {
  const VenueSupportManagementPage({super.key});

  void _handleQuickAction(BuildContext context, VenuePageQuickAction action) {
    showVenuePagePlaceholderAction(context, action.label);
  }

  @override
  Widget build(BuildContext context) {
    return VenueDashboardPageScaffold(
      tab: VenueDashboardTab.support,
      onQuickAction: (action) => _handleQuickAction(context, action),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenuePageMetricRow(
            metrics: const [
              VenuePageMetricCard(
                label: 'Open Tickets',
                value: '0',
                icon: Icons.confirmation_number_outlined,
              ),
              VenuePageMetricCard(
                label: 'Awaiting Reply',
                value: '0',
                icon: Icons.mark_email_unread_outlined,
              ),
              VenuePageMetricCard(
                label: 'Resolved',
                value: '0',
                icon: Icons.task_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          VenuePageSection(
            title: 'Support Centre',
            child: Column(
              children: const [
                VenuePageSummaryTile(
                  label: 'Open Tickets',
                  value: 'No open tickets yet.',
                  icon: Icons.confirmation_number_outlined,
                ),
                SizedBox(height: AppSpacing.sm),
                VenuePageSummaryTile(
                  label: 'Create Support Ticket',
                  value: 'Raise a request with the Vexda team.',
                  icon: Icons.add_comment_outlined,
                ),
                SizedBox(height: AppSpacing.sm),
                VenuePageSummaryTile(
                  label: 'Ticket History',
                  value: 'Your previous support requests will appear here.',
                  icon: Icons.history_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
