import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_owner_profile_service.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

import '../../auth/services/auth_service.dart';
import '../../owner/services/owner_venue_service.dart';
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

  VenueOwnerProfileDraft _buildDraft() {
    return VenueOwnerProfileDraft(
      name: nameController.text,
      description: descriptionController.text,
      address: addressController.text,
      category: categoryController.text,
      crowdLevel: crowdLevel,
      bannerImageUrl: bannerImageUrlController.text,
      logoUrl: logoUrlController.text,
      websiteUrl: websiteUrlController.text,
      openingHours: _openingHoursDraft(),
      latitude: selectedLocation?.latitude,
      longitude: selectedLocation?.longitude,
    );
  }

  Future<void> _saveVenue() async {
    _normaliseOpeningHourControllers();

    setState(() => isLoading = true);

    try {
      final user = AuthService.currentUser;

      if (user == null) {
        _showMessage('You must be logged in.');
        return;
      }

      final result = await OwnerVenueService.createVenue(
        ownerId: user.uid,
        draft: _buildDraft(),
      );

      switch (result) {
        case DataSuccess():
          if (!mounted) return;
          _showMessage('Venue added successfully.');
          Navigator.pop(context);
        case DataFailure(:final error):
          _showMessage(error.message);
      }
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
