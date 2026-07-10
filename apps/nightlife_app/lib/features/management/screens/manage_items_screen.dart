import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../venues/screens/add_venue_screen.dart';
import '../../venues/screens/edit_venue_screen.dart';
import '../services/soft_delete_service.dart';

class ManageItemsScreen extends StatelessWidget {
  final String collection;
  final String title;
  final String titleField;
  final String subtitleField;
  final bool isAdmin;
  final String? ownerId;

  const ManageItemsScreen({
    super.key,
    required this.collection,
    required this.title,
    required this.titleField,
    required this.subtitleField,
    required this.isAdmin,
    this.ownerId,
  });

  bool get _canCreateVenue => collection == 'venues';

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(collection)
        .where('isDeleted', isEqualTo: false);

    if (!isAdmin && ownerId != null && ownerId!.isNotEmpty) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      floatingActionButton: _canCreateVenue
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddVenueScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Venue'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                collection == 'venues'
                    ? 'No active venues found. Tap Add Venue to create one.'
                    : 'No active $collection found',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final itemTitle =
                  (data[titleField] ?? 'Unnamed item').toString();
              final itemSubtitle = (data[subtitleField] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text(itemTitle),
                  subtitle:
                      itemSubtitle.isNotEmpty ? Text(itemSubtitle) : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        if (collection == 'venues') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditVenueScreen(venueId: doc.id),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Edit screen for this item is coming next.',
                              ),
                            ),
                          );
                        }
                      }

                      if (value == 'delete') {
                        await SoftDeleteService.softDelete(
                          collection: collection,
                          docId: doc.id,
                        );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$itemTitle deleted')),
                        );
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
      ),
    );
  }
}