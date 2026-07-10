import 'package:flutter/material.dart';

import 'venue_network_image_io.dart'
    if (dart.library.html) 'venue_network_image_web.dart';

/// Cross-platform venue network image.
///
/// On Flutter Web uses a native HTML `<img>` element because Firebase Storage
/// URLs can fail through [Image.network] while loading correctly in the browser.
class VenueNetworkImage extends StatelessWidget {
  const VenueNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return buildVenueNetworkImage(
      url: url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorWidget: errorWidget,
    );
  }
}
