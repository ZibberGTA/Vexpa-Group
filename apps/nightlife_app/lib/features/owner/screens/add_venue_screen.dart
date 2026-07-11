import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';
import 'package:vex_engines/venue/domain/venue_profile_constants.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

import '../../auth/services/auth_service.dart';
import '../../venues/screens/pick_location_screen.dart';

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;

    var formatted = limited;
    if (limited.length > 2) {
      formatted = '${limited.substring(0, 2)}:${limited.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final categoryController = TextEditingController();
  final bannerImageUrlController = TextEditingController();
  final logoUrlController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final Map<String, TextEditingController> openingOpenControllers = {};
  final Map<String, TextEditingController> openingCloseControllers = {};
  final Map<String, bool> openingClosedDays = {};

  static const List<String> _openingDayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> _openingDayLabels = <String, String>{
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  String crowdLevel = 'quiet';
  LatLng? selectedLocation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final day in _openingDayKeys) {
      openingOpenControllers[day] = TextEditingController(text: '12:00');
      openingCloseControllers[day] = TextEditingController(text: '23:00');
      openingClosedDays[day] = false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    categoryController.dispose();
    bannerImageUrlController.dispose();
    logoUrlController.dispose();
    websiteUrlController.dispose();
    for (final controller in openingOpenControllers.values) {
      controller.dispose();
    }
    for (final controller in openingCloseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          initialLocation: selectedLocation,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      selectedLocation = result;
    });
  }



  String _normaliseTimeInput(String value) =>
      VenueProfileFieldCodec.normaliseTimeInput(value);

  void _normaliseOpeningHourControllers() {
    for (final day in _openingDayKeys) {
      final openController = openingOpenControllers[day];
      final closeController = openingCloseControllers[day];

      if (openController != null) {
        openController.text = _normaliseTimeInput(openController.text);
      }
      if (closeController != null) {
        closeController.text = _normaliseTimeInput(closeController.text);
      }
    }
  }

  bool _isValidTime(String value) => VenueProfileFieldCodec.isValidTime(value);

  Map<String, Map<String, dynamic>> _buildOpeningHoursMap() =>
      VenueProfileFieldCodec.buildOpeningHoursMap(_openingHoursDraft());

  Map<String, Map<String, dynamic>> _openingHoursDraft() {
    final result = <String, Map<String, dynamic>>{};

    for (final day in _openingDayKeys) {
      result[day] = {
        'closed': openingClosedDays[day] ?? false,
        'open': openingOpenControllers[day]?.text ?? '',
        'close': openingCloseControllers[day]?.text ?? '',
      };
    }

    return result;
  }

  bool _validateOpeningHours() {
    _normaliseOpeningHourControllers();
    final error = VenueProfileFieldCodec.validateOpeningHours(_openingHoursDraft());
    if (error != null) {
      _showMessage(error);
      return false;
    }
    return true;
  }

  Widget _buildOpeningHoursSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opening Times',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'These times control the Open / Closed status shown on the map venue card. Use 24-hour time. Overnight closing is supported, e.g. 18:00 to 02:00.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final day in _openingDayKeys) ...[
              Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      _openingDayLabels[day] ?? day,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: openingOpenControllers[day],
                      enabled: openingClosedDays[day] != true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_TimeTextInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Open',
                        hintText: '18:00',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: openingCloseControllers[day],
                      enabled: openingClosedDays[day] != true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_TimeTextInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Close',
                        hintText: '02:00',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const Text('Closed', style: TextStyle(fontSize: 11)),
                      Switch(
                        value: openingClosedDays[day] ?? false,
                        onChanged: (value) => setState(() => openingClosedDays[day] = value),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveVenue() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final address = addressController.text.trim();
    final category = categoryController.text.trim();
    final bannerImageUrl = bannerImageUrlController.text.trim();
    final logoUrl = logoUrlController.text.trim();
    var websiteUrl = websiteUrlController.text.trim();
    if (websiteUrl.isNotEmpty && !websiteUrl.startsWith('http')) websiteUrl='https://'+websiteUrl;

    if (name.isEmpty ||
        description.isEmpty ||
        address.isEmpty ||
        category.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    if (!_validateOpeningHours()) return;

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
      'currentCrowdLevel': crowdLevel,
      'currentCrowdScore': VenueProfileConstants.crowdScoreForLevel(crowdLevel),
        'bannerImageUrl': bannerImageUrl,
        'logoUrl': logoUrl,
        'websiteUrl': websiteUrl,
        'openingHours': _buildOpeningHoursMap(),
        'hasDeals': false,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'searchTerms': DiscoveryVenueSearchTermBuilder.buildMinimalVenueTerms(
          name: name,
          description: description,
          address: address,
          category: category,
          crowdLevel: crowdLevel,
        ),
        'location': selectedLocation != null
            ? GeoPoint(
                selectedLocation!.latitude,
                selectedLocation!.longitude,
              )
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
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
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
              TextField(
                controller: websiteUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  hintText: 'https://winecentral.co.uk',
                  helperText: 'Public website shown on the venue information page.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildOpeningHoursSection(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: crowdLevel,
                decoration: const InputDecoration(
                  labelText: 'Crowd Level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'quiet', child: Text('Quiet')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'busy', child: Text('Busy')),
                  DropdownMenuItem(value: 'packed', child: Text('Packed')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    crowdLevel = value;
                  });
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
