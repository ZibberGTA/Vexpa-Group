import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/google_maps_web_config.dart';
import '../../../core/map/dark_map_style.dart';
import '../../../core/map/google_maps_load_state.dart';
import '../../../core/map/map_camera_motion.dart';
import '../../../core/map/vexda_map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/search_map_coordinates.dart';
import '../data/search_venue_map_geometry.dart';
import '../map/search_map_marker_builder.dart';
import '../models/venue_search_result.dart';

/// Real Google Map for the Vexda search page — mobile map parity foundation.
class SearchGoogleMap extends StatefulWidget {
  const SearchGoogleMap({
    super.key,
    required this.venues,
    required this.selectedIndex,
    required this.visibleVenueIndices,
    required this.onPinSelected,
    this.padding = EdgeInsets.zero,
  });

  final List<VenueSearchResult> venues;

  final int selectedIndex;
  final List<int> visibleVenueIndices;
  final ValueChanged<int> onPinSelected;
  final EdgeInsets padding;

  @override
  State<SearchGoogleMap> createState() => _SearchGoogleMapState();
}

class _SearchGoogleMapState extends State<SearchGoogleMap> {
  final SearchMapMarkerBuilder _markerBuilder = SearchMapMarkerBuilder();

  GoogleMapController? _mapController;
  int? _lastFocusedIndex;
  double _cameraZoom = VexdaMapConstants.defaultZoom;
  LatLng _cameraTarget = SearchMapCoordinates.londonCenter;
  Set<Marker> _markers = const {};
  bool _mapReady = false;
  String? _loadError;
  String? _loadErrorDetail;
  int _markerRequestId = 0;

  @override
  void initState() {
    super.initState();
    _cameraTarget = SearchVenueMapGeometry.initialCenterFor(widget.venues);
    _loadMarkers();
    _pollMapsLoadState();
  }

  @override
  void didUpdateWidget(covariant SearchGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venues != widget.venues) {
      _cameraTarget = SearchVenueMapGeometry.initialCenterFor(widget.venues);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _focusSelectedVenue();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        !listEquals(
          oldWidget.visibleVenueIndices,
          widget.visibleVenueIndices,
        ) ||
        oldWidget.venues != widget.venues) {
      _loadMarkers();
    }
  }

  void _pollMapsLoadState({int attempt = 0}) {
    if (!kIsWeb || !mounted) return;

    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final error = GoogleMapsLoadState.error;
      final detail = GoogleMapsLoadState.errorDetail;
      if (error != null &&
          (error != _loadError || detail != _loadErrorDetail)) {
        if (kDebugMode) {
          debugPrint('[SearchGoogleMap] Maps load error: $error');
          if (detail != null) {
            debugPrint('[SearchGoogleMap] Detail: $detail');
          }
        }
        setState(() {
          _loadError = error;
          _loadErrorDetail = detail;
        });
        return;
      }

      if (_mapReady || attempt >= 40) return;
      _pollMapsLoadState(attempt: attempt + 1);
    });
  }

  Future<void> _loadMarkers() async {
    final requestId = ++_markerRequestId;

    final markers = await _markerBuilder.markersFor(
      venues: widget.venues,
      visibleVenueIndices: widget.visibleVenueIndices,
      selectedIndex: widget.selectedIndex,
      onVenueSelected: widget.onPinSelected,
    );

    if (!mounted || requestId != _markerRequestId) return;
    setState(() => _markers = markers);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (mounted) {
      setState(() => _mapReady = true);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _cameraTarget = position.target;
    _cameraZoom = position.zoom;
  }

  Future<void> _focusSelectedVenue() async {
    final controller = _mapController;
    final index = widget.selectedIndex;
    if (controller == null || index < 0) return;
    if (_lastFocusedIndex == index) return;

    _lastFocusedIndex = index;
    if (index >= widget.venues.length) return;
    final target = widget.venues[index].position;

    await MapCameraMotion.focusVenue(
      controller,
      target: target,
      currentZoom: _cameraZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFailure = _loadError != null;

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraTarget,
                zoom: _cameraZoom,
              ),
              padding: widget.padding,
              markers: _markers,
              style: DarkMapStyle.json,
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
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
          ),
          if (showFailure)
            _MapLoadFailureOverlay(
              error: _loadError!,
              detail: _loadErrorDetail,
            ),
        ],
      ),
    );
  }
}

class _MapLoadFailureOverlay extends StatelessWidget {
  const _MapLoadFailureOverlay({
    required this.error,
    this.detail,
  });

  final String error;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Material(
          color: AppColors.surfaceElevated.withValues(alpha: 0.96),
          elevation: 8,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Map could not load',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  GoogleMapsWebConfig.setupHint,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  'Enable Maps JavaScript API: '
                  '${GoogleMapsWebConfig.mapsJavaScriptApiEnableUrl}',
                  style: TextStyle(
                    color: AppColors.primaryPink.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
