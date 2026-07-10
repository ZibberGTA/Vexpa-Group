import 'package:flutter/material.dart';

import '../../features/venues/models/image_position_metadata.dart';
import 'venue_network_image.dart';

/// Displays a venue image inside a frame using saved focal-point metadata.
class PositionedVenueImage extends StatelessWidget {
  const PositionedVenueImage({
    super.key,
    required this.image,
    this.metadata,
    this.fit = BoxFit.cover,
    this.circular = false,
  }) : _networkUrl = null,
       errorWidget = null;

  const PositionedVenueImage.network({
    super.key,
    required String url,
    this.metadata,
    this.fit = BoxFit.cover,
    this.circular = false,
    this.errorWidget,
  }) : image = null,
       _networkUrl = url;

  final Widget? image;
  final ImagePositionMetadata? metadata;
  final BoxFit fit;
  final bool circular;
  final String? _networkUrl;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final resolved = metadata ?? ImagePositionMetadata.defaults;

    Widget child =
        image ??
        VenueNetworkImage(
          url: _networkUrl!,
          fit: fit,
          alignment: resolved.alignment,
          errorWidget: errorWidget,
        );

    if (circular) {
      return ClipOval(child: child);
    }

    return child;
  }
}

/// Network image with optional positioning metadata and gradient fallback.
class FramedVenueImage extends StatelessWidget {
  const FramedVenueImage({
    super.key,
    required this.imageUrl,
    this.metadata,
    this.height,
    this.width,
    this.borderRadius,
    this.circular = false,
    this.fallback,
  });

  final String? imageUrl;
  final ImagePositionMetadata? metadata;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool circular;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final fallbackWidget = fallback ?? const SizedBox.expand();

    Widget content;
    if (hasUrl) {
      content = PositionedVenueImage.network(
        url: url,
        metadata: metadata,
        circular: circular,
        errorWidget: fallbackWidget,
      );
    } else {
      content = fallbackWidget;
    }

    if (height != null || width != null) {
      content = SizedBox(height: height, width: width, child: content);
    }

    if (circular) return content;

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}
