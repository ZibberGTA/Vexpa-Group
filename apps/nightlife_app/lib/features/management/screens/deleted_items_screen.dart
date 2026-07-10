import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/soft_delete_service.dart';

class DeletedItemsScreen extends StatelessWidget {
  const DeletedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deleted Items'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Venues'),
              Tab(text: 'Drinks'),
              Tab(text: 'Deals'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DeletedCollectionList(
              collection: 'venues',
              titleField: 'name',
              subtitleField: 'address',
            ),
            _DeletedCollectionList(
              collection: 'drinks',
              titleField: 'name',
              subtitleField: 'category',
            ),
            _DeletedCollectionList(
              collection: 'deals',
              titleField: 'title',
              subtitleField: 'description',
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedCollectionList extends StatelessWidget {
  final String collection;
  final String titleField;
  final String subtitleField;

  const _DeletedCollectionList({
    required this.collection,
    required this.titleField,
    required this.subtitleField,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('isDeleted', isEqualTo: true)
          .snapshots(),
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
            child: Text('No deleted $collection'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final title = (data[titleField] ?? 'Unnamed item').toString();
            final subtitle = (data[subtitleField] ?? '').toString();
            final deletedByEmail = (data['deletedByEmail'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle.isNotEmpty) Text(subtitle),
                    if (deletedByEmail.isNotEmpty)
                      Text('Deleted by: $deletedByEmail'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () async {
                    await SoftDeleteService.restore(
                      collection: collection,
                      docId: doc.id,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title restored')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}