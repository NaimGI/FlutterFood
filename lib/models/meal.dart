import '../core/app_images.dart';

class Meal {
  static const String currency = '\$';

  final int id;
  final String name;
  final String? description;
  final double price;
  final String? _imageUrl;

  const Meal({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    String? imageUrl,
  }) : _imageUrl = imageUrl;

  factory Meal.fromJson(Map<String, dynamic> json) {
    final image = (json['imageUrl'] ?? json['image'])?.toString();
    final price = json['price'];

    return Meal(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      price: price is num ? price.toDouble() : double.tryParse('$price') ?? 0,
      imageUrl: (image == null || image.isEmpty) ? null : image,
    );
  }

  /// API image if present, otherwise one of the 5 repeated images.
  String get imageUrl => _imageUrl ?? AppImages.forId(id + 2);

  String get priceText => '$currency${price.toStringAsFixed(2)}';
}