import 'package:flutter/material.dart';

import 'venue_dashboard_tab.dart';
import 'venue_page_quick_action.dart';

/// Page-level configuration for a venue management tab.
class VenuePageConfig {
  const VenuePageConfig({
    required this.title,
    required this.subtitle,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.quickActions = const [],
  });

  final String title;
  final String subtitle;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final List<VenuePageQuickAction> quickActions;
}

extension VenuePageConfigX on VenueDashboardTab {
  VenuePageConfig get pageConfig {
    return switch (this) {
      VenueDashboardTab.dashboard => VenuePageConfig(
        title: label,
        subtitle: '',
        quickActions: _dashboardQuickActions,
      ),
      VenueDashboardTab.map => VenuePageConfig(title: label, subtitle: ''),
      VenueDashboardTab.venueProfile => VenuePageConfig(
        title: 'Venue Profile',
        subtitle: 'Manage how your venue appears to customers.',
        primaryActionLabel: 'Edit Profile',
        primaryActionIcon: Icons.edit_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Edit Venue Details',
            icon: Icons.storefront_outlined,
          ),
          VenuePageQuickAction(
            label: 'Change Banner',
            icon: Icons.image_outlined,
            actionKey: 'change_banner',
          ),
          VenuePageQuickAction(
            label: 'Upload Logo',
            icon: Icons.account_circle_outlined,
            actionKey: 'upload_logo',
          ),
          VenuePageQuickAction(
            label: 'Adjust Banner Position',
            icon: Icons.crop_outlined,
            actionKey: 'adjust_banner_position',
          ),
          VenuePageQuickAction(
            label: 'Adjust Logo Position',
            icon: Icons.crop_outlined,
            actionKey: 'adjust_logo_position',
          ),
          VenuePageQuickAction(
            label: 'Update Opening Hours',
            icon: Icons.schedule_outlined,
          ),
          VenuePageQuickAction(
            label: 'Edit Tags',
            icon: Icons.label_outline_rounded,
          ),
        ],
      ),
      VenueDashboardTab.drinks => VenuePageConfig(
        title: 'Drinks',
        subtitle: 'Manage your drinks menu and categories.',
        primaryActionLabel: 'Add Drink',
        primaryActionIcon: Icons.add_rounded,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Add Drink',
            icon: Icons.add_circle_outline_rounded,
            actionKey: 'add_drink',
          ),
          VenuePageQuickAction(
            label: 'Bulk Import',
            icon: Icons.upload_file_outlined,
            actionKey: 'bulk_import_drinks',
          ),
          VenuePageQuickAction(
            label: 'Bulk Update Prices',
            icon: Icons.price_change_outlined,
          ),
          VenuePageQuickAction(
            label: 'Copy Drinks',
            icon: Icons.copy_all_outlined,
          ),
          VenuePageQuickAction(
            label: 'Export Drinks',
            icon: Icons.download_outlined,
            actionKey: 'export_drinks',
          ),
        ],
      ),
      VenueDashboardTab.deals => VenuePageConfig(
        title: 'Deals',
        subtitle: 'Create and manage promotional offers for your venue.',
        primaryActionLabel: 'Create Deal',
        primaryActionIcon: Icons.add_rounded,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Add Deal',
            icon: Icons.add_circle_outline_rounded,
            actionKey: 'create_deal',
          ),
          VenuePageQuickAction(
            label: 'Duplicate Deal',
            icon: Icons.copy_outlined,
            actionKey: 'duplicate_deal',
          ),
          VenuePageQuickAction(
            label: 'Export Deals',
            icon: Icons.download_outlined,
            actionKey: 'export_deals',
          ),
          VenuePageQuickAction(
            label: 'View Deal Performance',
            icon: Icons.insights_outlined,
            actionKey: 'view_deal_performance',
          ),
          VenuePageQuickAction(
            label: 'Pause Selected Deal(s)',
            icon: Icons.pause_circle_outline_rounded,
            actionKey: 'pause_selected_deals',
          ),
        ],
      ),
      VenueDashboardTab.events => VenuePageConfig(
        title: 'Events',
        subtitle: 'Create and manage upcoming events.',
        primaryActionLabel: 'Add Event',
        primaryActionIcon: Icons.add_rounded,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Add Event',
            icon: Icons.event_available_outlined,
            actionKey: 'add_event',
          ),
          VenuePageQuickAction(
            label: 'Duplicate Event',
            icon: Icons.copy_outlined,
            actionKey: 'duplicate_event',
          ),
          VenuePageQuickAction(
            label: 'Export Events',
            icon: Icons.download_outlined,
            actionKey: 'export_events',
          ),
          VenuePageQuickAction(
            label: 'Upload Event Banner',
            icon: Icons.image_outlined,
            actionKey: 'upload_event_banner',
          ),
          VenuePageQuickAction(
            label: 'View Event Performance',
            icon: Icons.insights_outlined,
            actionKey: 'view_event_performance',
          ),
        ],
      ),
      VenueDashboardTab.gallery => VenuePageConfig(
        title: 'Gallery',
        subtitle: 'Manage venue, deal and event media libraries.',
        primaryActionLabel: 'Upload Photos',
        primaryActionIcon: Icons.cloud_upload_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Upload Photos',
            icon: Icons.cloud_upload_outlined,
          ),
          VenuePageQuickAction(
            label: 'Reorder Gallery',
            icon: Icons.reorder_rounded,
          ),
          VenuePageQuickAction(
            label: 'Delete Photos',
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
      VenueDashboardTab.trails => VenuePageConfig(
        title: 'Trails',
        subtitle:
            'Join local trails, increase exposure and attract more customers.',
        primaryActionLabel: 'Learn about Trails',
        primaryActionIcon: Icons.help_outline_rounded,
        quickActions: const [
          VenuePageQuickAction(
            label: 'View Public Profile',
            icon: Icons.open_in_new_rounded,
          ),
          VenuePageQuickAction(
            label: 'Improve Venue Profile',
            icon: Icons.auto_fix_high_rounded,
          ),
          VenuePageQuickAction(
            label: 'Contact Support',
            icon: Icons.support_agent_outlined,
          ),
          VenuePageQuickAction(
            label: 'Learn About Trails',
            icon: Icons.route_outlined,
          ),
        ],
      ),
      VenueDashboardTab.analytics => VenuePageConfig(
        title: 'Venue Analytics',
        subtitle:
            'Understand how customers discover, engage with and return to your venue.',
        primaryActionLabel: 'Export Report',
        primaryActionIcon: Icons.download_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Export Report',
            icon: Icons.download_outlined,
          ),
          VenuePageQuickAction(
            label: 'Change Date Range',
            icon: Icons.date_range_outlined,
          ),
          VenuePageQuickAction(
            label: 'Download CSV',
            icon: Icons.table_chart_outlined,
          ),
        ],
      ),
      VenueDashboardTab.reviews => VenuePageConfig(
        title: 'Reviews',
        subtitle: 'Monitor customer feedback and ratings.',
        primaryActionLabel: 'Respond to Reviews',
        primaryActionIcon: Icons.reply_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Respond to Reviews',
            icon: Icons.reply_outlined,
          ),
          VenuePageQuickAction(
            label: 'Filter Reviews',
            icon: Icons.filter_list_outlined,
          ),
        ],
      ),
      VenueDashboardTab.team => VenuePageConfig(
        title: 'Team',
        subtitle: 'Manage staff accounts, permissions and roles.',
        primaryActionLabel: 'Invite Staff',
        primaryActionIcon: Icons.person_add_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Invite Staff',
            icon: Icons.person_add_outlined,
          ),
          VenuePageQuickAction(
            label: 'Edit Permissions',
            icon: Icons.admin_panel_settings_outlined,
          ),
          VenuePageQuickAction(
            label: 'Remove Staff',
            icon: Icons.person_remove_outlined,
          ),
        ],
      ),
      VenueDashboardTab.subscription => VenuePageConfig(
        title: 'Subscription',
        subtitle: 'Choose the plan that fits how your venue grows with Vexda.',
        primaryActionLabel: 'Manage Plan',
        primaryActionIcon: Icons.workspace_premium_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Upgrade Plan',
            icon: Icons.workspace_premium_outlined,
          ),
          VenuePageQuickAction(
            label: 'Manage Billing',
            icon: Icons.payment_outlined,
          ),
          VenuePageQuickAction(
            label: 'View Invoices',
            icon: Icons.receipt_long_outlined,
          ),
        ],
      ),
      VenueDashboardTab.marketing => VenuePageConfig(
        title: 'Marketing',
        subtitle: 'Promote your venue and reach more customers.',
        primaryActionLabel: 'Create Campaign',
        primaryActionIcon: Icons.campaign_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Create Campaign',
            icon: Icons.campaign_outlined,
          ),
          VenuePageQuickAction(
            label: 'Send Notification',
            icon: Icons.notifications_active_outlined,
          ),
          VenuePageQuickAction(
            label: 'Download QR Code',
            icon: Icons.qr_code_2_outlined,
          ),
        ],
      ),
      VenueDashboardTab.support => VenuePageConfig(
        title: 'Support',
        subtitle: 'Raise tickets and get help from the Vexda team.',
        primaryActionLabel: 'Create Ticket',
        primaryActionIcon: Icons.add_comment_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Create Ticket',
            icon: Icons.add_comment_outlined,
          ),
          VenuePageQuickAction(
            label: 'View Open Tickets',
            icon: Icons.confirmation_number_outlined,
          ),
          VenuePageQuickAction(
            label: 'View Ticket History',
            icon: Icons.history_rounded,
          ),
        ],
      ),
      VenueDashboardTab.settings => VenuePageConfig(
        title: 'Settings',
        subtitle: 'Configure your venue preferences and account settings.',
        primaryActionLabel: 'Save Changes',
        primaryActionIcon: Icons.save_outlined,
        quickActions: const [
          VenuePageQuickAction(
            label: 'Change Password',
            icon: Icons.lock_outline_rounded,
          ),
          VenuePageQuickAction(
            label: 'Notification Settings',
            icon: Icons.notifications_outlined,
          ),
          VenuePageQuickAction(
            label: 'Export Data',
            icon: Icons.download_outlined,
          ),
        ],
      ),
    };
  }
}

const _dashboardQuickActions = [
  VenuePageQuickAction(
    label: 'Edit Venue Profile',
    icon: Icons.edit_outlined,
    targetTab: VenueDashboardTab.venueProfile,
  ),
  VenuePageQuickAction(
    label: 'Add New Drink',
    icon: Icons.add_circle_outline_rounded,
    targetTab: VenueDashboardTab.drinks,
    actionKey: 'add_drink',
  ),
  VenuePageQuickAction(
    label: 'Create a Deal',
    icon: Icons.local_offer_outlined,
    targetTab: VenueDashboardTab.deals,
    actionKey: 'create_deal',
  ),
  VenuePageQuickAction(
    label: 'Add Event',
    icon: Icons.event_available_outlined,
    targetTab: VenueDashboardTab.events,
    actionKey: 'add_event',
  ),
  VenuePageQuickAction(
    label: 'Upload Photos',
    icon: Icons.cloud_upload_outlined,
    targetTab: VenueDashboardTab.gallery,
    actionKey: 'media_upload',
  ),
];
