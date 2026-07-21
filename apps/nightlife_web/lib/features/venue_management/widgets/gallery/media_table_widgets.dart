import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../../shared/widgets/venue_network_image.dart';
import '../../data/venue_media_repository.dart';
import '../../models/venue_media_item.dart';
import '../../models/venue_media_type.dart';
import '../drinks/drink_selection_checkbox.dart';

enum MediaSortColumn { name, uploaded, cover }

class MediaTableSort {
  const MediaTableSort({
    this.column = MediaSortColumn.uploaded,
    this.ascending = false,
  });

  final MediaSortColumn column;
  final bool ascending;

  MediaTableSort toggleColumn(MediaSortColumn next) {
    if (column == next) {
      return MediaTableSort(column: next, ascending: !ascending);
    }
    return MediaTableSort(column: next, ascending: true);
  }
}

/// Shared column widths so header and row cells stay aligned.
abstract final class MediaTableSpec {
  static const checkboxColumnWidth = 32.0;
  static const thumbnailColumnWidth = 44.0;
  static const coverColumnWidth = 108.0;
  static const actionsColumnWidth = 72.0;
  static const nameFlex = 3;
  static const uploadedFlex = 2;

  static const rowHorizontalPadding = AppSpacing.md;
  static const rowVerticalPadding = AppSpacing.sm + 2;
}

List<VenueMediaItem> sortMediaItems(
  List<VenueMediaItem> items,
  MediaTableSort sort,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    int compare;
    switch (sort.column) {
      case MediaSortColumn.name:
        compare = a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      case MediaSortColumn.uploaded:
        final aTime = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        compare = aTime.compareTo(bTime);
      case MediaSortColumn.cover:
        compare = (a.isCover ? 1 : 0).compareTo(b.isCover ? 1 : 0);
    }
    return sort.ascending ? compare : -compare;
  });
  return sorted;
}

class MediaTableHeader extends StatelessWidget {
  const MediaTableHeader({
    super.key,
    required this.sort,
    required this.onSortColumn,
    this.showCoverColumn = true,
    this.coverColumnLabel = 'Featured',
  });

  final MediaTableSort sort;
  final ValueChanged<MediaSortColumn> onSortColumn;
  final bool showCoverColumn;
  final String coverColumnLabel;

  @override
  Widget build(BuildContext context) {
    return _MediaTableRowShell(
      child: _MediaTableColumns(
        showCoverColumn: showCoverColumn,
        checkbox: const SizedBox.shrink(),
        thumbnail: const SizedBox.shrink(),
        name: _SortableHeaderCell(
          label: 'Name',
          active: sort.column == MediaSortColumn.name,
          ascending: sort.ascending,
          onTap: () => onSortColumn(MediaSortColumn.name),
        ),
        uploaded: _SortableHeaderCell(
          label: 'Uploaded',
          active: sort.column == MediaSortColumn.uploaded,
          ascending: sort.ascending,
          onTap: () => onSortColumn(MediaSortColumn.uploaded),
        ),
        cover: showCoverColumn
            ? _SortableHeaderCell(
                label: coverColumnLabel,
                active: sort.column == MediaSortColumn.cover,
                ascending: sort.ascending,
                onTap: () => onSortColumn(MediaSortColumn.cover),
              )
            : const SizedBox.shrink(),
        actions: const SizedBox.shrink(),
      ),
    );
  }
}

class _MediaTableRowShell extends StatelessWidget {
  const _MediaTableRowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MediaTableSpec.rowHorizontalPadding,
        vertical: MediaTableSpec.rowVerticalPadding,
      ),
      child: child,
    );
  }
}

class _MediaTableColumns extends StatelessWidget {
  const _MediaTableColumns({
    required this.showCoverColumn,
    required this.checkbox,
    required this.thumbnail,
    required this.name,
    required this.uploaded,
    required this.cover,
    required this.actions,
  });

