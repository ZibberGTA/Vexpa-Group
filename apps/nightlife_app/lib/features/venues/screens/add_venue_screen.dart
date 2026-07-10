import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/services/auth_service.dart';
import 'pick_location_screen.dart';

class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final bannerImageUrlController = TextEditingController();
  final logoUrlController = TextEditingController();

  String category = 'Bar';
  String crowdLevel = 'quiet';
  LatLng? selectedLocation;
  bool isLoading = false;

  static const List<String> categories = ['Bar', 'Club', 'Pub'];
  static const List<String> crowdLevels = ['quiet', 'moderate', 'busy', 'packed'];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    bannerImageUrlController.dispose();
    logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(initialLocation: selectedLocation),
      ),
    );

    if (result == null) return;

    setState(() {
      selectedLocation = result;
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
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final address = addressController.text.trim();
    final bannerImageUrl = bannerImageUrlController.text.trim();
    final logoUrl = logoUrlController.text.trim();

    if (name.isEmpty || description.isEmpty || address.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = AuthService.currentUser;

      if (user == null) {
        _showMessage('You must be logged in.');
        return;
      }

      await FirebaseFirestore.instance.collection('venues').add({
        'ownerId': user.uid,
        'name': name,
        'description': description,
        'address': address,
        'category': category,
        'crowdLevel': crowdLevel,
        'bannerImageUrl': bannerImageUrl,
        'logoUrl': logoUrl,
        'hasDeals': false,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'searchTerms': _buildSearchTerms(
          name: name,
          description: description,
          address: address,
          category: category,
          crowdLevel: crowdLevel,
        ),
        'location': selectedLocation != null
            ? GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude)
            : null,
        'presenceRadiusMeters': 75,
        'activePresenceCount': 0,
        'crowdSource': 'owner',
      });

      if (!mounted) return;
      _showMessage('Venue added successfully.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to save venue: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _displayCrowdLevel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Venue'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Venue Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bannerImageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Banner Picture URL',
                  helperText: 'Shown at the top of the public venue page.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Venue Logo URL',
                  helperText: 'Shown as the venue logo on the map and public venue page.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => category = value);
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: crowdLevel,
                decoration: const InputDecoration(
                  labelText: 'Crowd Level',
                  border: OutlineInputBorder(),
                ),
                items: crowdLevels
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(_displayCrowdLevel(item)),
                      ),
                    )
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => crowdLevel = value);
                      },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _pickLocation,
                icon: const Icon(Icons.location_on),
                label: Text(
                  selectedLocation == null
                      ? 'Set Location on Map'
                      : 'Location Selected',
                ),
              ),
              if (selectedLocation != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, '
                  'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveVenue,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Venue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
