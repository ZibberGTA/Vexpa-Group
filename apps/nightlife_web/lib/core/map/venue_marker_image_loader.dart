import 'dart:typed_data';

import 'venue_marker_image_loader_io.dart'
    if (dart.library.html) 'venue_marker_image_loader_web.dart';

Future<Uint8List?> loadVenueMarkerImageBytes(String url, int targetSize) {
  return loadMarkerImageBytes(url, targetSize);
}
