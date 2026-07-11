import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vex_engines/experience/shared/experience_search_term_builder.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/models/venue_model.dart';
import '../../search/services/search_index_service.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({
    super.key,
    required this.venue,
  });

  final VenueModel venue;

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  bool isLoading = false;
  String searchText = '';
  final Set<String> existingDrinks = {};

  final Map<String, List<String>> drinkLibrary = const {
    'Beer': [
      'Guinness',
      'Madri',
      'Peroni',
      'Carling',
      'Coors',
      'Corona',
      'Stella Artois',
      'Heineken',
      'Birra Moretti',
      'Camden Hells',
      'Beavertown Neck Oil',
      'San Miguel',
    ],
    'Cider': [
      'Strongbow',
      'Aspall',
      'Rekorderlig',
      'Kopparberg',
      'Old Mout',
      'Thatchers Gold',
    ],
    'Wine': [
      'House Red',
      'House White',
      'House Rosé',
      'Merlot',
      'Malbec',
      'Pinot Grigio',
      'Sauvignon Blanc',
      'Prosecco',
      'Champagne',
    ],
    'Spirits': [
      'Vodka',
      'Gin',
      'Rum',
      'Whisky',
      'Jack Daniels',
      'Jameson',
      'Bacardi',
      'Captain Morgan',
      'Gordon\'s Gin',
      'Bombay Sapphire',
      'Hendrick\'s Gin',
      'Tequila',
    ],
    'Cocktails': [
      'Espresso Martini',
      'Pornstar Martini',
      'Mojito',
      'Aperol Spritz',
      'Old Fashioned',
      'Margarita',
      'Cosmopolitan',
      'Long Island Iced Tea',
      'Pina Colada',
      'Negroni',
    ],
    'Soft Drinks': [
      'Coke',
      'Diet Coke',
      'Coke Zero',
      'Lemonade',
      'Orange Juice',
      'Apple Juice',
      'J2O',
      'Red Bull',
      'Still Water',
      'Sparkling Water',
    ],
  };

  final Map<String, bool> selected = {};
  final Map<String, TextEditingController> priceControllers = {};

 @override
