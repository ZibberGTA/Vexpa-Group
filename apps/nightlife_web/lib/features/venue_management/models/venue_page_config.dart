import 'package:flutter/material.dart';

import 'venue_dashboard_activity.dart';
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
    this.recentActivity = const [],
  });

  final String title;
  final String subtitle;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final List<VenuePageQuickAction> quickActions;
  final List<VenueDashboardActivity> recentActivity;
}

extension VenuePageConfigX on VenueDashboardTab {
  VenuePageConfig get pageConfig {
    return switch (this) {
      VenueDashboardTab.dashboard => VenuePageConfig(
        title: label,
        subtitle: '',
        quickActions: _dashboardQuickActions,
        recentActivity: VenueDashboardActivity.mockRecent,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Logo updated',
            timestampLabel: '1 hour ago',
            icon: Icons.account_circle_outlined,
          ),
          VenueDashboardActivity(
            title: 'Banner changed',
            timestampLabel: '3 hours ago',
            icon: Icons.image_outlined,
          ),
          VenueDashboardActivity(
            title: 'Opening hours edited',
            timestampLabel: 'Yesterday',
            icon: Icons.schedule_outlined,
          ),
          VenueDashboardActivity(
            title: 'Contact details updated',
            timestampLabel: '2 days ago',
            icon: Icons.contact_mail_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Event created',
            timestampLabel: '4 hours ago',
            icon: Icons.event_outlined,
          ),
          VenueDashboardActivity(
            title: 'Event updated',
            timestampLabel: 'Yesterday',
            icon: Icons.edit_outlined,
          ),
          VenueDashboardActivity(
            title: 'Event published',
            timestampLabel: '3 days ago',
            icon: Icons.publish_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Photos uploaded',
            timestampLabel: '1 hour ago',
            icon: Icons.photo_library_outlined,
          ),
          VenueDashboardActivity(
            title: 'Gallery reordered',
            timestampLabel: 'Yesterday',
            icon: Icons.reorder_rounded,
          ),
          VenueDashboardActivity(
            title: 'Featured image changed',
            timestampLabel: '2 days ago',
            icon: Icons.star_outline_rounded,
          ),
        ],
      ),
      VenueDashboardTab.trails => VenuePageConfig(
        title: 'Trails',
        subtitle: 'Manage your venue\'s participation in trails.',
        primaryActionLabel: 'Learn About Trails',
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Joined trail',
            timestampLabel: 'Yesterday',
            icon: Icons.route_outlined,
          ),
          VenueDashboardActivity(
            title: 'Trail updated',
            timestampLabel: '3 days ago',
            icon: Icons.update_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Weekly report generated',
            timestampLabel: 'Yesterday',
            icon: Icons.insights_outlined,
          ),
          VenueDashboardActivity(
            title: 'Analytics exported',
            timestampLabel: '4 days ago',
            icon: Icons.download_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Review received',
            timestampLabel: '2 hours ago',
            icon: Icons.rate_review_outlined,
          ),
          VenueDashboardActivity(
            title: 'Review responded',
            timestampLabel: 'Yesterday',
            icon: Icons.reply_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Staff invited',
            timestampLabel: '3 hours ago',
            icon: Icons.mail_outline_rounded,
          ),
          VenueDashboardActivity(
            title: 'Permission updated',
            timestampLabel: 'Yesterday',
            icon: Icons.admin_panel_settings_outlined,
          ),
          VenueDashboardActivity(
            title: 'Staff removed',
            timestampLabel: '5 days ago',
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Subscription updated',
            timestampLabel: '1 week ago',
            icon: Icons.workspace_premium_outlined,
          ),
          VenueDashboardActivity(
            title: 'Invoice generated',
            timestampLabel: '2 weeks ago',
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Campaign launched',
            timestampLabel: 'Yesterday',
            icon: Icons.campaign_outlined,
          ),
          VenueDashboardActivity(
            title: 'Notification sent',
            timestampLabel: '3 days ago',
            icon: Icons.notifications_active_outlined,
          ),
          VenueDashboardActivity(
            title: 'QR downloaded',
            timestampLabel: '1 week ago',
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Ticket created',
            timestampLabel: 'Recently',
            icon: Icons.confirmation_number_outlined,
          ),
          VenueDashboardActivity(
            title: 'Ticket updated',
            timestampLabel: 'Recently',
            icon: Icons.edit_outlined,
          ),
          VenueDashboardActivity(
            title: 'Reply received',
            timestampLabel: 'Recently',
            icon: Icons.mark_email_read_outlined,
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
        recentActivity: const [
          VenueDashboardActivity(
            title: 'Password changed',
            timestampLabel: '2 weeks ago',
            icon: Icons.lock_outline_rounded,
          ),
          VenueDashboardActivity(
            title: 'Settings updated',
            timestampLabel: '3 days ago',
            icon: Icons.settings_outlined,
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
  ),
  VenuePageQuickAction(
    label: 'Create a Deal',
    icon: Icons.local_offer_outlined,
    targetTab: VenueDashboardTab.deals,
  ),
  VenuePageQuickAction(
    label: 'Add Event',
    icon: Icons.event_available_outlined,
    targetTab: VenueDashboardTab.events,
  ),
  VenuePageQuickAction(
    label: 'Upload Photos',
    icon: Icons.cloud_upload_outlined,
    targetTab: VenueDashboardTab.gallery,
  ),
];
