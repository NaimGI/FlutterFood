double toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class Cart {
  final int id;
  final String restaurant;
  final String organization;
  final double totalCartPrice;
  final double minPrice;
  final double deliveryPrice;
  final double freeDeliveryMinPrice;

  const Cart({
    required this.id,
    required this.restaurant,
    required this.organization,
    required this.totalCartPrice,
    required this.minPrice,
    required this.deliveryPrice,
    required this.freeDeliveryMinPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: (json['id'] as num).toInt(),
        restaurant: (json['restaurant'] ?? '').toString(),
        organization: (json['organization'] ?? '').toString(),
        totalCartPrice: toDouble(json['totalCartPrice']),
        minPrice: toDouble(json['minPrice']),
        deliveryPrice: toDouble(json['deliveryPrice']),
        freeDeliveryMinPrice: toDouble(json['freeDeliveryMinPrice']),
      );

  bool get freeDelivery =>
      freeDeliveryMinPrice > 0 && totalCartPrice >= freeDeliveryMinPrice;

  double get deliveryFee => freeDelivery ? 0 : deliveryPrice;

  /// Items total + delivery (assumes totalCartPrice is the items total).
  double get totalToPay => totalCartPrice + deliveryFee;

  bool get meetsMinimum => totalCartPrice >= minPrice;

  double get missingForMinimum => minPrice - totalCartPrice;

  double get missingForFreeDelivery => freeDeliveryMinPrice - totalCartPrice;
}

class CartPage {
  final List<Cart> items;
  final int totalPages;
  final int itemFrom;
  final int itemTo;
  final int totalItemsCount;

  const CartPage({
    required this.items,
    required this.totalPages,
    required this.itemFrom,
    required this.itemTo,
    required this.totalItemsCount,
  });

  const CartPage.empty()
      : items = const [],
        totalPages = 1,
        itemFrom = 0,
        itemTo = 0,
        totalItemsCount = 0;

  factory CartPage.fromList(List<dynamic> list) => CartPage(
        items: list
            .map((e) => Cart.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPages: 1,
        itemFrom: 1,
        itemTo: list.length,
        totalItemsCount: list.length,
      );

  factory CartPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? []);
    return CartPage(
      items:
          list.map((e) => Cart.fromJson(e as Map<String, dynamic>)).toList(),
      totalPages: ((json['totalPages'] ?? 1) as num).toInt(),
      itemFrom: ((json['itemFrom'] ?? 0) as num).toInt(),
      itemTo: ((json['itemTo'] ?? 0) as num).toInt(),
      totalItemsCount:
          ((json['totalItemsCount'] ?? list.length) as num).toInt(),
    );
  }

  /// Sum of all carts' items totals.
  double get itemsTotal =>
      items.fold<double>(0, (sum, c) => sum + c.totalCartPrice);

  /// Sum of all delivery fees (free ones count as 0).
  double get deliveryTotal =>
      items.fold<double>(0, (sum, c) => sum + c.deliveryFee);

  /// What the user pays for everything.
  double get grandTotal => itemsTotal + deliveryTotal;
}