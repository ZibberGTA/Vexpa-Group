import 'package:flutter/material.dart';

import '../../features/venues/data/venue_image_field_parser.dart';
import 'venue_network_image.dart';

/// Network image for venue branding with a synchronous fallback on load failure.
class SafeVenueBrandingImage extends StatelessWidget {
  const SafeVenueBrandingImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    final fallbackWidget = fallback ?? SizedBox(width: width, height: height);

    if (!VenueImageFieldParser.isRenderableImageUrl(trimmed)) {
      return fallbackWidget;
    }

    return VenueNetworkImage(
      url: trimmed,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorWidget: fallbackWidget,
    );
  }
}
