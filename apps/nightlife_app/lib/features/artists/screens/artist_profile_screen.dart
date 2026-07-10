import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';

import '../services/artist_service.dart';

class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final artistNameController = TextEditingController();
  final bioController = TextEditingController();
  final contactEmailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final performanceFeeController = TextEditingController();
  final genresController = TextEditingController();

  String artistType = 'Singer';
  bool loading = true;
  bool saving = false;

  final artistTypes = [
    'Singer',
    'Band',
    'DJ',
    'Comedian',
    'Dancer',
    'Performer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final stream = ArtistService.artistProfileStream();
    final snapshot = await stream.first;

    if (snapshot.exists) {
      final data = snapshot.data()!;
      artistNameController.text = data['artistName'] ?? '';
      bioController.text = data['bio'] ?? '';
      contactEmailController.text = data['contactEmail'] ?? '';
      phoneController.text = data['phone'] ?? '';
      locationController.text = data['location'] ?? '';
      performanceFeeController.text = data['performanceFee'] ?? '';
      artistType = data['artistType'] ?? 'Singer';

      final genres = data['genres'];
      if (genres is List) {
        genresController.text = genres.join(', ');
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (artistNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist name is required')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final genres = genresController.text
        .split(',')
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toList();

    await ArtistService.createOrUpdateArtistProfile(
      artistName: artistNameController.text,
      artistType: artistType,
      bio: bioController.text,
      contactEmail: contactEmailController.text,
      phone: phoneController.text,
      location: locationController.text,
      performanceFee: performanceFeeController.text,
      genres: genres,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artist profile saved')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    artistNameController.dispose();
    bioController.dispose();
    contactEmailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    performanceFeeController.dispose();
    genresController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Profile'),
        actions: const [HomeIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: artistNameController,
            decoration: _decoration('Artist / Stage Name'),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: artistType,
            decoration: _decoration('Artist Type'),
            items: artistTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  artistType = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: genresController,
            decoration: _decoration('Genres e.g. Pop, Rock, Acoustic'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: bioController,
            maxLines: 4,
            decoration: _decoration('Bio'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: locationController,
            decoration: _decoration('Location'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: performanceFeeController,
            keyboardType: TextInputType.number,
            decoration: _decoration('Usual Performance Fee'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: contactEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('Contact Email'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Phone'),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            icon: saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(saving ? 'Saving...' : 'Save Profile'),
            onPressed: saving ? null : _saveProfile,
          ),
        ],
      ),
    );
  }
}