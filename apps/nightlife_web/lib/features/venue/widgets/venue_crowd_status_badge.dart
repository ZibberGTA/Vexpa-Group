import 'package:flutter/material.dart';
import 'package:vex_engines/venue/shared/crowd_status_presentation.dart';

import '../../../core/theme/app_colors.dart';
import '../services/venue_crowd_status_service.dart';

/// Customer-facing crowd status pill for venue hero surfaces.
class VenueCrowdStatusBadge extends StatefulWidget {
  const VenueCrowdStatusBadge({
    super.key,
    required this.venueId,
    required this.crowdLevel,
    this.crowdUpdatedAt,
    this.previewOnly = false,
  });

  final String venueId;
  final String crowdLevel;
  final DateTime? crowdUpdatedAt;
  final bool previewOnly;

  @override
  State<VenueCrowdStatusBadge> createState() => _VenueCrowdStatusBadgeState();
}

class _VenueCrowdStatusBadgeState extends State<VenueCrowdStatusBadge> {
  late Stream<VenueCrowdStatusSnapshot> _crowdStream;

  @override
  void initState() {
    super.initState();
    _crowdStream = _buildStream();
  }

  @override
  void didUpdateWidget(covariant VenueCrowdStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId ||
        oldWidget.crowdLevel != widget.crowdLevel ||
        oldWidget.crowdUpdatedAt != widget.crowdUpdatedAt) {
      _crowdStream = _buildStream();
    }
  }

  Stream<VenueCrowdStatusSnapshot> _buildStream() {
    return VenueCrowdStatusService.venueCrowdStream(
      venueId: widget.venueId,
      manualLevel: widget.crowdLevel,
      updatedAt: widget.crowdUpdatedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VenueCrowdStatusSnapshot>(
      stream: _crowdStream,
      builder: (context, snapshot) {
        final level = snapshot.data?.level ??
            CrowdStatusPresentation.displayLevel(
              level: widget.crowdLevel,
              updatedAt: widget.crowdUpdatedAt,
            );
        final label = CrowdStatusPresentation.labelForLevel(level);
        final badge = _CrowdStatusBadgeShell(label: label);

        if (widget.previewOnly) {
          return AbsorbPointer(child: badge);
        }

        return badge;
      },
    );
  }
}

class _CrowdStatusBadgeShell extends StatelessWidget {
  const _CrowdStatusBadgeShell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
