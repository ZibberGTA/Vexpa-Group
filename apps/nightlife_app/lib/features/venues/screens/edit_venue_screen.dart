import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'pick_location_screen.dart';

class EditVenueScreen extends StatefulWidget {
  final String venueId;

  const EditVenueScreen({
    super.key,
    required this.venueId,
  });

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bannerImageUrlController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _category = 'Bar';
  String _crowdLevel = 'moderate';
  LatLng? _selectedLocation;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _venueSub;

  static const List<String> _categories = ['Bar', 'Club', 'Pub'];
  static const List<String> _crowdLevels = ['quiet', 'moderate', 'busy', 'packed'];

  @override
  void initState() {
    super.initState();
    _loadVenue();
    _listenForDeletion();
  }

  @override
  void dispose() {
    _venueSub?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _bannerImageUrlController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadVenue() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        Navigator.pop(context);
        return;
      }

      final data = doc.data()!;

      if (data['isDeleted'] == true) {
        Navigator.pop(context);
        return;
      }

      _nameController.text = data['name']?.toString() ?? '';
      _addressController.text = data['address']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';
      _bannerImageUrlController.text = (data['bannerImageUrl'] ?? data['coverImageUrl'] ?? data['imageUrl'] ?? '').toString();
      _logoUrlController.text = data['logoUrl']?.toString() ?? '';
      _category = data['category']?.toString() ?? 'Bar';
      _crowdLevel = data['crowdLevel']?.toString() ?? 'moderate';

      final location = data['location'];
      if (location is GeoPoint) {
        _selectedLocation = LatLng(location.latitude, location.longitude);
      }

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load venue: $e')),
      );
    }
  }

  void _listenForDeletion() {
    _venueSub = FirebaseFirestore.instance
        .collection('venues')
        .doc(widget.venueId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final isDeleted = doc.data()?['isDeleted'] == true;

      if (isDeleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue was deleted')),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedLocation = result;
    });
  }

  List<String> _buildSearchTerms({
    required String name,
    required String description,
    required String address,
    required String category,
    required String crowdLevel,
  }) {
    return <String>[
      name,
      description,
      address,
      category,
      crowdLevel,
      ...name.split(RegExp(r'\s+')),
      ...description.split(RegExp(r'\s+')),
      ...address.split(RegExp(r'\s+')),
      ...category.split(RegExp(r'\s+')),
    ]
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final bannerImageUrl = _bannerImageUrlController.text.trim();
    final logoUrl = _logoUrlController.text.trim();

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({
        'name': name,
        'address': address,
        'description': description,
        'category': _category,
        'crowdLevel': _crowdLevel,
        'bannerImageUrl': bannerImageUrl,
        'logoUrl': logoUrl,
        'searchTerms': _buildSearchTerms(
          name: name,
          description: description,
          address: address,
          category: _category,
          crowdLevel: _crowdLevel,
        ),
        'location': _selectedLocation != null
            ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude)
            : null,
        'presenceRadiusMeters': 75,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue updated')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save venue: $e')),
      );
    }
  }

  Future<void> _deleteVenue() async {
    await FirebaseFirestore.instance
        .collection('venues')
        .doc(widget.venueId)
        .update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _displayCrowdLevel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _saving ? null : _deleteVenue,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bannerImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Banner Picture URL',
                    helperText: 'Shown at the top of the public venue page.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _logoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Venue Logo URL',
                    helperText: 'Shown as the venue logo on the map and public venue page.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _crowdLevel,
                  items: _crowdLevels
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(_displayCrowdLevel(e)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _crowdLevel = v);
                        },
                  decoration: const InputDecoration(
                    labelText: 'Crowd Level',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickLocation,
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    _selectedLocation == null
                        ? 'Set Location on Map'
                        : 'Edit Location on Map',
                  ),
                ),
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveVenue,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save Changes'),
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
