import 'package:flutter/services.dart';

Future<Uint8List?> loadMarkerImageBytes(String url, int targetSize) async {
  final data = await NetworkAssetBundle(Uri.parse(url)).load(url);
  return data.buffer.asUint8List();
}
