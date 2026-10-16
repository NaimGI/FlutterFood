import 'package:flutter/foundation.dart';

import '../models/meal.dart';
import '../models/restaurant.dart';

/// In-memory draft basket: one restaurant at a time.
/// No backend calls until checkout — fixes the old "one cart per tap" bug.
class CartDraftItem {
  final Meal meal;
  int quantity;

  CartDraftItem({required this.meal, this.quantity = 1});

  double get lineTotal => meal.price * quantity;
}

class CartDraft extends ValueNotifier<List<CartDraftItem>> {
  Restaurant? restaurant;

  CartDraft._() : super([]);
  static final CartDraft instance = CartDraft._();

  int get count => value.fold<int>(0, (s, e) => s + e.quantity);
  double get itemsTotal =>
      value.fold<double>(0, (s, e) => s + e.lineTotal);
  bool get isEmpty => value.isEmpty;

  /// Returns false when the draft holds another restaurant's items.
  bool canAdd(Restaurant r) =>
      restaurant == null || restaurant!.id == r.id;

  void add(Restaurant r, Meal meal, {int quantity = 1}) {
    if (!canAdd(r)) return;
    restaurant ??= r;
    final i = value.indexWhere((e) => e.meal.id == meal.id);
    final next = List<CartDraftItem>.of(value);
    if (i >= 0) {
      next[i].quantity += quantity;
    } else {
      next.add(CartDraftItem(meal: meal, quantity: quantity));
    }
    value = next;
  }

  void setQuantity(int mealId, int quantity) {
    final next = List<CartDraftItem>.of(value);
    final i = next.indexWhere((e) => e.meal.id == mealId);
    if (i < 0) return;
    if (quantity <= 0) {
      next.removeAt(i);
    } else {
      next[i].quantity = quantity;
    }
    if (next.isEmpty) restaurant = null;
    value = next;
  }

  void remove(int mealId) => setQuantity(mealId, 0);

  void clear() {
    restaurant = null;
    value = [];
  }

  int quantityOf(int mealId) {
    final i = value.indexWhere((e) => e.meal.id == mealId);
    return i < 0 ? 0 : value[i].quantity;
  }
}
