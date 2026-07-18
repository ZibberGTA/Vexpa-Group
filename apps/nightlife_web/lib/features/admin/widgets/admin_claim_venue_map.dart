import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/vexda_cloud_map_config.dart';
import '../../../core/map/dark_map_style.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_claim_venue.dart';

class AdminClaimVenueMap extends StatefulWidget {
  const AdminClaimVenueMap({
    super.key,
    required this.venues,
    required this.selectedVenue,
    required this.onVenueSelected,
    this.padding = EdgeInsets.zero,
  });

  final List<AdminClaimVenue> venues;
  final AdminClaimVenue? selectedVenue;
  final ValueChanged<AdminClaimVenue> onVenueSelected;
  final EdgeInsets padding;

  @override
  State<AdminClaimVenueMap> createState() => _AdminClaimVenueMapState();
}

class _AdminClaimVenueMapState extends State<AdminClaimVenueMap> {
  GoogleMapController? _controller;
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(54.5, -3.2),
    zoom: 5.4,
  );
  Set<Marker> _markers = const {};
  Timer? _markerDebounce;

  @override
  void initState() {
    super.initState();
    _cameraPosition = CameraPosition(
      target: _initialCenter(widget.venues),
      zoom: 5.4,
    );
    unawaited(_rebuildMarkers());
  }

  @override
  void didUpdateWidget(covariant AdminClaimVenueMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venues != widget.venues ||
        oldWidget.selectedVenue?.id != widget.selectedVenue?.id) {
      unawaited(_rebuildMarkers());
    }
  }

  @override
  void dispose() {
    _markerDebounce?.cancel();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _cameraPosition = position;
  }

  void _onCameraIdle() {
    _markerDebounce?.cancel();
    _markerDebounce = Timer(
      const Duration(milliseconds: 120),
      () => unawaited(_rebuildMarkers()),
    );
  }

  Future<void> _rebuildMarkers() async {
    final visibleRegion = await _safeVisibleRegion();
    final markers = _buildClusteredMarkers(visibleRegion);
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<LatLngBounds?> _safeVisibleRegion() async {
    final controller = _controller;
    if (controller == null) return null;
    try {
      return controller.getVisibleRegion();
    } on Object {
      return null;
    }
  }

  Set<Marker> _buildClusteredMarkers(LatLngBounds? visibleRegion) {
    if (widget.venues.isEmpty) return const {};

    final selectedId = widget.selectedVenue?.id;
    final zoom = _cameraPosition.zoom;
    final cellSize = _cellSizeForZoom(zoom);
    final visibleVenues = visibleRegion == null
        ? widget.venues
        : widget.venues.where(
            (venue) => _inBounds(venue.position, visibleRegion),
          );

    final clusters = <String, _VenueCluster>{};
    for (final venue in visibleVenues) {
      if (venue.id == selectedId) continue;
      final key = _clusterKey(venue.position, cellSize);
      clusters.putIfAbsent(key, () => _VenueCluster()).add(venue);
    }

    final markers = <Marker>{};
    for (final entry in clusters.entries) {
      final cluster = entry.value;
      if (cluster.venues.length == 1 || zoom >= 13.5) {
        final venue = cluster.venues.first;
        markers.add(_venueMarker(venue, selected: false));
      } else {
        markers.add(_clusterMarker(entry.key, cluster));
      }
    }

    final selected = widget.selectedVenue;
    if (selected != null) {
      markers.add(_venueMarker(selected, selected: true));
    }

    return markers;
  }

  Marker _venueMarker(AdminClaimVenue venue, {required bool selected}) {
    return Marker(
      markerId: MarkerId('claim-${venue.id}'),
      position: venue.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(_hueForVenue(venue)),
      zIndexInt: selected ? 20 : 10,
      infoWindow: InfoWindow(title: venue.name, snippet: venue.claimStatus),
      onTap: () => widget.onVenueSelected(venue),
    );
  }

  Marker _clusterMarker(String key, _VenueCluster cluster) {
    final count = cluster.venues.length;
    return Marker(
      markerId: MarkerId('claim-cluster-$key'),
      position: cluster.center,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      zIndexInt: 1,
      infoWindow: InfoWindow(title: '$count venues'),
      onTap: () async {
        final controller = _controller;
        if (controller == null) return;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            cluster.center,
            _cameraPosition.zoom + 1.8,
          ),
        );
      },
    );
  }

  static double _hueForVenue(AdminClaimVenue venue) {
    if (venue.isClaimed) return BitmapDescriptor.hueGreen;
    if (venue.isPending) return BitmapDescriptor.hueOrange;
    if (venue.isRejected) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueMagenta;
  }

  static String _clusterKey(LatLng position, double cellSize) {
    final latBucket = (position.latitude / cellSize).floor();
    final lngBucket = (position.longitude / cellSize).floor();
    return '$latBucket:$lngBucket';
  }

  static double _cellSizeForZoom(double zoom) {
    if (zoom < 6) return 1.4;
    if (zoom < 7) return 0.9;
    if (zoom < 8) return 0.55;
    if (zoom < 9) return 0.32;
    if (zoom < 10) return 0.18;
    if (zoom < 11) return 0.10;
    if (zoom < 12) return 0.055;
    if (zoom < 13.5) return 0.028;
    return 0.012;
  }

  static bool _inBounds(LatLng point, LatLngBounds bounds) {
    final south = bounds.southwest.latitude;
    final north = bounds.northeast.latitude;
    final west = bounds.southwest.longitude;
    final east = bounds.northeast.longitude;

    final latOk =
        point.latitude >= math.min(south, north) &&
        point.latitude <= math.max(south, north);
    final lngOk = west <= east
        ? point.longitude >= west && point.longitude <= east
        : point.longitude >= west || point.longitude <= east;
    return latOk && lngOk;
  }

  static LatLng _initialCenter(List<AdminClaimVenue> venues) {
    if (venues.isEmpty) return const LatLng(54.5, -3.2);
    final sample = venues.take(2000).toList();
    final lat =
        sample.map((venue) => venue.latitude).reduce((a, b) => a + b) /
        sample.length;
    final lng =
        sample.map((venue) => venue.longitude).reduce((a, b) => a + b) /
        sample.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: GoogleMap(
        mapId: VexdaCloudMapConfig.usesVectorMaps
            ? VexdaCloudMapConfig.mapId
            : null,
        style: VexdaCloudMapConfig.usesVectorMaps ? null : DarkMapStyle.json,
        initialCameraPosition: _cameraPosition,
        padding: widget.padding,
        markers: _markers,
        onMapCreated: (controller) {
          _controller = controller;
          unawaited(_rebuildMarkers());
        },
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        tiltGesturesEnabled: false,
      ),
    );
  }
}

class _VenueCluster {
  final List<AdminClaimVenue> venues = [];
  double _latTotal = 0;
  double _lngTotal = 0;

  void add(AdminClaimVenue venue) {
    venues.add(venue);
    _latTotal += venue.latitude;
    _lngTotal += venue.longitude;
  }

  LatLng get center =>
      LatLng(_latTotal / venues.length, _lngTotal / venues.length);
}
