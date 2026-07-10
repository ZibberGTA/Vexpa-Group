import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../models/media_library_tab.dart';

/// Usage counter with progress bar for the active media library tab.
class MediaUsageCard extends StatelessWidget {
  const MediaUsageCard({
    super.key,
    required this.tab,
    required this.used,
    required this.limit,
  });

  final MediaLibraryTab tab;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    if (tab == MediaLibraryTab.brandAssets) {
      return const BrandAssetsInfoCard();
    }

    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final barSegments = 20;
    final filledSegments = (ratio * barSegments).round();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tab.label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$used / $limit ${tab.usageLabel}',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _progressBar(filledSegments, barSegments),
            style: TextStyle(
              color: ratio >= 1
                  ? AppColors.primaryPink
                  : AppColors.primaryPurple.withValues(alpha: 0.95),
              fontSize: 16,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _progressBar(int filled, int total) {
    final buffer = StringBuffer();
    for (var i = 0; i < total; i++) {
      buffer.write(i < filled ? '█' : '░');
    }
    return buffer.toString();
  }
}

/// Brand assets are managed from Venue Profile and excluded from gallery limits.
class BrandAssetsInfoCard extends StatelessWidget {
  const BrandAssetsInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Brand Assets',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Logo and banner uploads are managed from Venue Profile. '
            'They do not count toward your gallery photo limit.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
