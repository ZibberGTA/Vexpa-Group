import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/map/dark_map_style.dart';
import '../../trails/models/trail_model.dart';

class TrailRoutePreviewScreen extends StatefulWidget {
  const TrailRoutePreviewScreen({
    super.key,
    required this.trail,
    this.onGoToVenues,
  });

  final DrinkSpotTrailModel trail;
  final VoidCallback? onGoToVenues;

  @override
  State<TrailRoutePreviewScreen> createState() =>
      _TrailRoutePreviewScreenState();
}

class _TrailRoutePreviewScreenState extends State<TrailRoutePreviewScreen> {
  GoogleMapController? _mapController;
  Future<_RoutePreviewData>? _dataFuture;
  bool _cameraFitted = false;

  @override
  void initState() {
    super.initState();
    if (_orderedStops.isNotEmpty) {
      _dataFuture = _loadRouteData();
    }
  }

  List<TrailStopModel> get _orderedStops {
    final stops = [...widget.trail.stops];
    stops.sort((a, b) => a.order.compareTo(b.order));
    return stops;
  }

  Future<_RoutePreviewData> _loadRouteData() async {
    final locatedStops = <_LocatedRouteStop>[];

    for (final stop in _orderedStops) {
      if (stop.venueId.trim().isEmpty) continue;
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(stop.venueId)
          .get();
      final data = doc.data();
      final location = data?['location'];
      if (location is! GeoPoint) continue;

      locatedStops.add(
        _LocatedRouteStop(
          stop: stop,
          position: LatLng(location.latitude, location.longitude),
        ),
      );
    }

    final markers = <Marker>{};
    for (final located in locatedStops) {
      final icon = await TrailRouteNumberMarker.create(located.stop.order);
      markers.add(
        Marker(
          markerId: MarkerId('trail-stop-${located.stop.order}'),
          position: located.position,
          icon: icon,
          infoWindow: InfoWindow(
            title: '${located.stop.order}. ${located.stop.venueName}',
          ),
        ),
      );
    }

    final polylinePoints = locatedStops.map((item) => item.position).toList();
    final polylines = polylinePoints.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('trail_route_preview'),
              points: polylinePoints,
              color: const Color(0xFFFF2D95),
              width: 4,
              geodesic: true,
            ),
          }
        : const <Polyline>{};

    return _RoutePreviewData(
      markers: markers,
      polylines: polylines,
      boundsPoints: polylinePoints,
    );
  }

  void _fitCamera(_RoutePreviewData data) {
    final controller = _mapController;
    if (controller == null) return;

    final points = data.boundsPoints;
    if (points.isEmpty) return;

    if (points.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14.5));
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        96,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orderedStops.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF080713),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080713),
          title: const Text('Route Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: RouteEmptyState(onGoToVenues: widget.onGoToVenues),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080713),
      body: FutureBuilder<_RoutePreviewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting;

          if (data != null && _mapController != null && !_cameraFitted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _mapController == null) return;
              _cameraFitted = true;
              _fitCamera(data);
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      data?.boundsPoints.firstOrNull ??
                      const LatLng(51.5074, -0.1278),
                  zoom: 13,
                ),
                markers: data?.markers ?? const {},
                polylines: data?.polylines ?? const {},
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.setMapStyle(DarkMapStyle.json);
                },
              ),
              if (loading)
                const ColoredBox(
                  color: Color(0x88080713),
                  child: Center(child: CircularProgressIndicator()),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: const Color(0xFF111218).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(14),
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RouteVenueList(stops: _orderedStops),
                      const SizedBox(height: 12),
                      RouteInformationPanel(trail: widget.trail),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RouteEmptyState extends StatelessWidget {
  const RouteEmptyState({this.onGoToVenues});

  final VoidCallback? onGoToVenues;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF111218).withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_rounded, size: 56, color: Color(0xFFFF2D95)),
              const SizedBox(height: 18),
              const Text(
                'No route available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add venues to your trail before previewing the route.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onGoToVenues != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onGoToVenues!();
                    },
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text('Go to Venues'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RouteVenueList extends StatelessWidget {
  const RouteVenueList({required this.stops});

  final List<TrailStopModel> stops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111218).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Order',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 168),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: stops.length,
              separatorBuilder: (_, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.38),
                ),
              ),
              itemBuilder: (context, index) {
                final stop = stops[index];
                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D95).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF2D95).withOpacity(0.34),
                        ),
                      ),
                      child: Text(
                        '${stop.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stop.venueName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RouteInformationPanel extends StatelessWidget {
  const RouteInformationPanel({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final stopCount = trail.stops.isNotEmpty
        ? trail.stops.length
        : trail.venueCount;
    final durationLabel = _routePreviewDurationLabel(trail);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111218).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              const spacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              final stats = [
                ('Stops', '$stopCount'),
                ('Walking Distance', 'Coming Soon'),
                ('Walking Time', 'Coming Soon'),
                ('Trail Duration', durationLabel),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final stat in stats)
                    SizedBox(
                      width: itemWidth,
                      child: _RoutePreviewStat(label: stat.$1, value: stat.$2),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewStat extends StatelessWidget {
  const _RoutePreviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _routePreviewDurationLabel(DrinkSpotTrailModel trail) {
  if (trail.estimatedDuration.inMinutes > 0) {
    final minutes = trail.estimatedDuration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }
  final span = trail.availabilityEnd.difference(trail.availabilityStart);
  if (span.inMinutes > 0) {
    final minutes = span.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }
  return 'Coming Soon';
}

class _RoutePreviewData {
  const _RoutePreviewData({
    required this.markers,
    required this.polylines,
    required this.boundsPoints,
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<LatLng> boundsPoints;
}

class _LocatedRouteStop {
  const _LocatedRouteStop({required this.stop, required this.position});

  final TrailStopModel stop;
  final LatLng position;
}

class TrailRouteNumberMarker {
  TrailRouteNumberMarker._();

  static final Map<int, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> create(int order) async {
    final cached = _cache[order];
    if (cached != null) return cached;

    const size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2 - 4);

    final glowPaint = Paint()
      ..color = const Color(0xFFFF2D95).withOpacity(0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..isAntiAlias = true;
    canvas.drawCircle(center, 30, glowPaint);

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2D95), Color(0xFF9D28FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()))
      ..isAntiAlias = true;
    canvas.drawCircle(center, 26, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawCircle(center, 26, borderPaint);

    final text = order.toString();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    _cache[order] = icon;
    return icon;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
