import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/models/drink_model.dart';
import '../../search/services/search_index_service.dart';

class EditDrinkScreen extends StatefulWidget {
  const EditDrinkScreen({
    super.key,
    required this.drink,
  });

  final DrinkModel drink;

  @override
  State<EditDrinkScreen> createState() => _EditDrinkScreenState();
}

class _EditDrinkScreenState extends State<EditDrinkScreen> {
  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController priceController;
  late final TextEditingController descriptionController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.drink.name);
    categoryController = TextEditingController(text: widget.drink.category);
    priceController = TextEditingController(
  text: widget.drink.price.toStringAsFixed(2),
);
    descriptionController = TextEditingController(text: widget.drink.description);
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateDrink() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final price = priceController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || category.isEmpty || price.isEmpty || description.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('drinks')
          .doc(widget.drink.id)
          .update({
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Update search index
      await SearchIndexService.updateVenueSearchTerms(widget.drink.venueId);

      if (!mounted) return;
      _showMessage('Drink updated successfully.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to update drink: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteDrink() async {
    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('drinks')
          .doc(widget.drink.id)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUser?.uid,
        'deletedByEmail': currentUser?.email,
      });

      // ✅ Update search index
      await SearchIndexService.updateVenueSearchTerms(widget.drink.venueId);

      if (!mounted) return;
      _showMessage('Drink moved to recovery.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to delete drink: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Drink'),
          content: const Text('Are you sure you want to delete this drink?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDrink();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Edit Drink'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Drink Name',
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
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
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
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updateDrink,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : _confirmDelete,
                child: const Text('Delete Drink'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}