  final bool showCoverColumn;
  final Widget checkbox;
  final Widget thumbnail;
  final Widget name;
  final Widget uploaded;
  final Widget cover;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: MediaTableSpec.checkboxColumnWidth,
          child: Align(alignment: Alignment.centerLeft, child: checkbox),
        ),
        SizedBox(
          width: MediaTableSpec.thumbnailColumnWidth,
          child: Align(alignment: Alignment.centerLeft, child: thumbnail),
        ),
        Expanded(
          flex: MediaTableSpec.nameFlex,
          child: Align(alignment: Alignment.centerLeft, child: name),
        ),
        Expanded(
          flex: MediaTableSpec.uploadedFlex,
          child: Align(alignment: Alignment.centerLeft, child: uploaded),
        ),
        if (showCoverColumn)
          SizedBox(
            width: MediaTableSpec.coverColumnWidth,
            child: Align(alignment: Alignment.centerLeft, child: cover),
          ),
        SizedBox(
          width: MediaTableSpec.actionsColumnWidth,
          child: Align(alignment: Alignment.centerRight, child: actions),
        ),
      ],
    );
  }
}

class _SortableHeaderCell extends StatelessWidget {
  const _SortableHeaderCell({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primaryPink : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.3,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: AppColors.primaryPink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MediaItemRow extends StatefulWidget {
  const MediaItemRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onAdjustPosition,
    this.onSetFeatured,
    this.isSettingFeatured = false,
    this.showCoverColumn = true,
    this.showCurrentColumn = false,
    this.showDivider = true,
  });

  final VenueMediaItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback? onAdjustPosition;
  final VoidCallback? onSetFeatured;
  final bool isSettingFeatured;
  final bool showCoverColumn;
  final bool showCurrentColumn;
  final bool showDivider;

  @override
  State<MediaItemRow> createState() => _MediaItemRowState();
}

class _MediaItemRowState extends State<MediaItemRow> {
  bool _hovered = false;
  bool _previewTriggerHovered = false;
  bool _previewCardHovered = false;
  bool _tapPreviewActive = false;
  OverlayEntry? _previewOverlay;
  Timer? _hidePreviewTimer;

  bool get _showPreviewTarget =>
      widget.item.hasLoadableUrl &&
      (_previewTriggerHovered || _previewCardHovered || _tapPreviewActive);

  @override
  void dispose() {
    _hidePreviewTimer?.cancel();
    _removePreviewOverlay();
    super.dispose();
  }

  void _handleRowEnter() {
    setState(() => _hovered = true);
  }

  void _handleRowExit() {
    setState(() => _hovered = false);
  }

  void _handlePreviewTriggerEnter() {
    _hidePreviewTimer?.cancel();
    setState(() => _previewTriggerHovered = true);
    _showPreviewOverlay();
  }

  void _handlePreviewTriggerExit() {
    setState(() => _previewTriggerHovered = false);
    _scheduleRemovePreviewOverlay();
  }

  void _handlePreviewTap() {
    if (!widget.item.hasLoadableUrl) return;

    if (_tapPreviewActive) {
      _removePreviewOverlay();
      setState(() {});
      return;
    }

    _hidePreviewTimer?.cancel();
    setState(() => _tapPreviewActive = true);
    _showPreviewOverlay(fromTap: true);
  }

