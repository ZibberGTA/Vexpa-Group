import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'venue_marker_image_loader.dart';

/// Vexda venue pin renderer — ported from the mobile app for cross-platform parity.
///
/// TODO(FIREBASE): Live venue logos load via [imageUrl] once Firestore is connected.
class VenueMapMarker {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List> create({
    required String venueId,
    required String venueName,
    required String? imageUrl,
    bool glow = false,
    Color? glowColor,
    int size = 112,
  }) async {
    final safeUrl = imageUrl?.trim() ?? '';
    final key = '$venueId|$safeUrl|$glow|${glowColor?.toARGB32()}|$size';

    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    final double w = size.toDouble();
    final double h = size.toDouble();
    final Offset center = Offset(w / 2, w * 0.42);

    if (glow) {
      final glowPaint = Paint()
        ..color = (glowColor ?? const Color(0xFFFF2D95)).withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..isAntiAlias = true;

      canvas.drawCircle(center, w * 0.40, glowPaint);
    }

    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: w * 0.31))
      ..moveTo(w / 2 - w * 0.13, w * 0.70)
      ..quadraticBezierTo(w / 2, h * 0.94, w / 2 + w * 0.13, w * 0.70)
      ..close();

    final gradientPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2D95), Color(0xFF9D28FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(pinPath, gradientPaint);

    final innerRing = Paint()
      ..color = const Color(0xFF05000A)
      ..isAntiAlias = true;

    canvas.drawCircle(center, w * 0.255, innerRing);

    final imageRect = Rect.fromCircle(center: center, radius: w * 0.225);
    canvas.save();
    canvas.clipPath(Path()..addOval(imageRect));

    var drewImage = false;
    if (safeUrl.isNotEmpty) {
      try {
        final bytes = await loadVenueMarkerImageBytes(safeUrl, 128);
        if (bytes == null || bytes.isEmpty) {
          throw StateError(
            'Marker image bytes unavailable for venueId=$venueId url=$safeUrl',
          );
        }
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        canvas.drawImageRect(
          frame.image,
          Rect.fromLTWH(
            0,
            0,
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ),
          imageRect,
          paint,
        );
        drewImage = true;
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[VenueMapMarker] logo draw failed venueId=$venueId '
            'url=$safeUrl error=$error',
          );
          debugPrint('$stackTrace');
        }
        drewImage = false;
      }
    }

    if (!drewImage) {
      final fallbackPaint = Paint()
        ..color = const Color(0xFF111218)
        ..isAntiAlias = true;
      canvas.drawRect(imageRect, fallbackPaint);
      _drawLetter(canvas, venueName, center, w);
    }

    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF2D95)
      ..isAntiAlias = true;

    canvas.drawCircle(center, w * 0.235, borderPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final markerBytes = byteData!.buffer.asUint8List();

    _cache[key] = markerBytes;
    return markerBytes;
  }

  static void _drawLetter(
    Canvas canvas,
    String venueName,
    Offset center,
    double w,
  ) {
    final letter = venueName.trim().isNotEmpty
        ? venueName.trim()[0].toUpperCase()
        : '?';

    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.26,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
