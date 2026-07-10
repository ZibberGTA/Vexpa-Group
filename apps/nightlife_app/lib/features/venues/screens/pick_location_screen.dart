import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/map/dark_map_style.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng? selectedLocation;

  static const LatLng defaultLocation = LatLng(51.5074, -0.1278); // London

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation ?? defaultLocation;
  }

  void _saveLocation() {
    if (selectedLocation == null) return;
    Navigator.pop(context, selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final markerLocation = selectedLocation ?? defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Venue Location'),
        actions: [
          TextButton(
            onPressed: _saveLocation,
            child: const Text('Save'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: markerLocation,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('venue_location'),
            position: markerLocation,
            draggable: true,
            onDragEnd: (value) {
              setState(() {
                selectedLocation = value;
              });
            },
          ),
        },
        onMapCreated: (controller) {
          controller.setMapStyle(DarkMapStyle.json);
        },
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onTap: (value) {
          setState(() {
            selectedLocation = value;
          });
        },
      ),
    );
  }
}