  void _scheduleRemovePreviewOverlay() {
    _hidePreviewTimer?.cancel();
    _hidePreviewTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (!_previewTriggerHovered &&
          !_previewCardHovered &&
          !_tapPreviewActive) {
        _removePreviewOverlay();
        if (mounted) setState(() {});
      }
    });
  }

  void _showPreviewOverlay({bool fromTap = false}) {
    if (!widget.item.hasLoadableUrl) return;

    if (fromTap) {
      _tapPreviewActive = true;
    }

    if (_previewOverlay != null) {
      _previewOverlay!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _previewOverlay = OverlayEntry(
      builder: (overlayContext) {
        return _CenteredMediaPreviewOverlay(
          url: widget.item.previewUrl,
          displayName: widget.item.displayName,
          tapMode: _tapPreviewActive,
          onDismiss: () {
            _removePreviewOverlay();
            if (mounted) setState(() {});
          },
          onPreviewEnter: () {
            _previewCardHovered = true;
            _hidePreviewTimer?.cancel();
          },
          onPreviewExit: () {
            _previewCardHovered = false;
            _scheduleRemovePreviewOverlay();
          },
        );
      },
    );

    overlay.insert(_previewOverlay!);
  }

  void _removePreviewOverlay() {
    _tapPreviewActive = false;
    _previewCardHovered = false;
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  Widget _previewTrigger({required Widget child}) {
    return MouseRegion(
      onEnter: (_) => _handlePreviewTriggerEnter(),
      onExit: (_) => _handlePreviewTriggerExit(),
      child: GestureDetector(
        onTap: _handlePreviewTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadedLabel = widget.item.uploadedAt == null
        ? '—'
        : VenueMediaRepository.relativeTimeLabel(widget.item.uploadedAt!);

    return MouseRegion(
      onEnter: (_) => _handleRowEnter(),
      onExit: (_) => _handleRowExit(),
      child: AnimatedContainer(
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        decoration: BoxDecoration(
          color: _hovered || widget.isSelected
              ? AppColors.primaryPurple.withValues(
                  alpha: widget.isSelected ? 0.16 : 0.08,
                )
              : widget.item.isCover
              ? AppColors.primaryPink.withValues(alpha: 0.08)
              : Colors.transparent,
          border: widget.showDivider
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.glassBorder.withValues(alpha: 0.45),
                  ),
                )
              : null,
          boxShadow: widget.item.isCover
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : _hovered
              ? PremiumEffects.hoverGlow(intensity: 0.2)
              : null,
        ),
        child: _MediaTableRowShell(
          child: _MediaTableColumns(
            showCoverColumn: widget.showCoverColumn,
            checkbox: DrinkSelectionCheckbox(
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
            ),
            thumbnail: _previewTrigger(
              child: _MediaThumbnail(
                item: widget.item,
                hovered: _showPreviewTarget,
              ),
            ),
            name: _previewTrigger(
              child: Text(
                widget.showCurrentColumn
                    ? '${widget.item.mediaType.label} · ${widget.item.displayName}'
                    : widget.item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            uploaded: Text(
              uploadedLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            cover: widget.showCoverColumn
                ? _FeaturedColumnCell(
                    item: widget.item,
                    onSetFeatured: widget.onSetFeatured,
                    isSettingFeatured: widget.isSettingFeatured,
                  )
                : widget.showCurrentColumn && widget.item.isCurrent
                ? Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primaryPink.withValues(alpha: 0.95),
                  )
                : const SizedBox.shrink(),
            actions: widget.onAdjustPosition == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: _hovered ? widget.onAdjustPosition : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Adjust',
                      style: TextStyle(
                        color: _hovered
                            ? AppColors.primaryPink
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedColumnCell extends StatelessWidget {
  const _FeaturedColumnCell({
    required this.item,
    this.onSetFeatured,
    this.isSettingFeatured = false,
  });

  final VenueMediaItem item;
  final VoidCallback? onSetFeatured;
  final bool isSettingFeatured;

  @override
  Widget build(BuildContext context) {
    if (item.isCover) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: AppColors.primaryPink.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
              color: AppColors.primaryPink.withValues(alpha: 0.95),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (onSetFeatured == null || !item.canBeFeatured) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: isSettingFeatured ? null : onSetFeatured,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: isSettingFeatured
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryPink.withValues(alpha: 0.9),
              ),
            )
          : Text(
              'Set as Featured',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.item, required this.hovered});

  final VenueMediaItem item;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: hovered ? 1.04 : 1,
      duration: PremiumEffects.fast,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: SizedBox(
          width: MediaTableSpec.thumbnailColumnWidth,
          height: MediaTableSpec.thumbnailColumnWidth,
          child: _MediaNetworkImage(
            url: item.previewUrl,
            fit: BoxFit.cover,
            error: const _ThumbnailError(),
          ),
        ),
      ),
    );
  }
}

class _CenteredMediaPreviewOverlay extends StatelessWidget {
  const _CenteredMediaPreviewOverlay({
    required this.url,
    required this.displayName,
    required this.tapMode,
    required this.onDismiss,
    required this.onPreviewEnter,
    required this.onPreviewExit,
  });

  final String url;
  final String displayName;
  final bool tapMode;
  final VoidCallback onDismiss;
  final VoidCallback onPreviewEnter;
  final VoidCallback onPreviewExit;

  static const _minPreviewWidth = 320.0;
  static const _maxPreviewWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final previewWidth = (viewportWidth * 0.28).clamp(
      _minPreviewWidth,
      _maxPreviewWidth,
    );

    return Stack(
      children: [
        if (tapMode)
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
            ),
          ),
        Center(
          child: MouseRegion(
            onEnter: (_) => onPreviewEnter(),
            onExit: (_) => onPreviewExit(),
            child: Material(
              color: Colors.transparent,
              elevation: 24,
              shadowColor: AppColors.primaryPurple.withValues(alpha: 0.45),
              child: _HoverPreviewCard(
                url: url,
                displayName: displayName,
                width: previewWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverPreviewCard extends StatelessWidget {
  const _HoverPreviewCard({
    required this.url,
    required this.displayName,
    required this.width,
  });

  final String url;
  final String displayName;
  final double width;

  static const _imageAreaHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    const imageAreaHeight = _HoverPreviewCard._imageAreaHeight;
    final contentWidth = width - (AppSpacing.sm * 2);
    final trimmedName = displayName.trim();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.medium,
      innerHighlight: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: PremiumEffects.hoverGlow(intensity: 0.35),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: contentWidth,
                height: imageAreaHeight,
                child: _MediaNetworkImage(
                  url: url,
                  fit: BoxFit.contain,
                  error: const _PreviewErrorPlaceholder(),
                ),
              ),
            ),
            if (trimmedName.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: contentWidth,
                child: Text(
                  trimmedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaNetworkImage extends StatelessWidget {
  const _MediaNetworkImage({
    required this.url,
    required this.fit,
    required this.error,
  });

  final String url;
  final BoxFit fit;
  final Widget error;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return error;

    return VenueNetworkImage(
      url: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorWidget: error,
    );
  }
}

class _ThumbnailError extends StatelessWidget {
  const _ThumbnailError();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.35),
        ),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
        size: 18,
      ),
    );
  }
}

class _PreviewErrorPlaceholder extends StatelessWidget {
  const _PreviewErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.88),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Preview unavailable',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaSelectionActionBar extends StatelessWidget {
  const MediaSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onClearSelection,
    this.onSetCover,
    this.onReplace,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onClearSelection;
  final VoidCallback? onSetCover;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Selected: $selectedCount',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          if (onSetCover != null)
            TextButton.icon(
              onPressed: onSetCover,
              icon: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Set as Featured'),
            ),
          if (onReplace != null)
            TextButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Replace'),
            ),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
          ),
          TextButton.icon(
            onPressed: onClearSelection,
            icon: const Icon(Icons.deselect_outlined, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Opens the existing tap-to-preview overlay for a gallery media item.
void showVenueMediaItemPreviewOverlay(
  BuildContext context,
  VenueMediaItem item,
) {
  if (!item.hasLoadableUrl) return;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return _CenteredMediaPreviewOverlay(
        url: item.previewUrl,
        displayName: item.displayName,
        tapMode: true,
        onDismiss: () => entry.remove(),
        onPreviewEnter: () {},
        onPreviewExit: () => entry.remove(),
      );
    },
  );
  overlay.insert(entry);
}