void initState() {
  super.initState();

  for (final drinks in drinkLibrary.values) {
    for (final drink in drinks) {
      selected[drink] = false;
      priceControllers[drink] = TextEditingController();
    }
  }

  _loadExistingDrinks();
}

  @override
  void dispose() {
    for (final controller in priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingDrinks() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('drinks')
        .where('venueId', isEqualTo: widget.venue.id)
        .where('isDeleted', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final name = (data['name'] ?? '').toString();

      if (name.isEmpty) continue;

      existingDrinks.add(name.toLowerCase());

      if (selected.containsKey(name)) {
        selected[name] = true;
      }

      final price = data['price'];

      if (price != null && priceControllers.containsKey(name)) {
        priceControllers[name]!.text = price.toString();
      }
    }

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    debugPrint('Failed to load existing drinks: $e');
  }
}

  int get selectedCount => selected.values.where((value) => value).length;

  int get selectedWithPrices {
    var count = 0;

    for (final entry in selected.entries) {
      if (!entry.value) continue;
      final price = priceControllers[entry.key]?.text.trim() ?? '';
      if (price.isNotEmpty) count++;
    }

    return count;
  }

  List<String> _buildSearchTerms(List<String> values) =>
      ExperienceSearchTermBuilder.buildFromValues(values);

  String _categoryForDrink(String drinkName) {
    for (final entry in drinkLibrary.entries) {
      if (entry.value.contains(drinkName)) {
        return entry.key;
      }
    }

    return 'Other';
  }

  List<MapEntry<String, List<String>>> _filteredLibrary() {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return drinkLibrary.entries.toList();
    }

    return drinkLibrary.entries
        .map((entry) {
          final filteredDrinks = entry.value
              .where((drink) => drink.toLowerCase().contains(query))
              .toList();

          return MapEntry(entry.key, filteredDrinks);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  Future<void> _saveSelected() async {
    final chosen = selected.entries.where((entry) => entry.value).toList();

    if (chosen.isEmpty) {
      _showMessage('Select at least one drink.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final drinksCollection = FirebaseFirestore.instance.collection('drinks');

      for (final item in chosen) {
        final drinkName = item.key;

        if (existingDrinks.contains(drinkName.toLowerCase())) {
          continue;
        }
        final category = _categoryForDrink(drinkName);
        final priceText = priceControllers[drinkName]?.text.trim() ?? '';
        final price = priceText.isEmpty ? null : double.tryParse(priceText);

        if (priceText.isNotEmpty && price == null) {
          _showMessage('Please enter a valid price for $drinkName.');
          setState(() => isLoading = false);
          return;
        }

        final docRef = drinksCollection.doc();

        batch.set(docRef, {
          'venueId': widget.venue.id,
          'venueName': widget.venue.name,
          'name': drinkName,
          'category': category.toLowerCase(),
          'price': price,
          'description': '',
          'available': true,
          'isDeleted': false,
          'isPresetDrink': true,
          'searchTerms': _buildSearchTerms([
            drinkName,
            category,
            widget.venue.name,
          ]),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await SearchIndexService.updateVenueSearchTerms(widget.venue.id);

      if (!mounted) return;

      _showMessage('${chosen.length} drink${chosen.length == 1 ? '' : 's'} added.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Failed to save drinks: $e');
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beer':
        return Icons.sports_bar_rounded;
      case 'cider':
        return Icons.local_drink_rounded;
      case 'wine':
        return Icons.wine_bar_rounded;
      case 'spirits':
        return Icons.liquor_rounded;
      case 'cocktails':
        return Icons.local_bar_rounded;
      case 'soft drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.local_bar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLibrary = _filteredLibrary();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Drinks'),
        actions: [
          TextButton.icon(
            onPressed: _showCustomDrinkComingSoon,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Custom'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 120,
                ),
                children: [
                  Text(
                    'Tick drinks you sell. Prices are optional.',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.92),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _VenueSelectorPreview(venue: widget.venue),

                  const SizedBox(height: 14),

                  TextField(
                    onChanged: (value) {
                      setState(() => searchText = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search drinks...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.055),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: AppColors.primaryPurple.withOpacity(0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: AppColors.primaryPurple.withOpacity(0.28),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: AppColors.primaryPink,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (filteredLibrary.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No drinks found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...filteredLibrary.map(
                      (entry) => _DrinkCategorySection(
                        category: entry.key,
                        drinks: entry.value,
                        icon: _categoryIcon(entry.key),
                        selected: selected,
                        priceControllers: priceControllers,
                        onChanged: (drinkName, value) {
                          setState(() {
                            selected[drinkName] = value;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            _BottomSaveBar(
              selectedCount: selectedCount,
              selectedWithPrices: selectedWithPrices,
              isLoading: isLoading,
              onSave: _saveSelected,
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDrinkComingSoon() {
    _showMessage('Custom drink entry is next. For now, use the preset library.');
  }
}

class _VenueSelectorPreview extends StatelessWidget {
  const _VenueSelectorPreview({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Venue',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrinkCategorySection extends StatelessWidget {
  const _DrinkCategorySection({
    required this.category,
    required this.drinks,
    required this.icon,
    required this.selected,
    required this.priceControllers,
    required this.onChanged,
  });

  final String category;
  final List<String> drinks;
  final IconData icon;
  final Map<String, bool> selected;
  final Map<String, TextEditingController> priceControllers;
  final void Function(String drinkName, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.25),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: category == 'Beer',
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: AppColors.primaryPink,
          collapsedIconColor: AppColors.primaryPink,
          leading: Icon(
            icon,
            color: AppColors.primaryPink,
          ),
          title: Row(
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${drinks.length})',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          children: drinks.map((drink) {
            return _DrinkLibraryRow(
              drinkName: drink,
              isSelected: selected[drink] ?? false,
              priceController: priceControllers[drink]!,
              onChanged: (value) => onChanged(drink, value),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DrinkLibraryRow extends StatelessWidget {
  const _DrinkLibraryRow({
    required this.drinkName,
    required this.isSelected,
    required this.priceController,
    required this.onChanged,
  });

  final String drinkName;
  final bool isSelected;
  final TextEditingController priceController;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryPurple.withOpacity(0.10)
            : Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryPink.withOpacity(0.62)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: isSelected,
              activeColor: AppColors.primaryPink,
              side: const BorderSide(
                color: AppColors.textSecondary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (value) => onChanged(value ?? false),
            ),
          ),

          Expanded(
            child: InkWell(
              onTap: () => onChanged(!isSelected),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  drinkName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 118,
            child: TextField(
              controller: priceController,
              enabled: isSelected,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '',
                prefixText: '£ ',
                isDense: true,
                filled: true,
                fillColor: Colors.black.withOpacity(0.14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryPurple.withOpacity(0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryPurple.withOpacity(0.28),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(
                    color: AppColors.primaryPink,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  const _BottomSaveBar({
    required this.selectedCount,
    required this.selectedWithPrices,
    required this.isLoading,
    required this.onSave,
  });

  final int selectedCount;
  final int selectedWithPrices;
  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF0111218),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryPurple.withOpacity(0.25),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount == 0
                  ? 'No drinks selected'
                  : '$selectedCount drinks selected',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: selectedCount == 0
                    ? null
                    : const LinearGradient(
                        colors: [
                          AppColors.primaryPink,
                          AppColors.primaryPurple,
                        ],
                      ),
                color: selectedCount == 0 ? Colors.white.withOpacity(0.08) : null,
                borderRadius: BorderRadius.circular(17),
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading || selectedCount == 0 ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  selectedCount == 0
                      ? 'Add Drinks'
                      : 'Add $selectedCount Drinks',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
