import 'package:flutter/material.dart';

/// VM/desktop network image — plain [Image.network].
Widget buildVenueNetworkImage({
  required String url,
  required BoxFit fit,
  double? width,
  double? height,
  Alignment alignment = Alignment.center,
  Widget? errorWidget,
}) {
  return Image.network(
    url,
    fit: fit,
    width: width,
    height: height,
    alignment: alignment,
    errorBuilder: (context, error, stackTrace) {
      return errorWidget ?? SizedBox(width: width, height: height);
    },
  );
}
