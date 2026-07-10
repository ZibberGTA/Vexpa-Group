import 'package:vex_core/vex_core.dart';

import '../../features/venue/data/models/drink_model.dart';

VenueDrink vexVenueDrinkFromDrinkModel(DrinkModel model) {
  return VenueDrink(
    id: model.id,
    venueId: model.venueId,
    name: model.name,
    category: model.category,
    price: model.price,
    description: model.description,
    available: model.available,
    featured: model.featured,
    isDeleted: model.isDeleted,
  );
}

DrinkModel drinkModelFromVexVenueDrink(VenueDrink drink) {
  return DrinkModel(
    id: drink.id,
    venueId: drink.venueId,
    name: drink.name,
    category: drink.category,
    price: drink.price,
    description: drink.description,
    available: drink.available,
    featured: drink.featured,
    isDeleted: drink.isDeleted,
  );
}
