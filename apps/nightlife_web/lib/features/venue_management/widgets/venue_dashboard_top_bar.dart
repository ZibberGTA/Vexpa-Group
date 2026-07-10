import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/vexda_logo.dart';
import '../models/venue_dashboard_context.dart';
import 'venue_dashboard_layout.dart';

/// Fixed top bar for the venue management dashboard.
class VenueDashboardTopBar extends StatelessWidget {
  const VenueDashboardTopBar({
    super.key,
    required this.contextData,
    required this.onNotificationsTap,
  });

  final VenueDashboardContext contextData;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: VenueDashboardLayout.topBarHeight,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.78),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.home,
                      (_) => false,
                    );
                  },
                  child: VexdaLogo(
                    height: isMobile
                        ? VenueDashboardLayout.headerLogoHeightMobile
                        : VenueDashboardLayout.headerLogoHeightDesktop,
                  ),
                ),
              ),
              const Spacer(),
              _NotificationBellButton(
                unreadCount: contextData.unreadNotifications,
                onPressed: onNotificationsTap,
              ),
              if (!isMobile) ...[
                const SizedBox(width: AppSpacing.lg),
                _OwnerVenueSummary(contextData: contextData),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerVenueSummary extends StatelessWidget {
  const _OwnerVenueSummary({required this.contextData});

  final VenueDashboardContext contextData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          contextData.ownerName,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          contextData.venueName,
          style: TextStyle(
            color: AppColors.primaryPink.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _NotificationBellButton extends StatefulWidget {
  const _NotificationBellButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  State<_NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _hovered ? AppColors.brandGradient : null,
            color: _hovered ? null : AppColors.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: _hovered
                  ? Colors.transparent
                  : AppColors.primaryPurple.withValues(alpha: 0.28),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _hovered ? AppColors.white : AppColors.textSecondary,
                size: 22,
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
