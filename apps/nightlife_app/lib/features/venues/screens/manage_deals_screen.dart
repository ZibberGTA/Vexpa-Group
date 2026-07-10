import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';

class ManageDealsScreen extends StatefulWidget {
  const ManageDealsScreen({super.key});

  @override
  State<ManageDealsScreen> createState() => _ManageDealsScreenState();
}

class _ManageDealsScreenState extends State<ManageDealsScreen> {
  String? _selectedVenueId;
  String? _selectedVenueName;

  Future<void> _syncVenueHasDeals(String venueId) async {
    final activeDeals = await FirebaseFirestore.instance
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    await FirebaseFirestore.instance.collection('venues').doc(venueId).update({
      'hasDeals': activeDeals.docs.isNotEmpty,
    });
  }

  Future<void> _addOrEditDeal({
    String? dealId,
    Map<String, dynamic>? existingDeal,
  }) async {
    if (_selectedVenueId == null) return;

    final titleController = TextEditingController(
      text: existingDeal?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingDeal?['description']?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dealId == null ? 'Add Deal' : 'Edit Deal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) return;

    if (dealId == null) {
      await FirebaseFirestore.instance.collection('deals').add({
        'title': title,
        'description': description,
        'venueId': _selectedVenueId,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(_selectedVenueId)
          .update({'hasDeals': true});
    } else {
      await FirebaseFirestore.instance.collection('deals').doc(dealId).update({
        'title': title,
        'description': description,
      });

      await _syncVenueHasDeals(_selectedVenueId!);
    }
  }

  Future<void> _softDeleteDeal(String dealId, String venueId) async {
    await FirebaseFirestore.instance.collection('deals').doc(dealId).update({
      'isDeleted': true,
    });

    await _syncVenueHasDeals(venueId);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Deals'),
      ),
      floatingActionButton: _selectedVenueId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addOrEditDeal(),
              icon: const Icon(Icons.add),
              label: const Text('Add Deal'),
            ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('venues')
            .where('ownerId', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (context, venueSnapshot) {
          if (venueSnapshot.hasError) {
            return const Center(child: Text('Unable to load venues.'));
          }

          if (venueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final venues = venueSnapshot.data?.docs ?? [];

          if (venues.isEmpty) {
            return const Center(child: Text('You have no venues yet.'));
          }

          _selectedVenueId ??= venues.first.id;
          _selectedVenueName ??=
              venues.first.data()['name']?.toString() ?? 'Venue';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedVenueId,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  items: venues.map((venueDoc) {
                    final venue = venueDoc.data();
                    final name = venue['name']?.toString() ?? 'Venue';

                    return DropdownMenuItem(
                      value: venueDoc.id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedVenue = venues.firstWhere(
                      (venueDoc) => venueDoc.id == value,
                    );

                    setState(() {
                      _selectedVenueId = selectedVenue.id;
                      _selectedVenueName =
                          selectedVenue.data()['name']?.toString() ?? 'Venue';
                    });
                  },
                ),
              ),
              Expanded(
                child: _DealsList(
                  venueId: _selectedVenueId!,
                  onEdit: (dealId, deal) {
                    _addOrEditDeal(
                      dealId: dealId,
                      existingDeal: deal,
                    );
                  },
                  onDelete: _softDeleteDeal,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DealsList extends StatelessWidget {
  final String venueId;
  final void Function(String dealId, Map<String, dynamic> deal) onEdit;
  final Future<void> Function(String dealId, String venueId) onDelete;

  const _DealsList({
    required this.venueId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('deals')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load deals.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final deals = snapshot.data?.docs ?? [];

        if (deals.isEmpty) {
          return const Center(child: Text('No active deals for this venue.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final dealDoc = deals[index];
            final deal = dealDoc.data();

            final title = deal['title']?.toString() ?? 'Untitled deal';
            final description = deal['description']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.local_offer),
                ),
                title: Text(title),
                subtitle: description.isNotEmpty ? Text(description) : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit(dealDoc.id, deal);
                    }

                    if (value == 'delete') {
                      await onDelete(dealDoc.id, venueId);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}