import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vex_engines/venue/shared/venue_opening_status_presentation.dart';

import '../../../core/theme/app_colors.dart';

/// Customer-facing opening status line for venue hero surfaces.
class VenueOpeningStatusLine extends StatefulWidget {
  const VenueOpeningStatusLine({
    super.key,
    required this.openingHours,
  });

  final Map<String, dynamic> openingHours;

  @override
  State<VenueOpeningStatusLine> createState() => _VenueOpeningStatusLineState();
}

class _VenueOpeningStatusLineState extends State<VenueOpeningStatusLine> {
  Timer? _refreshTimer;
  late VenueOpeningStatus _status;

  @override
  void initState() {
    super.initState();
    _status = _resolveStatus();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _status = _resolveStatus());
    });
  }

  @override
  void didUpdateWidget(covariant VenueOpeningStatusLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openingHours != widget.openingHours) {
      setState(() => _status = _resolveStatus());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  VenueOpeningStatus _resolveStatus() {
    return VenueOpeningStatusPresentation.resolve(widget.openingHours);
  }

  @override
  Widget build(BuildContext context) {
    if (!_status.hasHours || _status.label.isEmpty) {
      return const SizedBox.shrink();
    }

    final parts = _status.label.split(' • ');
    final stateText = parts.isNotEmpty ? parts.first : _status.label;
    final detailText = parts.length > 1 ? parts.sublist(1).join(' • ') : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stateText,
          style: TextStyle(
            color: _status.isOpen
                ? const Color(0xFF35E06F)
                : const Color(0xFFFF5A6A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (detailText.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '• $detailText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
