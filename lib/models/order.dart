import 'dart:convert';

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class OrderPosition {
  final String name;
  final int quantity;
  final double price;

  const OrderPosition({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderPosition.fromJson(Map<String, dynamic> json) {
    final meal = json['meal'] is Map ? json['meal'] as Map : null;
    return OrderPosition(
      name: (json['mealName'] ?? json['name'] ?? meal?['name'] ?? 'Item')
          .toString(),
      quantity: ((json['quantity'] ?? json['count'] ?? 1) as num).toInt(),
      price: _toDouble(json['price'] ?? json['unitPrice'] ?? meal?['price']),
    );
  }

  double get lineTotal => price * quantity;
}

class Order {
  final int id;
  final double totalPrice;
  final String notes;
  final int? cartId;
  final String? restaurant;
  final List<OrderPosition> positions;
  final int? itemsCount;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.totalPrice,
    required this.notes,
    this.cartId,
    this.restaurant,
    this.positions = const [],
    this.itemsCount,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    dynamic raw = json['positions'];

    // "Positions" may come as a JSON string: '[{"name":"Pizza",...}]'
    if (raw is String) {
      final text = raw.trim();
      if (text.startsWith('[')) {
        try {
          raw = jsonDecode(text);
        } catch (_) {}
      }
    }

    var positions = <OrderPosition>[];
    int? count;
    if (raw is List) {
      positions = raw
          .whereType<Map>()
          .map((e) => OrderPosition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      count = positions.isNotEmpty
          ? positions.fold<int>(0, (s, p) => s + p.quantity)
          : raw.length;
    } else if (raw is num) {
      count = raw.toInt();
    } else if (raw is String) {
      count = int.tryParse(raw);
    }

    final rest = json['restaurant'] ?? json['restaurantName'];
    final date = json['createdAt'] ??
        json['createdOn'] ??
        json['orderDate'] ??
        json['date'];

    return Order(
      id: (json['id'] as num).toInt(),
      totalPrice: _toDouble(json['totalPrice']),
      notes: (json['notes'] ?? '').toString(),
      cartId: (json['cartId'] as num?)?.toInt(),
      restaurant: rest is Map ? rest['name']?.toString() : rest?.toString(),
      positions: positions,
      itemsCount: count,
      createdAt: date == null ? null : DateTime.tryParse('$date'),
    );
  }

  String? get dateText {
    final d = createdAt?.toLocal();
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}