import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/positioned_venue_image.dart';
import '../../../venues/models/image_position_metadata.dart';

/// Opens the image reposition dialog and returns saved metadata, or null if cancelled.
Future<ImagePositionMetadata?> showImageRepositionDialog(
  BuildContext context, {
  required ImageFrameKind frameKind,
  ImageProvider? imageProvider,
  String? imageUrl,
  ImagePositionMetadata? initialMetadata,
  String? previewSubtitle,
}) {
  return showDialog<ImagePositionMetadata>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ImageRepositionDialog(
      frameKind: frameKind,
      imageProvider: imageProvider,
      imageUrl: imageUrl,
      initialMetadata: initialMetadata,
      previewSubtitle: previewSubtitle,
    ),
  );
}

class ImageRepositionDialog extends StatefulWidget {
  const ImageRepositionDialog({
    super.key,
    required this.frameKind,
    this.imageProvider,
    this.imageUrl,
    this.initialMetadata,
    this.previewSubtitle,
  });

  final ImageFrameKind frameKind;
  final ImageProvider? imageProvider;
  final String? imageUrl;
  final ImagePositionMetadata? initialMetadata;
  final String? previewSubtitle;

  @override
  State<ImageRepositionDialog> createState() => _ImageRepositionDialogState();
}

class _ImageRepositionDialogState extends State<ImageRepositionDialog> {
  late ImagePositionMetadata _metadata;

  Offset _dragStartFocal = Offset.zero;
  Offset _dragStartPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _metadata = widget.initialMetadata ?? ImagePositionMetadata.defaults;
  }

  void _reset() {
    setState(() {
      _metadata = ImagePositionMetadata(
        aspectRatio: widget.frameKind.aspectRatio,
      );
    });
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartFocal = Offset(_metadata.focalPointX, _metadata.focalPointY);
    _dragStartPoint = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, Size frameSize) {
    final delta = details.localPosition - _dragStartPoint;
    final normalized = Offset(
      (_dragStartFocal.dx - delta.dx / frameSize.width).clamp(0.0, 1.0),
      (_dragStartFocal.dy - delta.dy / frameSize.height).clamp(0.0, 1.0),
    );

    setState(() {
      _metadata = _metadata.copyWith(
        focalPointX: normalized.dx,
        focalPointY: normalized.dy,
        cropX: normalized.dx,
        cropY: normalized.dy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Adjust ${widget.frameKind.label}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Drag and zoom to choose how this image appears.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                if (widget.previewSubtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.previewSubtitle!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Live preview',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RepositionFrame(
                  frameKind: widget.frameKind,
                  imageProvider: widget.imageProvider,
                  imageUrl: widget.imageUrl,
                  metadata: _metadata,
                  interactive: true,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.zoom_out_map_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Slider(
                        value: _metadata.scale.clamp(1, 3),
                        min: 1,
                        max: 3,
                        divisions: 20,
                        activeColor: AppColors.primaryPink,
                        onChanged: (value) {
                          setState(() => _metadata = _metadata.copyWith(scale: value));
                        },
                      ),
                    ),
                    Text(
                      '${(_metadata.scale * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DrinkSpotButton(
                    key: const Key('image_reposition_reset_button'),
                    label: 'Reset',
                    icon: Icons.restart_alt_rounded,
                    compact: true,
                    variant: DrinkSpotButtonVariant.ghost,
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: DrinkSpotButton(
                        label: 'Cancel',
                        variant: DrinkSpotButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DrinkSpotButton(
                        key: const Key('image_reposition_save_button'),
                        label: 'Save Position',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          Navigator.of(context).pop(
                            _metadata.copyWith(
                              aspectRatio: widget.frameKind.aspectRatio,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositionFrame extends StatelessWidget {
  const _RepositionFrame({
    required this.frameKind,
    required this.metadata,
    required this.interactive,
    this.imageProvider,
    this.imageUrl,
    this.onPanStart,
    this.onPanUpdate,
  });

  final ImageFrameKind frameKind;
  final ImageProvider? imageProvider;
  final String? imageUrl;
  final ImagePositionMetadata metadata;
  final bool interactive;
  final GestureDragStartCallback? onPanStart;
  final void Function(DragUpdateDetails details, Size frameSize)? onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final aspect = frameKind.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(280.0, 640.0);
        final frameWidth = maxWidth;
        final frameHeight = frameWidth / aspect;

        Widget frame = Container(
          width: frameWidth,
          height: frameHeight,
          decoration: BoxDecoration(
            borderRadius: frameKind.isCircular
                ? null
                : BorderRadius.circular(AppSpacing.radiusMd),
            shape: frameKind.isCircular ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _RepositionFrameImage(
                imageProvider: imageProvider,
                imageUrl: imageUrl,
                metadata: metadata,
                circular: frameKind.isCircular,
              ),
              if (interactive)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
            ],
          ),
        );

        if (interactive && onPanStart != null && onPanUpdate != null) {
          frame = GestureDetector(
            onPanStart: onPanStart,
            onPanUpdate: (details) => onPanUpdate!(details, Size(frameWidth, frameHeight)),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: frame,
            ),
          );
        }

        return Center(child: frame);
      },
    );
  }
}

class _RepositionFrameImage extends StatelessWidget {
  const _RepositionFrameImage({
    required this.metadata,
    required this.circular,
    this.imageProvider,
    this.imageUrl,
  });

  final ImageProvider? imageProvider;
  final String? imageUrl;
  final ImagePositionMetadata metadata;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return PositionedVenueImage.network(
        url: url,
        metadata: metadata,
        circular: circular,
        errorWidget: const _RepositionFrameFallback(),
      );
    }

    final provider = imageProvider;
    if (provider != null) {
      return PositionedVenueImage(
        image: Image(
          image: provider,
          fit: BoxFit.cover,
          alignment: metadata.alignment,
        ),
        metadata: metadata,
        circular: circular,
      );
    }

    return const _RepositionFrameFallback();
  }
}

class _RepositionFrameFallback extends StatelessWidget {
  const _RepositionFrameFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.35),
            AppColors.surface.withValues(alpha: 0.86),
          ],
        ),
      ),
    );
  }
}

/// Read-only mini preview for profile cards.
class ImageRepositionPreview extends StatelessWidget {
  const ImageRepositionPreview({
    super.key,
    required this.frameKind,
    required this.imageUrl,
    this.metadata,
    this.height,
  });

  final ImageFrameKind frameKind;
  final String? imageUrl;
  final ImagePositionMetadata? metadata;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (frameKind.isCircular) {
      final size = height ?? 56;
      return FramedVenueImage(
        imageUrl: imageUrl,
        metadata: metadata,
        width: size,
        height: size,
        circular: true,
        fallback: _previewFallback(circular: true, size: size),
      );
    }

    return FramedVenueImage(
      imageUrl: imageUrl,
      metadata: metadata,
      height: height ?? 140,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      fallback: _previewFallback(height: height ?? 140),
    );
  }

  static Widget _previewFallback({
    double? height,
    double? size,
    bool circular = false,
  }) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.42),
            AppColors.surface.withValues(alpha: 0.92),
          ],
        ),
      ),
    );

    if (circular && size != null) {
      return SizedBox(width: size, height: size, child: child);
    }
    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: child);
    }
    return child;
  }
}
