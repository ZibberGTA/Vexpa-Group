import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';
import 'admin_permission_constants.dart';

/// Premium access-restricted card for admin pages the user cannot view.
class AdminAccessRestrictedCard extends StatelessWidget {
  const AdminAccessRestrictedCard({
    super.key,
    required this.pageTitle,
    this.detail =
        'You do not have permission to view this area. Contact a platform administrator if you need access.',
  });

  final String pageTitle;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: '$pageTitle access restricted',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.primaryPink,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            detail,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Wraps a button-like control with a permission tooltip when disabled.
class AdminPermissionTooltip extends StatelessWidget {
  const AdminPermissionTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: message, child: child);
  }
}

/// Returns [onPressed] when allowed, otherwise null with denial tooltip.
Widget adminPermissionButton({
  required bool allowed,
  required Widget child,
  required VoidCallback? onPressed,
  String deniedMessage = kAdminPermissionDeniedTooltip,
}) {
  return AdminPermissionTooltip(
    message: allowed ? '' : deniedMessage,
    child: IgnorePointer(
      ignoring: !allowed && onPressed != null,
      child: Opacity(
        opacity: allowed || onPressed == null ? 1 : 0.55,
        child: child,
      ),
    ),
  );
}
